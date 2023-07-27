package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Let's kick Zarf's tires!🦄")
	})
	http.Handle("/metrics", promhttp.Handler())

	log.Println("Serving on port :8081 🦄")

	log.Fatal(http.ListenAndServe(":8081", nil))

}
