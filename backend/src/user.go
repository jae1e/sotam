package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"strconv"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type UserDocument struct {
	UserId  string   `bson:"_id"`
	Likes   []string `bson:"likes"`   // Hospital ids that the user liked
	Surveys []string `bson:"surveys"` // Hospital ids that the user submitted survey
}

type SurveyCountResponse struct {
	Count int `json:"count"`
}

func recordUserLike(collection *mongo.Collection, userId string, hospitalId string, like bool) bool {
	if collection.Name() != UserCollectionName {
		log.Printf("Got wrong collection: %s", collection.Name())
		return false
	}

	// Define the filter
	filter := bson.M{"_id": userId}
	update := bson.M{}
	opts := options.UpdateOptions{}

	if like {
		// Like
		update = bson.M{"$addToSet": bson.M{"likes": hospitalId}}
		// Create document if it doesn't exist
		opts = *options.Update().SetUpsert(true)
	} else {
		// Unlike
		update = bson.M{"$pull": bson.M{"likes": hospitalId}}
	}

	_, err := collection.UpdateOne(context.Background(), filter, update, &opts)
	if err != nil {
		log.Println("Failed to record like " + strconv.FormatBool(like) +
			" of " + hospitalId + " to user " + userId + ": " +
			err.Error())
		return false
	}

	return true
}

func recordUserSurvey(collection *mongo.Collection, userId string, hospitalId string) bool {
	if collection.Name() != UserCollectionName {
		log.Printf("Got wrong collection: %s", collection.Name())
		return false
	}

	// Define the filter
	filter := bson.M{"_id": userId}
	update := bson.M{"$addToSet": bson.M{"surveys": hospitalId}}
	// Create document if it doesn't exist
	opts := *options.Update().SetUpsert(true)

	_, err := collection.UpdateOne(context.Background(), filter, update, &opts)
	if err != nil {
		log.Println("Failed to record survey of " + hospitalId +
			" to user " + userId + ": " + err.Error())
		return false
	}

	return true
}

func handleGetUserSurveyCount(collection *mongo.Collection) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "Only GET method is allowed", http.StatusMethodNotAllowed)
			return
		}

		if collection.Name() != UserCollectionName {
			log.Printf("Got wrong collection: %s", collection.Name())
			http.Error(w, "Wrong collection is assigned", http.StatusInternalServerError)
			return
		}

		userId := r.URL.Query().Get("userId")
		if userId == "" {
			http.Error(w, "userId is empty", http.StatusBadRequest)
			return
		}

		var document UserDocument
		err := collection.FindOne(context.Background(), bson.M{"_id": userId}).Decode(&document)

		// There is a chance that the document doesn't exist
		if err != nil && err != mongo.ErrNoDocuments {
			log.Println("Error while counting user surveys: " + err.Error())
			return
		}

		// Respond with the survey count
		response := SurveyCountResponse{
			Count: len(document.Surveys),
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	}
}
