package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func checkCollectionExists(db *mongo.Database, collectionName string) bool {
	coll, err := db.ListCollectionNames(context.Background(),
		bson.D{{Key: "name", Value: collectionName}})
	if err != nil {
		log.Println("Failed to get collection names from db: " + err.Error())
	}
	return len(coll) == 1
}

func main() {
	// Set timezone
	location, err := time.LoadLocation("Asia/Seoul")
	if err != nil {
		log.Print(err)
		return
	}
	time.Local = location

	// Init profiler
	startProfiler([]string{
		ProfileKeyGetHospitals,
		ProfileKeyGetMoonlights,
		ProfileKeyGetSurveySummary})

	// MongoDB connection setup
	clientOptions := options.Client().ApplyURI(MongoUri)
	client, err := mongo.Connect(context.Background(), clientOptions)
	if err != nil {
		log.Print(err)
		return
	}

	// MongoDB collections
	db := client.Database(HospitalDatabaseName)

	infoCollection := db.Collection(InfoCollectionName)
	hospitalCollection := db.Collection(HospitalCollectionName)
	moonlightCollection := db.Collection(MoonlightCollectionName)
	holidayCollection := db.Collection(HolidayCollectionName)
	surveyCollection := db.Collection(SurveyCollectionName)
	likeCollection := db.Collection(LikeCollectionName)
	userCollection := db.Collection(UserCollectionName)
	announcementCollection := db.Collection(AnnouncementCollectionName)

	if checkCollectionExists(db, SurveyCollectionName) &&
		!ensureSurveyCollectionIndex(surveyCollection) {
		return
	}
	if checkCollectionExists(db, LikeCollectionName) &&
		!ensureLikeCollectionIndex(likeCollection) {
		return
	}

	// Info
	http.HandleFunc("/v1/database/last-update", handleGetDatabaseLastUpdate(infoCollection))
	http.HandleFunc("/v1/info/introduction", handleGetIntroduction(infoCollection))
	http.HandleFunc("/v1/info/last-update", handleGetLastInfoUpdate(infoCollection))

	// Hospital
	http.HandleFunc("/v1/hospital", handleGetHospital(
		hospitalCollection, holidayCollection, surveyCollection, likeCollection))
	http.HandleFunc("/v1/hospitals", handleGetFilteredHospitals(
		hospitalCollection, holidayCollection, surveyCollection, likeCollection))
	http.HandleFunc("/v1/moonlights", handleGetAllMoonlights(
		moonlightCollection, holidayCollection, surveyCollection, likeCollection))

	// Survey
	http.HandleFunc("/v1/survey/questions", handleGetSurveyQuestions())
	http.HandleFunc("/v1/survey/answer", handleGetSurveyAnswer(surveyCollection))
	http.HandleFunc("/v1/survey/summary", handleGetSurveySummary(surveyCollection))
	http.HandleFunc("/v1/survey/submit", handlePostSurveyAnswer(surveyCollection, userCollection))

	// Like
	http.HandleFunc("/v1/like", handlePostLike(likeCollection, userCollection))
	http.HandleFunc("/v1/like/count", handleGetLikeCount(likeCollection))
	http.HandleFunc("/v1/like/found", handleGetLikeFound(likeCollection))

	// User
	http.HandleFunc("/v1/user/survey/count", handleGetUserSurveyCount(userCollection))

	// Announcement
	http.HandleFunc("/v1/announcements", handleGetAnnouncements(announcementCollection))
	http.HandleFunc("/v1/announcements/last-update", handleGetAnnouncementsLastUpdate(announcementCollection))
	http.HandleFunc("/v1/announcement/post", handlePostAnnouncement(announcementCollection))
	http.HandleFunc("/v1/announcement/delete", handleDeleteAnnouncement(announcementCollection))

	// Holiday
	http.HandleFunc("/v1/holiday/today", handleGetIsTodayHoliday(holidayCollection))

	log.Printf("Server is running on port %d...", DefaultPort)
	log.Print(http.ListenAndServe(fmt.Sprintf(":%d", DefaultPort), nil))
}
