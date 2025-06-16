package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"reflect"
	"strconv"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

type GeoJSON struct {
	Type        string    `bson:"type"`
	Coordinates []float64 `bson:"coordinates"` // [lng, lat]
}

type DatabaseHospital struct {
	Hpid       string  `bson:"_id"`
	DutyName   string  `bson:"dutyName"`   // 기관명
	DutyAddr   string  `bson:"dutyAddr"`   // 주소
	DutyTel1   string  `bson:"dutyTel1"`   // 대표전화1
	DutyDiv    string  `bson:"dutyDiv"`    // 병원분류 (코드)
	DutyDivNam string  `bson:"dutyDivNam"` // 병원분류명 (병원, 의원 등)
	DutyEryn   string  `bson:"dutyEryn"`   // 응급실운영여부 (1/2)
	DutyTel3   string  `bson:"dutyTel3"`   // 응급실전화
	DutyTime1s string  `bson:"dutyTime1s"` // 월요일 시작
	DutyTime1c string  `bson:"dutyTime1c"` // 월요일 종료
	DutyTime2s string  `bson:"dutyTime2s"`
	DutyTime2c string  `bson:"dutyTime2c"`
	DutyTime3s string  `bson:"dutyTime3s"`
	DutyTime3c string  `bson:"dutyTime3c"`
	DutyTime4s string  `bson:"dutyTime4s"`
	DutyTime4c string  `bson:"dutyTime4c"`
	DutyTime5s string  `bson:"dutyTime5s"`
	DutyTime5c string  `bson:"dutyTime5c"`
	DutyTime6s string  `bson:"dutyTime6s"`
	DutyTime6c string  `bson:"dutyTime6c"`
	DutyTime7s string  `bson:"dutyTime7s"` // 일요일 시작
	DutyTime7c string  `bson:"dutyTime7c"` // 일요일 종료
	DutyTime8s string  `bson:"dutyTime8s"` // 공휴일 시작
	DutyTime8c string  `bson:"dutyTime8c"` // 공휴일 종료
	DutyInf    string  `bson:"dutyInf"`    // 기관설명상세
	DutyEtc    string  `bson:"dutyEtc"`    // 비고
	DgidIdName string  `bson:"dgidIdName"` // 진료과목
	Location   GeoJSON `bson:"location"`   // 좌표
}

type ResponseHospital struct {
	Hpid              string         `json:"hpid"`
	Name              string         `json:"name"`              // 기관명
	Address           string         `json:"address"`           // 주소
	Phone             string         `json:"phone"`             // 대표전화1
	Type              string         `json:"type"`              // 병원분류명 (병원, 의원 등)
	Subjects          []string       `json:"subjects"`          // 진료과목
	Coordinates       []float64      `json:"coordinates"`       // [lng, lat]
	DetailInfo        []string       `json:"detailInfo"`        // 기관설명상세
	OperatingHoursMap map[int]string `json:"operatingHoursMap"` // Keys: 1 (monday) ~ 8 (holiday)
	OperatingStatus   string         `json:"operatingStatus"`   // "open", "finished", "unknown", "notOpenedToday"
	SurveyCount       int            `json:"surveyCount"`
	LikeCount         int            `json:"likeCount"`
}

type HospotalListResponse struct {
	Hospitals     []ResponseHospital `json:"hospitals"`
	TotalCount    int32              `json:"totalCount"`
	PageableCount int32              `json:"pageableCount"`
}

func getDayKey(holidayCollection *mongo.Collection) int {
	isTodayHoliday := getIsTodayHoliday(holidayCollection)
	var day = 8 // holidays
	if !isTodayHoliday {
		// Go's time.Weekday() returns an int starting from Sunday = 0
		day = int(time.Now().Weekday())
		if day == 0 { // Convert Sunday from 0 to 7 to match Dart's DateTime.now().weekday
			day = 7
		}
	}
	return day
}

