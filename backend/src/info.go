package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

type GeneralInfo struct {
	LastUpdate        string `bson:"lastUpdate"`
	IntroductionTitle string `bson:"introductionTitle"`
	IntroductionText  string `bson:"introductionText"`
}

type IntroductionResponse struct {
	Title string `json:"title"`
	Text  string `json:"text"`
}

type LastInfoUpdateResponse struct {
	Timestamp string `json:"timestamp"`
}

func handleGetDatabaseLastUpdate(collection *mongo.Collection) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "Only GET method is allowed", http.StatusMethodNotAllowed)
			return
		}

		if collection.Name() != InfoCollectionName {
			log.Printf("Got wrong collection: %s", collection.Name())
			http.Error(w, "Wrong collection is assigned", http.StatusInternalServerError)
			return
		}

		// Get general info
		var generalInfo GeneralInfo
		err := collection.FindOne(context.Background(), bson.M{}).Decode(&generalInfo)
		if err != nil {
			log.Println("Error finding general info: " + err.Error())
			http.Error(w, "Error while finding general info", http.StatusInternalServerError)
		}

		response := LastInfoUpdateResponse{
			Timestamp: generalInfo.LastUpdate,
		}

		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(response)
	}
}

func handleGetIntroduction(collection *mongo.Collection) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "Only GET method is allowed", http.StatusMethodNotAllowed)
			return
		}

		if collection.Name() != InfoCollectionName {
			log.Printf("Got wrong collection: %s", collection.Name())
			http.Error(w, "Wrong collection is assigned", http.StatusInternalServerError)
			return
		}

		// Get general info
		var generalInfo GeneralInfo
		err := collection.FindOne(context.Background(), bson.M{}).Decode(&generalInfo)
		if err != nil {
			log.Println("Error finding general info: " + err.Error())
			http.Error(w, "Error while finding general info", http.StatusInternalServerError)
		}

		response := IntroductionResponse{
			Title: generalInfo.IntroductionTitle,
			Text:  generalInfo.IntroductionText,
		}

		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(response)
	}
}

func handleGetLastInfoUpdate(collection *mongo.Collection) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "Only GET method is allowed", http.StatusMethodNotAllowed)
			return
		}

		if collection.Name() != InfoCollectionName {
			log.Printf("Got wrong collection: %s", collection.Name())
			http.Error(w, "Wrong collection is assigned", http.StatusInternalServerError)
			return
		}

		// Get general info
		var generalInfo GeneralInfo
		err := collection.FindOne(context.Background(), bson.M{}).Decode(&generalInfo)
		if err != nil {
			log.Println("Error finding general info: " + err.Error())
			http.Error(w, "Error while finding general info", http.StatusInternalServerError)
		}

		response := LastInfoUpdateResponse{
			Timestamp: generalInfo.LastUpdate,
		}

		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(response)
	}
}
