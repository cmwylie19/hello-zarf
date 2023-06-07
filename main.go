package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Let's kick Zarf's tires!🦄")
	})

	log.Println("Serving on port :8081 🦄")

	log.Fatal(http.ListenAndServe(":8081", nil))

}