func getFilterWithStatusParam(filter bson.M, status string, dayKey int) bson.M {
	if status == "openToday" || status == "openNow" || status == "openSunday" {
		if status == "openSunday" {
			dayKey = 7
		}

		startKey := fmt.Sprintf("dutyTime%ds", dayKey)
		endKey := fmt.Sprintf("dutyTime%dc", dayKey)

		startFilter := bson.M{"$regex": "^\\d{4}$"}
		endFilter := bson.M{"$regex": "^\\d{4}$"}

		if status == "openNow" {
			currentTime := time.Now().Format("1504")
			startFilter["$lte"] = currentTime
			endFilter["$gte"] = currentTime
		}

		filter[startKey] = startFilter
		filter[endKey] = endFilter
	}
	return filter
}

func newResponseHospital(data DatabaseHospital,
	dayKey int,
	surveyCollection *mongo.Collection,
	likeCollection *mongo.Collection) *ResponseHospital {
	response := ResponseHospital{
		Hpid:              data.Hpid,
		Name:              data.DutyName,
		Address:           data.DutyAddr,
		Phone:             data.DutyTel1,
		Type:              data.DutyDivNam,
		Subjects:          strings.Split(data.DgidIdName, ","),
		Coordinates:       data.Location.Coordinates,
		DetailInfo:        []string{},
		OperatingHoursMap: map[int]string{},
		OperatingStatus:   "unknown",
		SurveyCount:       0,
		LikeCount:         0,
	}

	// DetailInfo
	if data.DutyInf != "" {
		response.DetailInfo = append(response.DetailInfo, data.DutyInf)
	}
	if data.DutyEtc != "" {
		response.DetailInfo = append(response.DetailInfo, data.DutyEtc)
	}

	// OperatingHoursMap
	for i := 1; i < 9; i++ {
		startKey := fmt.Sprintf("DutyTime%ds", i)
		closeKey := fmt.Sprintf("DutyTime%dc", i)
		start := reflect.Indirect(reflect.ValueOf(data)).FieldByName(startKey).String()
		close := reflect.Indirect(reflect.ValueOf(data)).FieldByName(closeKey).String()

		// Continue if start or close time does not exist or is empty
		if start == "" || close == "" {
			continue
		}
		// Check the length of start and close times
		if len(start) != 4 || len(close) != 4 {
			log.Printf("Error in operating time: start %s close %s", start, close)
		}
		// Attempt to parse the times to ensure they are numbers
		if _, err := strconv.Atoi(start); err != nil {
			log.Printf("Error parsing start time %s: %v", start, err)
		}
		if _, err := strconv.Atoi(close); err != nil {
			log.Printf("Error parsing close time %s: %v", close, err)
		}

		// Construct the time string and assign it to operatingHours
		response.OperatingHoursMap[i] = start[:2] + ":" + start[2:] + "-" + close[:2] + ":" + close[2:]
	}

	// OperatingStatus
	nowTime := time.Now().Format("15:04")
	if len(response.OperatingHoursMap) > 0 {
		hours, ok := response.OperatingHoursMap[dayKey]
		if !ok {
			// Mark notOpenedToday if the day's operating hours is empty
			response.OperatingStatus = "notOpenedToday"
		} else {
			times := strings.Split(hours, "-") // HH:mm-HH:mm
			if len(times) == 2 {
				// Parse the start and end times
				startTime := strings.TrimSpace(times[0])
				endTime := strings.TrimSpace(times[1])
				if len(startTime) == 5 && len(endTime) == 5 {
					// Compare current time with start and end times
					if nowTime >= startTime && nowTime <= endTime {
						response.OperatingStatus = "open"
					} else {
						response.OperatingStatus = "finished"
					}
				} else {
					log.Printf("Operating hours has wrong format: %s - %s", times[0], times[1])
					response.OperatingStatus = "unknown"
				}
			}
		}
	}

	// SurveyCount
	response.SurveyCount = getSurveyCount(surveyCollection, data.Hpid)

	// LikeCount
	response.LikeCount = getLikeCount(likeCollection, data.Hpid)

	return &response
}

