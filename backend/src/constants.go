package main

const (
	AppName     = "SotamBackend"
	Version     = "1.0.0"
	DefaultPort = 8080

	// Profiler
	ProfileKeyGetHospitals     = "get_hospitals"
	ProfileKeyGetMoonlights    = "get_moonlights"
	ProfileKeyGetSurveySummary = "get_survey_summary"

	// Database
	MongoUri                   = "mongodb://mongo:27017"
	HospitalDatabaseName       = "hospital_database"
	InfoCollectionName         = "info"
	HospitalCollectionName     = "hospitals"
	MoonlightCollectionName    = "moonlights"
	HolidayCollectionName      = "holidays"
	SurveyCollectionName       = "surveys"
	LikeCollectionName         = "likes"
	UserCollectionName         = "users"
	AnnouncementCollectionName = "announcements"

	// Government
	GovApiKey     = "N/A"
	GovHolidayUrl = "http://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService/getRestDeInfo"

	// Backend API
	HospitalPageableCount     = 15
	AnnouncementPageableCount = 10
	TimestampFormat           = "2006-01-02 15:04:05"
)
