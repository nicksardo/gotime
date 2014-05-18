package main

import (
	"log"
	"runtime"
	"net/http"

	"github.com/NickSardo/GoTime"
)

func main() {
	runtime.GOMAXPROCS(runtime.NumCPU())

	http.HandleFunc("/time", gotime.NowHandler)

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		http.ServeFile(w, r, "index.html")
	})

	http.HandleFunc("/GoTime.js", func(w http.ResponseWriter, r *http.Request) {
		http.ServeFile(w, r, "../GoTime.js")
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