func handleGetHospital(
	hospitalCollection *mongo.Collection,
	holidayCollection *mongo.Collection,
	surveyCollection *mongo.Collection,
	likeCollection *mongo.Collection) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "Only GET method is allowed", http.StatusMethodNotAllowed)
			return
		}

		if hospitalCollection.Name() != HospitalCollectionName ||
			holidayCollection.Name() != HolidayCollectionName ||
			surveyCollection.Name() != SurveyCollectionName ||
			likeCollection.Name() != LikeCollectionName {
			log.Println("Wrong collection is assigned")
			http.Error(w, "Wrong collection is assigned", http.StatusInternalServerError)
			return
		}

		hospitalId := r.URL.Query().Get("hospitalId")
		if hospitalId == "" {
			log.Println("Get hospital: hospitalId is empty")
			http.Error(w, "Get hospital: hospitalId is empty", http.StatusBadRequest)
			return
		}

		var document DatabaseHospital
		err := hospitalCollection.FindOne(context.Background(), bson.M{"_id": hospitalId}).Decode(&document)
		if err != nil {
			log.Println("Error while finding hospital " + hospitalId + ": " + err.Error())
			http.Error(w, "Error while finding hospital", http.StatusInternalServerError)
			return
		}

		// Create response hospitals with extra properties
		dayKey := getDayKey(holidayCollection)
		responseHospitals := []ResponseHospital{
			*newResponseHospital(document, dayKey, surveyCollection, likeCollection),
		}

		response := HospotalListResponse{
			Hospitals:     responseHospitals,
			TotalCount:    1,
			PageableCount: 1,
		}
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(response)
	}
}

