package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type SurveyQuestion struct {
	Type          string   `json:"type"` // "selection", "text"
	Options       []string `json:"options"`
	MaxTextLength int      `json:"maxTextLength"`
}

type SurveyQuestionsResponse struct {
	Questions map[string]SurveyQuestion `json:"questions"`
}

type SurveyAnswer struct {
	Type   string `bson:"type" json:"type"`
	Option string `bson:"option" json:"option"`
	Text   string `bson:"text" json:"text"`
}

type SurveyAnswerDocument struct {
	HospitalId string                  `json:"hospitalId"`
	UserId     string                  `json:"userId"`
	Timestamp  string                  `json:"timestamp"`
	Answers    map[string]SurveyAnswer `json:"answers"`
}

type SurveySummary struct {
	Type         string   `json:"type"`
	Options      []string `json:"options"`
	OptionCounts []int    `json:"optionCounts"`
	Texts        []string `json:"texts"`
}

type SurveySummaryResponse struct {
	HospitalId string                   `json:"hospitalId"`
	TotalCount int                      `json:"totalCount"`
	Summaries  map[string]SurveySummary `json:"summaries"`
}

var SurveyQuestionMap = map[string]SurveyQuestion{
	// Space
	"waitingSpace": {
		Type: "selection",
		Options: []string{
			"smallSpace", "average", "bigSpace",
		},
	},
	"parkingDifficulty": {
		Type: "selection",
		Options: []string{
			"easy", "hard",
		},
	},
	"cleanliness": {
		Type: "selection",
		Options: []string{
			"clean", "average", "no",
		},
	},
	// Treatment
	"kindness": {
		Type: "selection",
		Options: []string{
			"kind", "average", "no",
		},
	},
	"thoroughness": {
		Type: "selection",
		Options: []string{
			"thorough", "average", "no",
		},
	},
	"medicineStrength": {
		Type: "selection",
		Options: []string{
			"weak", "average", "strong",
		},
	},
	"ivTreatment": {
		Type: "selection",
		Options: []string{
			"do", "dont",
		},
	},
	"whenToVisit": {
		Type: "selection",
		Options: []string{
			"littleSick", "verySick",
		},
	},
	// Checkup
	"checkupAvailable": {
		Type: "selection",
		Options: []string{
			"do", "dont",
		},
	},
	"checkupWaiting": {
		Type: "selection",
		Options: []string{
			"below1day", "below7day", "over7day",
		},
	},
	// Unused
	"morningWaiting": {
		Type: "selection",
		Options: []string{
			"below15min", "below30min", "below60min", "over60min",
		},
	},
	"afternoonWaiting": {
		Type: "selection",
		Options: []string{
			"below15min", "below30min", "below60min", "over60min",
		},
	},
	"tipForVisitors": {
		Type:          "text",
		MaxTextLength: 20,
	},
}

func getSurveyCount(collection *mongo.Collection, hospitalId string) int {
	filter := bson.M{"hospitalId": hospitalId}

	// Get the total count of documents matching the filter
	totalCount, err := collection.CountDocuments(context.Background(), filter)
	if err != nil && err != mongo.ErrNoDocuments {
		log.Println("Error in getSurveyCount: for " + hospitalId + ": " + err.Error())
		return 0
	}

	return int(totalCount)
}

func ensureSurveyCollectionIndex(collection *mongo.Collection) bool {
	if collection.Name() != SurveyCollectionName {
		log.Printf("Got wrong collection: %s", collection.Name())
		return false
	}

	// Skip if collection is empty
	totalCount, err := collection.CountDocuments(context.Background(), bson.M{})
	if err != nil && err != mongo.ErrNoDocuments {
		log.Println("Error in counting in ensureSurveyCollectionIndex: " + err.Error())
		return false
	} else if totalCount == 0 {
		log.Println("Skip ensureSurveyCollectionIndex as collection is empty")
		return true
	}

	// Index model for hospital ID and user ID using bson.D for ordered keys
	indexModel := mongo.IndexModel{
		Keys: bson.D{
			{Key: "hospitalId", Value: 1}, // 1 for ascending order
			{Key: "userId", Value: 1},
		},
		Options: options.Index().SetUnique(false),
	}

	// Create the index
	_, err = collection.Indexes().CreateOne(context.Background(), indexModel)
	if err != nil {
		log.Println("Could not create index in survey collection: " + err.Error())
	} else {
		log.Println("Survey collection index created successfully")
	}
	return true
}

func handleGetSurveyQuestions() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "Only GET method is allowed", http.StatusMethodNotAllowed)
			return
		}

		response := SurveyQuestionsResponse{
			Questions: SurveyQuestionMap,
		}
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(response)
	}
}

