import requests
import json


def test_getPediatricsInBounds(base_url):
    url = base_url + "/getPediatricsInBounds"

    bbox_request = {
        "count": 15,
        "page": 1,
        "southWest": [126.70, 37.45],
        "northEast": [126.71, 37.46],
    }
    headers = {"Content-Type": "application/json"}

    response = requests.post(url, headers=headers, data=json.dumps(bbox_request))
    return response


def test_listMoonlight(base_url):
    url = base_url + "/listMoonlight"

    headers = {"Content-Type": "application/json"}

    response = requests.get(url, headers=headers)
    return response


def main():
    base_url = "http://54.180.90.9:8080"
    response = test_getPediatricsInBounds(base_url)

    print("Status Code:", response.status_code)
    print("Response:", response.json())


if __name__ == "__main__":
    main()
