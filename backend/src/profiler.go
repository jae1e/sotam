package main

import (
	"log"
	"sync"
	"time"
)

type profileData struct {
	mutex         sync.Mutex
	count         int
	totalDuration int64
}

var _profileMap = make(map[string]*profileData)

func startProfiler(keys []string) {
	for _, key := range keys {
		_profileMap[key] = &profileData{
			mutex:         sync.Mutex{},
			count:         0,
			totalDuration: 0,
		}
	}

	// Start the routine to log summary every hour
	go _logProfileSummary()
}

func profilePerformance(key string, begin time.Time) {
	profile, ok := _profileMap[key]
	if !ok {
		log.Println("Wrong profile key: ", key)
		return
	}

	duration := time.Now().UnixMilli() - begin.UnixMilli()
	if duration < 0 {
		log.Printf("%s profile duration is incorrect: %d ms", key, duration)
		return
	}

	profile.mutex.Lock()
	profile.count++
	profile.totalDuration += duration
	profile.mutex.Unlock()
}

func _logProfileSummary() {
	// Repeat duration: 1 hour
	for range time.Tick(time.Hour) {
		for key, profile := range _profileMap {
			profile.mutex.Lock()

			// Print result
			var avgDuration float64
			if profile.count > 0 {
				avgDuration = float64(profile.totalDuration) / float64(profile.count)
			} else {
				avgDuration = 0
			}
			log.Printf("[Profiling summary] key: %s, count: %d, average duration (ms): %.3f\n",
				key, profile.count, avgDuration)

			// Reset data
			profile.count = 0
			profile.totalDuration = 0

			profile.mutex.Unlock()
		}
	}
}
