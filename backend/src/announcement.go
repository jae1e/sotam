package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type Announcement struct {
	Type      string `bson:"type" json:"type"` // "news" or "alert"
	Timestamp string `bson:"timestamp" json:"timestamp"`
	Title     string `bson:"title" json:"title"`
	Content   string `bson:"content" json:"content"`
}

type AnnouncementListResponse struct {
	Announcements []Announcement `json:"announcements"`
	TotalCount    int32          `json:"totalCount"`
	PageableCount int32          `json:"pageableCount"`
}

type LastAnnouncementUpdateResponse struct {
	Timestamp string `json:"timestamp"`
}

func isValidTimestamp(timestampStr string) bool {
	layout := TimestampFormat
	_, err := time.Parse(layout, timestampStr)
	return err == nil
}

func handleGetAnnouncements(collection *mongo.Collection) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "Only GET method is allowed", http.StatusMethodNotAllowed)
			return
		}

		if collection.Name() != AnnouncementCollectionName {
			log.Printf("Got wrong collection: %s", collection.Name())
			http.Error(w, "Wrong collection is assigned", http.StatusInternalServerError)
			return
		}

		// Add all condition to the filter if it exists
		getAllDocuments := false
		if r.URL.Query().Has("all") {
			getAllDocuments = true
		}

		// Get the total count of documents matching the filter
		totalCount, err := collection.CountDocuments(context.Background(), bson.M{})
		if err != nil {
			log.Println("Error in handleGetAnnouncements: CountDocuments: " + err.Error())
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		documents := []Announcement{}

		if totalCount > 0 {
			findOptions := options.Find()
			findOptions.SetSort(bson.D{{Key: "timestamp", Value: -1}}) // -1 for descending order
			// Set limit only when all option is off
			if !getAllDocuments {
				findOptions.SetLimit(AnnouncementPageableCount)
			}

			// Get the documents
			cursor, err := collection.Find(context.Background(), bson.M{}, findOptions)
			if err != nil {
				log.Println("Error in handleGetAnnouncements: collection.Find: " + err.Error())
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			defer cursor.Close(context.Background())

			for cursor.Next(context.Background()) {
				var document Announcement
				err = cursor.Decode(&document)
				if err != nil {
					log.Println("Announcement cursor decode error: " + err.Error())
				}
				documents = append(documents, document)
			}
		}

		response := AnnouncementListResponse{
			Announcements: documents,
			TotalCount:    int32(totalCount),
			PageableCount: int32(len(documents)),
		}
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(response)
	}
}

func handleGetAnnouncementsLastUpdate(collection *mongo.Collection) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "Only GET method is allowed", http.StatusMethodNotAllowed)
			return
		}

		if collection.Name() != AnnouncementCollectionName {
			log.Printf("Got wrong collection: %s", collection.Name())
			http.Error(w, "Wrong collection is assigned", http.StatusInternalServerError)
			return
		}

		findOptions := options.FindOne()
		findOptions.SetSort(bson.D{{Key: "timestamp", Value: -1}}) // -1 for descending order

		var document Announcement
		err := collection.FindOne(context.Background(), bson.M{}, findOptions).Decode(&document)
		if err != nil {
			log.Println("Error finding last announcement: " + err.Error())
		}

		response := LastAnnouncementUpdateResponse{
			Timestamp: document.Timestamp,
		}

		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(response)
	}
}

func handlePostAnnouncement(collection *mongo.Collection) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Only POST method is allowed", http.StatusMethodNotAllowed)
			return
		}

		if collection.Name() != AnnouncementCollectionName {
			log.Printf("Got wrong collection: %s", collection.Name())
			http.Error(w, "Wrong collection is assigned", http.StatusInternalServerError)
			return
		}

		var request Announcement
		err := json.NewDecoder(r.Body).Decode(&request)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			log.Println("Failed to decode announcement post request: " + err.Error())
			return
		}

		// Fill in timestamp if not valid
		if !isValidTimestamp(request.Timestamp) {
			request.Timestamp = time.Now().Format(TimestampFormat)
		}

		_, err = collection.InsertOne(context.Background(), request)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			log.Println("Failed to save or update announcement answer: " + err.Error())
			return
		}

		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, "Announcement submitted")
	}
}

func handleDeleteAnnouncement(collection *mongo.Collection) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodDelete {
			http.Error(w, "Only GET method is allowed", http.StatusMethodNotAllowed)
			return
		}

		if collection.Name() != AnnouncementCollectionName {
			log.Printf("Got wrong collection: %s", collection.Name())
			http.Error(w, "Wrong collection is assigned", http.StatusInternalServerError)
			return
		}

		timestamp := r.URL.Query().Get("timestamp")
		if timestamp == "" {
			log.Println("Error in handleDeleteAnnouncement: Bad timestamp param")
			http.Error(w, "Error in handleDeleteAnnouncement: Bad timestamp param", http.StatusBadRequest)
			return
		}

		filter := bson.M{"timestamp": timestamp}

		// Delete
		result, err := collection.DeleteOne(context.Background(), filter)
		if err != nil {
			log.Println("Error in handleDeleteAnnouncement: DeleteOne: " + err.Error())
			http.Error(w, "Error in handleDeleteAnnouncement: DeleteOne "+err.Error(), http.StatusInternalServerError)
		}

		if result.DeletedCount == 0 {
			fmt.Fprintf(w, "No documents found with the specified timestamp")
		} else {
			fmt.Fprintf(w, "Announcement deleted")
		}
	}
}
