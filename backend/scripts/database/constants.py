# DB
MONGO_URI = "mongodb://localhost:27017"
DB_NAME = "hospital_database"

# Collection
INFO_COLLECTION_NAME = "info"
HOSPITAL_COLLECTION_NAME = "hospitals"
MOONLIGHT_COLLECTION_NAME = "moonlights"
HOLIDAY_COLLECTION_NAME = "holidays"

# Backend API
BACKEND_HOSTNAME = "N/A"

# Gov API
GOV_SERVICE_KEY = "N/A"
GOV_URL_MAP = {
    "list": "http://apis.data.go.kr/B552657/HsptlAsembySearchService/getHsptlMdcncListInfoInqire",
    "location": "http://apis.data.go.kr/B552657/HsptlAsembySearchService/getHsptlMdcncLcinfoInqire",
    "hpid": "http://apis.data.go.kr/B552657/HsptlAsembySearchService/getHsptlBassInfoInqire",
    "moonlight_list": "http://apis.data.go.kr/B552657/HsptlAsembySearchService/getBabyListInfoInqire",
    "moonlight_location": "http://apis.data.go.kr/B552657/HsptlAsembySearchService/getBabyLcinfoInqire",
    "full_data": "http://apis.data.go.kr/B552657/HsptlAsembySearchService/getHsptlMdcncFullDown",
    "holiday": "http://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService/getRestDeInfo",
}

# Kakao API
KAKAO_API_KEY = "N/A"
KAKAO_URL_MAP = {"address": "https://dapi.kakao.com/v2/local/search/address.json"}

# Key
MOONLIGHT_FLAG = "isMoonlight"
DATA_FIELD_DICT = {
    # 병원 전체 및 달빛어린이병원
    "list": {
        "hpid": "기관ID",
        "dutyName": "기관명",
        "dutyAddr": "주소",
        "dutyTel1": "대표전화",
        "dutyDiv": "병원분류",
        "dutyDivNam": "병원분류명",
        "dutyEryn": "응급실운영여부",
        "dutyTel3": "응급실전화",
        "dutyTime1s": "진료시작(월요일)",
        "dutyTime1c": "진료종료(월요일)",
        "dutyTime2s": "진료시작(화요일)",
        "dutyTime2c": "진료종료(화요일)",
        "dutyTime3s": "진료시작(수요일)",
        "dutyTime3c": "진료종료(수요일)",
        "dutyTime4s": "진료시작(목요일)",
        "dutyTime4c": "진료종료(목요일)",
        "dutyTime5s": "진료시작(금요일)",
        "dutyTime5c": "진료종료(금요일)",
        "dutyTime6s": "진료시작(토요일)",
        "dutyTime6c": "진료종료(토요일)",
        "dutyTime7s": "진료시작(일요일)",
        "dutyTime7c": "진료종료(일요일)",
        "dutyTime8s": "진료시작(공휴일)",
        "dutyTime8c": "진료종료(공휴일)",
        "wgs84Lon": "경도",
        "wgs84Lat": "위도",
        "dutyInf": "기관설명상세",
        "dutyEtc": "비고",
    },
    # ID 기반 상세정보
    "detail": {
        "dgidIdName": "진료과목",
        "o008": "신생아 중환자실",
        "o009": "소아 중환자실",
        "o020": "소아응급전용 입원 병상",
        "o031": "소아 인공호흡기",
        "dutyTime1s": "진료시작(월요일)",
        "dutyTime1c": "진료종료(월요일)",
        "dutyTime2s": "진료시작(화요일)",
        "dutyTime2c": "진료종료(화요일)",
        "dutyTime3s": "진료시작(수요일)",
        "dutyTime3c": "진료종료(수요일)",
        "dutyTime4s": "진료시작(목요일)",
        "dutyTime4c": "진료종료(목요일)",
        "dutyTime5s": "진료시작(금요일)",
        "dutyTime5c": "진료종료(금요일)",
        "dutyTime6s": "진료시작(토요일)",
        "dutyTime6c": "진료종료(토요일)",
        "dutyTime7s": "진료시작(일요일)",
        "dutyTime7c": "진료종료(일요일)",
        "dutyTime8s": "진료시작(공휴일)",
        "dutyTime8c": "진료종료(공휴일)",
        "wgs84Lon": "경도",
        "wgs84Lat": "위도",
    },
}
SUBJECT_MAP = {
    "D001": "내과",
    "D002": "소아청소년과",
    "D003": "신경과",
    "D004": "정신건강의학과",
    "D005": "피부과",
    "D006": "외과",
    "D007": "흉부외과",
    "D008": "정형외과",
    "D009": "신경외과",
    "D010": "성형외과",
    "D011": "산부인과",
    "D012": "안과",
    "D013": "이비인후과",
    "D014": "비뇨기과",
    "D016": "재활의학과",
    "D017": "마취통증의학과",
    "D018": "영상의학과",
    "D019": "치료방사선과",
    "D020": "임상병리과",
    "D021": "해부병리과",
    "D022": "가정의학과",
    "D023": "핵의학과",
    "D024": "응급의학과",
    "D026": "치과",
    "D034": "구강악안면외과",
}
DUTY_DIV_MAP = {
    "A": ["상급종합병원", "종합병원"],
    "B": ["병원", "군 병원"],
    "C": ["의원", " 군 의원"],
    "D": ["요양병원"],
    "E": ["한방병원"],
    "G": ["한의원", "군 한의원"],
    "H": ["약국"],
    "I": ["기타"],
    "M": ["치과병원"],
    "N": ["치과의원"],
    "R": ["보건소", "보건지소", "보건진료소", "보건의료원"],
    "S": ["이송단체"],
    "T": ["119구급대"],
    "U": ["경찰서(교도소포함)"],
    "V": ["지방자치단체"],
    "W": ["기타시설", "군 기타"],
    "Y": ["중앙응급의료센터"],
    "Z": ["응급의료지원센터"],
}

# Info
INTRODUCTION_TITLE = "소개"
INTRODUCTION_TEXT = \
    "소아과탐색기는 아이가 아플 때 어찌해야 할지 몰라 우왕좌왕하던 초보 엄마와 아빠가 우리 주변에 있는 소아과 진료 병원에 대해 알려드리려고 만들었어요.\n" + \
    "알고 계시는 병원들에 대한 간단한 설문을 작성해주시면 아직 육아가 서투른, 혹은 지역이 처음이신 분들에게 큰 도움이 됩니다.\n" + \
    "우리 아이들이 더 안전한 환경에서 건강하게 자라나도록 보탬이 되었으면 합니다."
TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S"
