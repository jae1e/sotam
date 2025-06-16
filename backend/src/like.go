package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type LikeDocument struct {
	HospitalId string   `bson:"hospitalId"`
	UserIds    []string `bson:"userIds"` // User IDs who liked the hospital
}

type LikePostRequest struct {
	HospitalId string `json:"hospitalId"`
	UserId     string `json:"userId"`
	Like       int    `json:"like"` // 1: like 0: unlike
}

type LikeCountResponse struct {
	Count int `json:"count"`
}

type LikeFoundResponse struct {
	Found int `json:"found"`
}

func getLikeCount(collection *mongo.Collection, hospitalId string) int {
	if collection.Name() != LikeCollectionName {
		log.Printf("Got wrong collection: %s", collection.Name())
		return 0
	}

	var document LikeDocument
	err := collection.FindOne(context.Background(), bson.M{"hospitalId": hospitalId}).Decode(&document)

	// There is a chance that the document doesn't exist
	if err != nil && err != mongo.ErrNoDocuments {
		log.Println("Error while counting like: " + err.Error())
		return 0
	}

	return len(document.UserIds)
}

func ensureLikeCollectionIndex(collection *mongo.Collection) bool {
	if collection.Name() != LikeCollectionName {
		log.Printf("Got wrong collection: %s", collection.Name())
		return false
	}

	// Skip if collection is empty
	totalCount, err := collection.CountDocuments(context.Background(), bson.M{})
	if err != nil && err != mongo.ErrNoDocuments {
		log.Println("Error in counting in ensureLikeCollectionIndex: " + err.Error())
		return false
	} else if totalCount == 0 {
		log.Println("Skip ensureLikeCollectionIndex as collection is empty")
		return true
	}

	// Index model for hospital ID and user ID using bson.D for ordered keys
	indexModel := mongo.IndexModel{
		Keys: bson.D{
			{Key: "hospitalId", Value: 1}, // 1 for ascending order
		},
		Options: options.Index().SetUnique(false),
	}

	// Create the index
	_, err = collection.Indexes().CreateOne(context.Background(), indexModel)
	if err != nil {
		log.Println("Could not create index in like collection: " + err.Error())
	} else {
		log.Println("Like collection index created successfully")
	}
	return true
}

func handlePostLike(likeCollection *mongo.Collection,
	userCollection *mongo.Collection) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Only POST method is allowed", http.StatusMethodNotAllowed)
			return
		}

		if likeCollection.Name() != LikeCollectionName ||
			userCollection.Name() != UserCollectionName {
			log.Println("Wrong collection is assigned")
			http.Error(w, "Wrong collection is assigned", http.StatusInternalServerError)
			return
		}

		var likeReq LikePostRequest
		err := json.NewDecoder(r.Body).Decode(&likeReq)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			log.Println("Failed to decode like post request: " + err.Error())
			return
		}

		// Define the filter
		filter := bson.M{"hospitalId": likeReq.HospitalId}
		update := bson.M{}
		opts := options.UpdateOptions{}

		like := likeReq.Like != 0
		if like {
			// Like
			update = bson.M{"$addToSet": bson.M{"userIds": likeReq.UserId}}
			// Create document if it doesn't exist
			opts = *options.Update().SetUpsert(true)
		} else {
			// Unlike
			update = bson.M{"$pull": bson.M{"userIds": likeReq.UserId}}
		}

		_, err = likeCollection.UpdateOne(context.Background(), filter, update, &opts)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			log.Println("Failed to add like " + strconv.Itoa(likeReq.Like) +
				" to " + likeReq.HospitalId + " for " + likeReq.UserId + ": " +
				err.Error())
			return
		}

		// Record user activity
		recordUserLike(userCollection, likeReq.UserId, likeReq.HospitalId, like)

		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		fmt.Fprintf(w, "Like submitted")
	}
}

func handleGetLikeCount(collection *mongo.Collection) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "Only GET method is allowed", http.StatusMethodNotAllowed)
			return
		}

		if collection.Name() != LikeCollectionName {
			log.Printf("Got wrong collection: %s", collection.Name())
			http.Error(w, "Wrong collection is assigned", http.StatusInternalServerError)
			return
		}

		hospitalId := r.URL.Query().Get("hospitalId")
		if hospitalId == "" {
			http.Error(w, "hospitalId is empty", http.StatusBadRequest)
			return
		}

		response := LikeCountResponse{
			Count: getLikeCount(collection, hospitalId),
		}

		// Respond with the like count
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	}
}

func handleGetLikeFound(collection *mongo.Collection) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "Only GET method is allowed", http.StatusMethodNotAllowed)
			return
		}

		if collection.Name() != LikeCollectionName {
			log.Printf("Got wrong collection: %s", collection.Name())
			http.Error(w, "Wrong collection is assigned", http.StatusInternalServerError)
			return
		}

		hospitalId := r.URL.Query().Get("hospitalId")
		if hospitalId == "" {
			http.Error(w, "hospitalId is empty", http.StatusBadRequest)
			return
		}

		userId := r.URL.Query().Get("userId")
		if userId == "" {
			http.Error(w, "userId is empty", http.StatusBadRequest)
			return
		}

		var document LikeDocument
		err := collection.FindOne(context.Background(), bson.M{"hospitalId": hospitalId}).Decode(&document)

		// There is a chance that the document doesn't exist
		if err != nil && err != mongo.ErrNoDocuments {
			log.Println("Error while finding like: " + err.Error())
			http.Error(w, "Error while finding like", http.StatusInternalServerError)
			return
		}

		// Check if userId is in the likes array
		response := LikeFoundResponse{
			Found: 0,
		}
		for _, id := range document.UserIds {
			if id == userId {
				response.Found = 1
			}
		}

		// Respond with the like found
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	}
}
