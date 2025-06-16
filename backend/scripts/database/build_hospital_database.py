import requests
import math
import tqdm
import time
import datetime
import argparse
from xml.etree import ElementTree
from pymongo import MongoClient, GEOSPHERE, errors, ReplaceOne
from pymongo.errors import BulkWriteError

from constants import *


def get_all_hospital_counts(url_map_key):
    url = GOV_URL_MAP[url_map_key]
    params = {
        "serviceKey": GOV_SERVICE_KEY,
        "pageNo": 1,
        "numOfRows": 1,
    }

    response = requests.get(url, params=params)

    # Parse XML
    root = ElementTree.fromstring(response.text)

    # Check result code
    result_code = root.find("header/resultCode")
    assert result_code is not None, f"Null result code from hospital count check"
    assert (
        result_code.text == "00"
    ), f"Wrong result code ({result_code.text}) hospital count check"

    # Check total counts
    total_counts = root.find("body/totalCount")
    assert total_counts is not None, f"Total counts not found"

    return int(total_counts.text)


def get_hospital_list(
    url_map_key: str,
    no_rows: int,
    duty_div_set: set,
    retry: int,
    sleep_before_retry: float,
    page: int,
):
    url = GOV_URL_MAP[url_map_key]
    params = {
        "serviceKey": GOV_SERVICE_KEY,
        "pageNo": page,
        "numOfRows": no_rows,
    }

    for i in range(retry):
        response = requests.get(url, params=params)
        # Parse XML
        root = ElementTree.fromstring(response.text)
        # Check result code
        result_code = root.find("header/resultCode")
        if result_code is not None and result_code.text == "00":
            break
        # Sleep before retry
        time.sleep(sleep_before_retry)
        # print(f"Retrying query for hospital list page {page}...")

    input_items = root.findall("body/items/item")
    output_items = []
    for input_item in input_items:
        assert input_item is not None, f"Item element is None"
        # Check if item's dutyDiv is in target
        duty_div = input_item.find("dutyDiv")
        assert duty_div is not None, f"Item does not contain dutyDiv"
        if duty_div.text not in duty_div_set:
            continue
        # Make output item
        output_item = {}
        for field in DATA_FIELD_DICT["list"]:
            element = input_item.find(field)
            if element is None:
                continue
            output_item[field] = element.text
        output_items.append(output_item)

    return output_items


def add_hospital_detail(hospital: dict, retry: int, sleep_before_retry: float):
    hpid = hospital["hpid"]

    url = GOV_URL_MAP["hpid"]
    params = {
        "serviceKey": GOV_SERVICE_KEY,
        "HPID": hpid,
        "pageNo": 1,
        "numOfRows": 3,
    }

    root = None
    result_code = None

    for i in range(retry):
        response = requests.get(url, params=params)
        # Parse XML
        root = ElementTree.fromstring(response.text)
        # Check result code
        result_code = root.find("header/resultCode")
        if result_code is not None and result_code.text == "00":
            break
        # Sleep before retry
        time.sleep(sleep_before_retry)
        # print(f"Retrying detail query for {hpid}...")

    # Check result code again
    assert result_code is not None, f"Null result code from hospital detail of {hpid}"
    assert (
        result_code.text == "00"
    ), f"Wrong result code ({result_code.text}) from hospital detail of {hpid}"

    # Get item element
    input_items = root.findall("body/items/item")
    assert (
        len(input_items) == 1
    ), f"Item count from hospital detail of {hpid} is {len(input_items)}"
    input_item = input_items[0]
    assert input_item is not None, f"Item element of {hpid} is None"

    # Sanity check with hpid
    found_hpid = input_item.find("hpid").text
    assert hpid == found_hpid, f"Item hpid of {hpid} is not {found_hpid}"

    # Add info
    for field in DATA_FIELD_DICT["detail"]:
        element = input_item.find(field)
        if element is None or element.text == "":
            continue
        hospital[field] = element.text

    return hospital