func handlePostSurveyAnswer(surveyCollection *mongo.Collection,
	userCollection *mongo.Collection) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Only POST method is allowed", http.StatusMethodNotAllowed)
			return
		}

		if surveyCollection.Name() != SurveyCollectionName ||
			userCollection.Name() != UserCollectionName {
			log.Println("Wrong collection is assigned")
			http.Error(w, "Wrong collection is assigned", http.StatusInternalServerError)
			return
		}

		var surveyReq SurveyAnswerDocument
		err := json.NewDecoder(r.Body).Decode(&surveyReq)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			log.Println("Failed to decode survey post request: " + err.Error())
			return
		}

		// Define the filter for the document to update or insert
		filter := bson.M{"hospitalId": surveyReq.HospitalId, "userId": surveyReq.UserId}

		// Update or insert the document
		update := bson.M{"$set": surveyReq}
		opts := options.Update().SetUpsert(true) // Set the Upsert option

		result, err := surveyCollection.UpdateOne(context.Background(), filter, update, opts)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			log.Println("Failed to save or update survey answer: " + err.Error())
			return
		}

		// Record user activity
		recordUserSurvey(userCollection, surveyReq.UserId, surveyReq.HospitalId)

		// Check if a new document was inserted
		if result.UpsertedCount > 0 {
			w.WriteHeader(http.StatusCreated) // 201 Created for a new document
		} else {
			w.WriteHeader(http.StatusOK) // 200 OK for an update
		}
		fmt.Fprintf(w, "Survey submitted")
	}
}

func handleGetSurveyAnswer(collection *mongo.Collection) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "Only GET method is allowed", http.StatusMethodNotAllowed)
			return
		}

		if collection.Name() != SurveyCollectionName {
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

		var result SurveyAnswerDocument

		filter := bson.M{"hospitalId": hospitalId, "userId": userId}
		err := collection.FindOne(context.Background(), filter).Decode(&result)
		if err != nil && err != mongo.ErrNoDocuments {
			log.Println("Error while searching survey answer: " + err.Error())
			http.Error(w, "Error while searching survey answer", http.StatusInternalServerError)
			return
		}

		// Respond with the survey answer
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(result)
	}
}

func makeSurveySummaryPipelineEntries(key string, question SurveyQuestion) ([]string, []bson.D) {
	keys := []string{}
	entries := []bson.D{}
	for _, option := range question.Options {
		keys = append(keys, key+"?"+option)
		entries = append(entries, bson.D{{Key: "$sum",
			Value: bson.D{{Key: "$cond",
				Value: bson.A{bson.D{{Key: "$eq",
					Value: bson.A{"$answers." + key + ".option", option}}}, 1, 0}}}}})
	}
	return keys, entries
}

func handleGetSurveySummary(collection *mongo.Collection) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		begin := time.Now()

		if r.Method != http.MethodGet {
			http.Error(w, "Only GET method is allowed", http.StatusMethodNotAllowed)
			return
		}

		if collection.Name() != SurveyCollectionName {
			log.Printf("Got wrong collection: %s", collection.Name())
			http.Error(w, "Wrong collection is assigned", http.StatusInternalServerError)
			return
		}

		hospitalId := r.URL.Query().Get("hospitalId")
		if hospitalId == "" {
			http.Error(w, "hospitalId is empty", http.StatusBadRequest)
			return
		}

		// Define the aggregation pipeline for selection option counting
		searchKeys := []string{}
		groupStage := bson.D{
			{Key: "_id", Value: nil},                                    // Group all documents together
			{Key: "totalCount", Value: bson.D{{Key: "$sum", Value: 1}}}, // Count total surveys
		}
		for key, question := range SurveyQuestionMap {
			if question.Type != "selection" {
				continue
			}
			keys, entries := makeSurveySummaryPipelineEntries(key, question)
			searchKeys = append(searchKeys, keys...)
			for i := 0; i < len(keys); i++ {
				groupStage = append(groupStage, bson.E{Key: keys[i], Value: entries[i]})
			}
		}
		pipeline := mongo.Pipeline{
			bson.D{{Key: "$match", Value: bson.D{{Key: "hospitalId", Value: hospitalId}}}},
			bson.D{{Key: "$group", Value: groupStage}},
		}

		// Perform the aggregation
		cursor, err := collection.Aggregate(context.Background(), pipeline)
		if err != nil {
			log.Println("Survey summary aggregation error: " + err.Error())
		}
		defer cursor.Close(context.Background())

		// Decode result
		var result bson.M
		for cursor.Next(context.Background()) {
			err = cursor.Decode(&result)
			if err != nil {
				log.Println("Survey summary cursor decode error: " + err.Error())
			}
		}

		response := SurveySummaryResponse{
			HospitalId: hospitalId,
			TotalCount: 0,
			Summaries:  map[string]SurveySummary{},
		}

		if len(result) > 0 {
			totalCount32, ok := result["totalCount"].(int32)
			if !ok {
				log.Println("Survey summary total count is not integer: ", totalCount32)
				totalCount32 = 0
			}
			response.TotalCount = int(totalCount32)

			for _, key := range searchKeys {
				// Currently, the value should be always integer
				int32Val, ok := result[key].(int32)
				if !ok {
					log.Println("Survey summary value is not integer: ", key, result[key])
					continue
				}
				intVal := int(int32Val)
				split := strings.Split(key, "?")
				if len(split) != 2 {
					log.Println("Survey summary key format is wrong: ", key)
					continue
				}
				question := split[0]
				option := split[1]

				// Get summary
				summary, ok := response.Summaries[question]
				if !ok {
					summary = SurveySummary{
						Type:         "selection",
						Options:      []string{},
						OptionCounts: []int{},
					}
					response.Summaries[question] = summary
				}

				// Set option count
				summary.Options = append(summary.Options, option)
				summary.OptionCounts = append(summary.OptionCounts, intVal)
				response.Summaries[question] = summary
			}
		}

		// Respond with the survey answer
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)

		profilePerformance(ProfileKeyGetSurveySummary, begin)
	}
}
