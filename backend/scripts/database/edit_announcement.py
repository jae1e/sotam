import requests
import json
from constants import *


def get_all_announcements(all):
    url = "https://" + BACKEND_HOSTNAME + "/v1/announcements"

    params = {}
    if all is not None:
        params = {"all": 1}
    response = requests.get(url, params=params)
    print(response.headers)
    json_object = json.loads(response.text)
    json_formatted_str = json.dumps(json_object, indent=2, ensure_ascii=False)
    print(json_formatted_str)
    return json_object


def post_announcement(type, timestamp, title, content):
    url = "https://" + BACKEND_HOSTNAME + "/v1/announcement/post"

    data = {
        "type": type,
        "timestamp": timestamp,
        "title": title,
        "content": content,
    }
    response = requests.post(url, json=data)
    print(response.headers)
    print(response.text)


def delete_announcements(timestamp):
    print("Deleting " + timestamp)

    url = "https://" + BACKEND_HOSTNAME + "/v1/announcement/delete"

    params = {
        "timestamp": timestamp,
    }
    response = requests.delete(url, params=params)
    print(response.headers)
    print(response.text)
    print("")


if __name__ == "__main__":
    # delete_announcements("2024-04-01 12:22:58")

    # if len(json_object["announcements"]) > 0:
    #     delete_announcements(json_object["announcements"][0]["timestamp"])

    type = "news"  # "news" or "alert"
    timestamp = ""  # "" or "2006-01-02 15:04:05"
    title = "소아과탐색기 1.3 업데이트"
    content = "사용자분들의 소중한 의견을 반영한 소아과탐색기 1.3 버전이 4월 초 출시됩니댜. " +\
         "소아과 탐색 시인성 및 정보 가독성이 개선되었고, 몇 가지 설문 문항들이 추가/삭제 되었습니다. " +\
         "메인 메뉴에 평가/공유 기능도 추가되었으니 앱에 대한 많은 의견 부탁드리며, 공유 링크로 지인들께 추천 부탁드립니다."
    post_announcement(type, timestamp, title, content)

    json_object = get_all_announcements(True)
