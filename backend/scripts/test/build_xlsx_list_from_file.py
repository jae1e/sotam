import os
import tqdm
import pandas as pd


def load_db(index_dict, data_folder):
    dataframe_dict = {}
    # fill index-filename map
    index_name_dict = {}
    for file_name in os.listdir(data_folder):
        split = file_name.split(".")
        if split[-1] != "xlsx":
            continue
        index_name_dict[int(split[0])] = file_name
    # fill dataframe_dict
    for key in tqdm.tqdm(index_dict, f"Load db files"):
        index = index_dict[key]
        if not index in index_name_dict:
            raise f"Key {key} not found in index_dict"
        file_path = os.path.join(data_folder, index_name_dict[index])
        dataframe_dict[key] = pd.read_excel(file_path)
    return dataframe_dict


def collect_hospital_info_from_dataframe(
    dataframe_src, hospital_ids, id_title, info_column_titles, dataframe_tgt
):
    # select source data with hospital ids
    selected_src = dataframe_src[dataframe_src[id_title].isin(hospital_ids)]
    # copy matching data
    for i, row_tgt in tqdm.tqdm(dataframe_tgt.iterrows(), total=len(dataframe_tgt)):
        # find matching row and copy data
        match = selected_src[selected_src[id_title] == row_tgt[id_title]]
        if not match.empty:
            dataframe_tgt.loc[i, info_column_titles] = match[info_column_titles].values[
                0
            ]
    return dataframe_tgt


def collect_hospital_subject_list_from_dataframe(
    dataframe_src,
    hospital_ids,
    id_title,
    subject_column_title,
    subject_delimiter,
    dataframe_tgt,
):
    # title data type sanity check
    assert isinstance(id_title, str)
    assert isinstance(subject_column_title, str)
    # select source data with hospital ids
    selected_src = dataframe_src[dataframe_src[id_title].isin(hospital_ids)]
    # group subject data by id
    grouped_src = (
        selected_src.groupby(id_title)[subject_column_title].apply(list).to_dict()
    )
    # fill data to target dataframe with by joining subjects with delimiter
    for id in tqdm.tqdm(grouped_src, total=len(grouped_src)):
        subject_list = grouped_src[id]
        if len(subject_list) == 0:
            continue
        dataframe_tgt.loc[
            dataframe_tgt[id_title] == id, subject_column_title
        ] = subject_delimiter.join(subject_list)
    return dataframe_tgt


if __name__ == "__main__":
    print("Database version: 2023.09")

    print("==============================================")
    print("Step 1: Make key-data dict")

    file_index_dict = {
        "hospital": 1,
        # "pharmacy": 2,
        "detail": 4,
        "subject": 5,
    }
    cwd = os.path.dirname(os.path.realpath(__file__))
    data_folder = os.path.join(cwd, "data/전국 병의원 및 약국 현황 2023.09")

    dataframe_dict = load_db(file_index_dict, data_folder)
    for key in dataframe_dict:
        print(f"{key}: {dataframe_dict[key].columns}")

    print("==============================================")
    print("Step 2: Collect hospital ids (암호화요양기호) for each subject")

    subject_title = "진료과목코드명"
    subject_strs = ["소아청소년과", "소아치과"]
    id_title = "암호화요양기호"

    subject_ids_dict = {}
    for subject in subject_strs:
        subject_dataframe = dataframe_dict["subject"]
        ids = subject_dataframe[subject_dataframe[subject_title] == subject][id_title]
        subject_ids_dict[subject] = ids
        print(f"Found {len(ids)} {subject}")

    print("==============================================")
    print("Step 3: Collect info for each id")

    id_field = "암호화요양기호"
    raw_data_fields_dict = {
        "general": [
            "요양기관명",
            "종별코드명",
            "시도코드명",
            "시군구코드명",
            "읍면동",
            "주소",
            "전화번호",
            "좌표(X)",
            "좌표(Y)",
        ],
        "detail": [
            "주차가능대수",
            "주차_기타안내사항",
            "일요일 휴진안내",
            "공휴일 휴진안내",
            "점심시간_평일",
            "점심시간_토요일",
            "진료시작시간_월",
            "진료종료시간_월",
            "진료시작시간_화",
            "진료종료시간_화",
            "진료시작시간_수",
            "진료종료시간_수",
            "진료시작시간_목",
            "진료종료시간_목",
            "진료시작시간_금",
            "진료종료시간_금",
            "진료시작시간_토",
            "진료종료시간_토",
            "진료시작시간_일",
            "진료종료시간_일",
        ],
        "subject": ["진료과목코드명"],
    }
    subject_delimiter = "&"
    output_folder = os.path.join(cwd, "data/output")

    # Create output folder if it doesn't exist
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    for subject in subject_ids_dict:
        hospital_ids = subject_ids_dict[subject]

        # Make output dataframe
        output_dataframe = pd.DataFrame({}, dtype=str)
        output_dataframe[id_field] = hospital_ids
        for topic in raw_data_fields_dict:
            for field in raw_data_fields_dict[topic]:
                output_dataframe[field] = ""

        # Collect data to output dataframe
        print(f"Collecting general data for {subject}...")
        output_dataframe = collect_hospital_info_from_dataframe(
            dataframe_dict["hospital"],
            hospital_ids,
            id_field,
            raw_data_fields_dict["general"],
            output_dataframe,
        )

        print(f"Collecting detail data for {subject}...")
        output_dataframe = collect_hospital_info_from_dataframe(
            dataframe_dict["detail"],
            hospital_ids,
            id_field,
            raw_data_fields_dict["detail"],
            output_dataframe,
        )

        print(f"Collecting subject data for {subject}...")
        output_dataframe = collect_hospital_subject_list_from_dataframe(
            dataframe_dict["subject"],
            hospital_ids,
            id_field,
            raw_data_fields_dict["subject"][0],
            subject_delimiter,
            output_dataframe,
        )

        print(f"{subject} output dataframe:")
        print(output_dataframe.head)

        # Export data to excel
        output_file_path = os.path.join(output_folder, subject + ".xlsx")
        output_dataframe.to_excel(output_file_path, index=False, engine="openpyxl")
        print(f"Exported {len(hospital_ids)} {subject} to {output_file_path}")
