package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"slices"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

type HolidayDocument struct {
	Holidays []string `bson:"holidays"` // YYYYMMDD format
}

type IsTodayHolidayResponse struct {
	Response int `json:"response"`
}

func getIsTodayHoliday(collection *mongo.Collection) bool {
	var document HolidayDocument
	err := collection.FindOne(context.Background(), bson.M{}).Decode(&document)
	if err != nil && err != mongo.ErrNoDocuments {
		log.Println("Holiday DB is empty: " + err.Error())
		return false
	}

	// Return if today is holiday
	today := time.Now().Format("20060102")
	return slices.Contains(document.Holidays, today)
}

func handleGetIsTodayHoliday(collection *mongo.Collection) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "Only GET method is allowed", http.StatusMethodNotAllowed)
			return
		}

		if collection.Name() != HolidayCollectionName {
			log.Printf("Got wrong collection: %s", collection.Name())
			http.Error(w, "Wrong collection is assigned", http.StatusInternalServerError)
			return
		}

		isTodayHoliday := getIsTodayHoliday(collection)

		response := IsTodayHolidayResponse{
			Response: 0,
		}
		if isTodayHoliday {
			response.Response = 1
		}

		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(response)
	}
}
