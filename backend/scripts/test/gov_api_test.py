import requests

GOV_SERVICE_KEY = "Wh0JM6pl2Nq3mYLYshzN5bboyrWKRYNbr2NKJYEvKf9WTgQG6vc44RL6+CBQrjCveysdWVRQ/Bmy+5+ahXSTtw=="

if __name__ == "__main__":
    # url = "http://apis.data.go.kr/B552657/HsptlAsembySearchService/getHsptlMdcncListInfoInqire"
    # params = {
    #     "serviceKey": GOV_SERVICE_KEY,
    #     # "Q0": "서울특별시",
    #     # "Q1": "강남구",
    #     # "QZ": "B",
    #     # "QD": "D002",
    #     # "QT": "1",
    #     "QN": "송내연합의원",
    #     "ORD": "NAME",
    #     "pageNo": "1",
    #     "numOfRows": "10",
    # }

    url = "http://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService/getRestDeInfo"
    params ={"serviceKey" : GOV_SERVICE_KEY, "solYear" : "2024", "solMonth" : "01", "numOfRows": 20}

    response = requests.get(url, params=params)
    print(response.headers)
    print(response.text)