def redefine_fields(hospital: dict):
    # hpid -> _id
    hpid = hospital["hpid"]
    hospital["_id"] = hpid
    hospital.pop("hpid")

    # wgs84Lon wgs84Lat -> location
    if "wgs84Lon" not in hospital or "wgs84Lat" not in hospital:
        print(
            f"[Warning] Coordinate is not found in {hospital['_id']} ({hospital['dutyName']})"
        )
    else:
        lng = float(hospital["wgs84Lon"])
        lat = float(hospital["wgs84Lat"])
        hospital["location"] = {"type": "Point", "coordinates": [lng, lat]}
        hospital.pop("wgs84Lon")
        hospital.pop("wgs84Lat")
    return hospital


def build_list_collection(collection, url_map_key, clean, overwrite):
    # Purge existing data
    if clean:
        collection.delete_many({})

    # Create an index with (geospatial) location
    collection.create_index([("location", GEOSPHERE)])

    # Get hospital count
    hospital_count = get_all_hospital_counts(url_map_key)
    print(f"Total hospital counts: {hospital_count}")

    # Get hospital list
    duty_div_set = set({"A", "B", "C", "R", "Y", "Z"})

    no_rows = 64
    retry = 10
    retry_sleep = 1.0

    page_count = math.ceil(hospital_count / no_rows) + 1

    print("Querying and saving hospital info...")
    for page in tqdm.tqdm(range(1, page_count)):
        # Get basic info
        hospitals = get_hospital_list(
            url_map_key, no_rows, duty_div_set, retry, retry_sleep, page
        )

        consolidated_hospitals = []
        # Fill in detail
        for hospital in hospitals:
            # Fetch detail
            hospital = add_hospital_detail(hospital, retry, retry_sleep)
            # _id -> hpid
            # wgs84LonLat -> location with {"type": "Point", "coordinates": [lng, lat]}
            hospital = redefine_fields(hospital)

            consolidated_hospitals.append(hospital)

        if len(consolidated_hospitals) == 0:
            continue

        if overwrite:
            # Overwrite existing data in collection
            operations = [
                ReplaceOne({"_id": doc["_id"]}, doc, upsert=True)
                for doc in consolidated_hospitals
            ]
            result = collection.bulk_write(operations)
        else:
            # Insert to collection
            try:
                collection.insert_many(consolidated_hospitals)
            except errors.DuplicateKeyError:
                print("A document with the same hpid already exists")


def dump_moonlight_list(moonlight_collection, hospital_collection):
    bulk_operations = []
    for doc in moonlight_collection.find():
        # Add moonlight flag
        doc[MOONLIGHT_FLAG] = 1
        bulk_operations.append(ReplaceOne({"_id": doc["_id"]}, doc, upsert=True))
    # Perform bulk write
    try:
        result = hospital_collection.bulk_write(bulk_operations)
        inserted_ids = [
            upsert["_id"] for upsert in result.bulk_api_result.get("upserted", [])
        ]
        updated_count = result.modified_count

        print(f"Updated {updated_count} _ids")
        print(f"Inserted ({len(inserted_ids)}) _ids: {inserted_ids}")

    except BulkWriteError as bwe:
        print("Error occurred while dumping moonlight list:", bwe.details)


def convert_address_to_coordinates(hospital: dict):
    address = hospital.get("dutyAddr")
    print(f"Full address: {address}")
    address = address.split(",")[0]
    print(f"Refined address: {address}")
    assert (
        address is not None
    ), f"Address of {hospital['_id']} ({hospital['dutyName']}) is not found"
    # Query with Kakao API
    headers = {"Authorization": f"KakaoAK {KAKAO_API_KEY}"}
    params = {"query": address}
    response = requests.get(KAKAO_URL_MAP["address"], headers=headers, params=params)
    assert (
        response.status_code == 200
    ), f"Response code {response.status_code} from coordinate conversion of {hospital['_id']} ({hospital['dutyName']})"
    result = response.json()
    assert (
        len(result["documents"]) != 0
    ), f"No coordinate result for {hospital['_id']} ({hospital['dutyName']})"
    lng = float(result["documents"][0]["address"]["x"])
    lat = float(result["documents"][0]["address"]["y"])
    print(f"Lng lat: {lng, lat}")
    # Update coordinate info
    hospital["location"] = {"type": "Point", "coordinates": [lng, lat]}
    return hospital


