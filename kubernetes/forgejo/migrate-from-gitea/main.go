package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"slices"

	"github.com/joho/godotenv"
)

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("error loading .env file")
	}
	gitea_base_url := "https://git.alexmickelson.guru"
	forgejo_base_url := "https://forgejo.alexmickelson.guru"
	gitea_token := os.Getenv("GITEA_TOKEN")
	forgejo_token := os.Getenv("FORGEJO_TOKEN")
	// fmt.Printf("gitea token %s, forgejo token %s\n", gitea_token, forgejo_token)

	gitea_repos := read_repos(gitea_base_url, gitea_token)
	forgejo_repos := read_repos(forgejo_base_url, forgejo_token)

	forgejo_repo_names := make([]string, 0)
	for _, r := range forgejo_repos {
		forgejo_repo_names = append(forgejo_repo_names, r.Name)
	}
	for _, r := range gitea_repos {
		if !slices.Contains(forgejo_repo_names, r.Name) {
			fmt.Println(r.Name, r.Language, r.CloneURL)
		}
	}
}

func read_repos(base_url string, token string) []Repo {
	req, _ := http.NewRequest("GET", base_url+"/api/v1/user/repos", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	client := &http.Client{}
	resp, err := client.Do(req)

	if err != nil {
		fmt.Println("error in request", err)
	}

	defer resp.Body.Close()
	response_body, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Println("error reading body", err)
	}

	var repos []Repo
	json_err := json.Unmarshal(response_body, &repos)
	if json_err != nil {
		log.Fatal(json_err)
	}

	return repos
}


func create_repo(base_url string, token string, name string, private bool) Repo {
	body, json_err := json.Marshal(CreateRepoRequest{
		Name:    name,
		Private: private,
	})
	if json_err != nil {
		log.Fatal(json_err)
	}
	req, req_err := http.NewRequest("POST", base_url+"/api/v1/user/repos", bytes.NewBuffer(body))
	if req_err != nil {
		log.Fatal(req_err)
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, resp_err := client.Do(req)
	if resp_err != nil {
		log.Fatal(resp_err)
	}
	defer resp.Body.Close()

	responseBody, readErr := io.ReadAll(resp.Body)
	if readErr != nil {
		log.Fatal(readErr)
	}

	var repo Repo
	unmarshalErr := json.Unmarshal(responseBody, &repo)
	if unmarshalErr != nil {
		log.Fatal(unmarshalErr)
	}

	return repo
}
