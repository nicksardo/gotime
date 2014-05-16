package main

import (
	"log"
	"net/http"

	"github.com/NickSardo/GoTime"
)

func main() {
	http.HandleFunc("/time", gotime.NowHandler)

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		http.ServeFile(w, r, "index.html")
	})

	http.HandleFunc("/GoTime.js", func(w http.ResponseWriter, r *http.Request) {
		http.ServeFile(w, r, "../GoTime.js")
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