func handleGetFilteredHospitals(
	hospitalCollection *mongo.Collection,
	holidayCollection *mongo.Collection,
	surveyCollection *mongo.Collection,
	likeCollection *mongo.Collection) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		begin := time.Now()

		if r.Method != http.MethodGet {
			http.Error(w, "Only GET method is allowed", http.StatusMethodNotAllowed)
			return
		}

		if hospitalCollection.Name() != HospitalCollectionName ||
			holidayCollection.Name() != HolidayCollectionName ||
			surveyCollection.Name() != SurveyCollectionName ||
			likeCollection.Name() != LikeCollectionName {
			log.Println("Wrong collection is assigned")
			http.Error(w, "Wrong collection is assigned", http.StatusInternalServerError)
			return
		}

		// Get bounding box params
		swlng, err := strconv.ParseFloat(r.URL.Query().Get("swlng"), 64)
		if err != nil {
			log.Println("Error in FilteredHospital: Bad swlng param: " + err.Error())
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		swlat, err := strconv.ParseFloat(r.URL.Query().Get("swlat"), 64)
		if err != nil {
			log.Println("Error in FilteredHospital: Bad swlat param: " + err.Error())
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		nelng, err := strconv.ParseFloat(r.URL.Query().Get("nelng"), 64)
		if err != nil {
			log.Println("Error in FilteredHospital: Bad nelng param: " + err.Error())
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		nelat, err := strconv.ParseFloat(r.URL.Query().Get("nelat"), 64)
		if err != nil {
			log.Println("Error in FilteredHospital: Bad nelat param: " + err.Error())
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		box := bson.A{
			bson.A{swlng, swlat},
			bson.A{nelng, nelat},
		}

		// Filter with location and category
		typeCodes := []string{
			"A", "B", "C", "R", "Y", "Z", // 종합병원, 병원, 의원, 보건소, 중앙응급의료센터, 응급의료지원센터
		}
		filter := bson.M{
			// Inside the bounding box
			"location": bson.M{"$geoWithin": bson.M{"$box": box}},
			// Has 소아청소년과
			"dgidIdName": bson.M{"$regex": "소아청소년과"},
			// In hospital type
			"dutyDiv": bson.M{"$in": typeCodes},
		}

		// Add pedonly condition to the filter if it exists
		if r.URL.Query().Has("pedonly") {
			filter["dutyName"] = bson.M{"$regex": "소아"}
		}

		dayKey := getDayKey(holidayCollection)

		// Add operating status filter
		status := r.URL.Query().Get("status")
		filter = getFilterWithStatusParam(filter, status, dayKey)

		// Sample hospitals
		// NOTE: Performance optimization applied
		// Instead of counting with CountDocuments to get actual total counts,
		// sample [pageable count] + 1 hospitals and then send only [pageable count] results,
		// so that the app knows that there are more hospitals than results
		sampleStage := bson.D{
			{Key: "$sample", Value: bson.D{
				{Key: "size", Value: HospitalPageableCount + 1},
			}},
		}
		pipeline := mongo.Pipeline{
			bson.D{
				{Key: "$match", Value: filter},
			},
			sampleStage,
		}
		cursor, err := hospitalCollection.Aggregate(context.Background(), pipeline)
		if err != nil {
			log.Println("Error in FilteredHospital: collection.Aggregate: " + err.Error())
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		defer cursor.Close(context.Background())

		var documents []DatabaseHospital
		if err := cursor.All(context.Background(), &documents); err != nil {
			log.Println("Error in FilteredHospital: cursor.All: " + err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// Create response hospitals with extra properties
		var responseHospitals []ResponseHospital
		for i := 0; i < min(len(documents), HospitalPageableCount); i++ {
			responseHospitals = append(responseHospitals,
				*newResponseHospital(documents[i], dayKey, surveyCollection, likeCollection))
		}

		// TODO: When server becomes more powerful,
		// Use count document to calculate correct total count
		response := HospotalListResponse{
			Hospitals:     responseHospitals,
			TotalCount:    int32(len(documents)),
			PageableCount: int32(len(responseHospitals)),
		}
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(response)

		profilePerformance(ProfileKeyGetHospitals, begin)
	}
}

func handleGetAllMoonlights(
	moonlightCollection *mongo.Collection,
	holidayCollection *mongo.Collection,
	surveyCollection *mongo.Collection,
	likeCollection *mongo.Collection) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		begin := time.Now()

		if r.Method != http.MethodGet {
			http.Error(w, "Only GET method is allowed", http.StatusMethodNotAllowed)
			return
		}

		if moonlightCollection.Name() != MoonlightCollectionName ||
			holidayCollection.Name() != HolidayCollectionName ||
			surveyCollection.Name() != SurveyCollectionName ||
			likeCollection.Name() != LikeCollectionName {
			log.Println("Wrong collection is assigned")
			http.Error(w, "Wrong collection is assigned", http.StatusInternalServerError)
			return
		}

		// Get bounding box params
		swlng, err := strconv.ParseFloat(r.URL.Query().Get("swlng"), 64)
		if err != nil {
			log.Println("Error in AllHospitals: Bad swlng param: " + err.Error())
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		swlat, err := strconv.ParseFloat(r.URL.Query().Get("swlat"), 64)
		if err != nil {
			log.Println("Error in AllHospitals: Bad swlat param: " + err.Error())
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		nelng, err := strconv.ParseFloat(r.URL.Query().Get("nelng"), 64)
		if err != nil {
			log.Println("Error in AllHospitals: Bad nelng param: " + err.Error())
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		nelat, err := strconv.ParseFloat(r.URL.Query().Get("nelat"), 64)
		if err != nil {
			log.Println("Error in AllHospitals: Bad nelat param: " + err.Error())
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		box := bson.A{
			bson.A{swlng, swlat},
			bson.A{nelng, nelat},
		}

		// Get filter
		filter := bson.M{
			"location": bson.M{
				"$geoWithin": bson.M{"$box": box},
			},
		}

		dayKey := getDayKey(holidayCollection)

		// Add operating status filter
		status := r.URL.Query().Get("status")
		filter = getFilterWithStatusParam(filter, status, dayKey)

		// Get the documents
		cursor, err := moonlightCollection.Find(context.Background(), filter)
		if err != nil {
			log.Println("Error in AllHospital: collection.Find: " + err.Error())
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		defer cursor.Close(context.Background())

		var documents []DatabaseHospital
		if err = cursor.All(context.Background(), &documents); err != nil {
			log.Println("Error in AllHospital: cursor.All: " + err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// Create response hospitals
		var responseHospitals []ResponseHospital
		for _, document := range documents {
			responseHospitals = append(responseHospitals,
				*newResponseHospital(document, dayKey, surveyCollection, likeCollection))
		}

		response := HospotalListResponse{
			Hospitals:     responseHospitals,
			TotalCount:    int32(len(responseHospitals)),
			PageableCount: int32(len(responseHospitals)),
		}
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(response)

		profilePerformance(ProfileKeyGetMoonlights, begin)
	}
}