def check_data_integrity_and_resolve(collection):
    for hospital in collection.find():
        # Check if coordinate info exists
        if hospital.get("location") is not None:
            continue
        # Create coordinate from address
        hospital = convert_address_to_coordinates(hospital)
        collection.update_one({"_id": hospital["_id"]}, {"$set": hospital})
        print(
            f"Converted {hospital['_id']} ({hospital['dutyName']}) address to coordinates"
        )


def build_holiday_collection():
    url = GOV_URL_MAP["holiday"]
    current_year = datetime.datetime.now().year

    # Collect data for 2 years, every month
    holidays = []
    for year in tqdm.tqdm([current_year, current_year + 1]):
        for month in range(1, 13):
            year_str = str(year)
            month_str = str(month).zfill(2)

            params = {
                "serviceKey": GOV_SERVICE_KEY,
                "solYear": year_str,
                "solMonth": month_str,
                "numOfRows": 20,
            }

            retry = 10
            sleep_before_retry = 1.0

            for i in range(retry):
                response = requests.get(url, params=params)
                # Parse XML
                root = ElementTree.fromstring(response.text)
                # Check result code
                result_code = root.find("header/resultCode")
                if result_code is not None and result_code.text == "00":
                    break
                # Sleep before retry
                time.sleep(sleep_before_retry)
                # print(f"Retrying query for hospital list page {page}...")

            input_items = root.findall("body/items/item")
            for input_item in input_items:
                assert input_item is not None, f"Item element is None"
                # Check if item's locdate is in target
                locdate = input_item.find("locdate")
                assert locdate is not None, f"Item does not contain locdate"
                holidays.append(locdate.text)

    holiday_collection = db[HOLIDAY_COLLECTION_NAME]
    holiday_collection.delete_many({})
    data = {"holidays": holidays}
    holiday_collection.insert_one(data)
    print(f"Updated holidays: {data}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(prog="Build hospital database")
    parser.add_argument(
        "--collection",
        action="store",
        choices=["all", "holiday", "info"],
        help="build all database collections",
        required=True,
    )
    parser.add_argument(
        "--clean", action="store_true", help="clean and rebuild database"
    )

    args = parser.parse_args()
    clean = args.clean
    collection_selection = args.collection
    if collection_selection is None:
        print("Error: collection argument is empty")
        exit()

    client = MongoClient(MONGO_URI)
    db = client[DB_NAME]

    if collection_selection == "all":
        hospital_collection = db[HOSPITAL_COLLECTION_NAME]
        moonlight_collection = db[MOONLIGHT_COLLECTION_NAME]
        overwrite = True

        print("1. Build hospital collection")
        build_list_collection(
            hospital_collection, "full_data", clean=clean, overwrite=overwrite
        )

        print("2. Build moonlight collection")
        build_list_collection(
            moonlight_collection, "moonlight_list", clean=clean, overwrite=overwrite
        )

        print("3. Check data integrity and resolve error")
        check_data_integrity_and_resolve(hospital_collection)
        check_data_integrity_and_resolve(moonlight_collection)

        print("4. Dump moonlight hospitals to hospital collection")
        dump_moonlight_list(moonlight_collection, hospital_collection)

    if collection_selection == "all" or collection_selection == "holiday":
        print("5. Build holiday collection")
        build_holiday_collection()

    if collection_selection == "all" or collection_selection == "info":
        print("6. Add DB info")
        info_collection = db[INFO_COLLECTION_NAME]
        info_collection.delete_many({})
        info = {
            "lastUpdate": datetime.datetime.now().strftime(TIMESTAMP_FORMAT),
            "introductionTitle": INTRODUCTION_TITLE,
            "introductionText": INTRODUCTION_TEXT,
        }
        info_collection.insert_one(info)
        print(f"Updated DB info: {info}")
