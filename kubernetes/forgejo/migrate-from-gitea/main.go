package main

import (
	"bytes"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"

	"github.com/joho/godotenv"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Fatal("error loading .env file")
	}

	giteaRepos := read_repos("https://git.alexmickelson.guru", os.Getenv("GITEA_TOKEN"))
	forgejoRepos := read_repos("https://forgejo.alexmickelson.guru", os.Getenv("FORGEJO_TOKEN"))

	forgejoRepoNames := make([]string, 0, len(forgejoRepos))
	for _, r := range forgejoRepos {
		forgejoRepoNames = append(forgejoRepoNames, r.Name)
	}

	tmpDir, err := os.MkdirTemp("", "gitea-migrate-*")
	if err != nil {
		log.Fatal(err)
	}
	defer os.RemoveAll(tmpDir)

	for _, giteaRepo := range giteaRepos {
		if slices.Contains(forgejoRepoNames, giteaRepo.Name) {
			fmt.Printf("%s: skipped\n", giteaRepo.FullName)
			continue
		}

		newRepo := create_repo("https://forgejo.alexmickelson.guru", os.Getenv("FORGEJO_TOKEN"), giteaRepo.Name, giteaRepo.Private)

		clonePath := filepath.Join(tmpDir, giteaRepo.Name)
		cloneURL := fmt.Sprintf("https://alex:%s@%s", os.Getenv("GITEA_TOKEN"), strings.TrimPrefix(giteaRepo.CloneURL, "https://"))
		if err := runGit("clone", cloneURL, clonePath); err != nil {
			fmt.Printf("%s: clone failed - %v\n", giteaRepo.FullName, err)
			continue
		}

		pushURL := fmt.Sprintf("https://alex:%s@%s", os.Getenv("FORGEJO_TOKEN"), strings.TrimPrefix(newRepo.CloneURL, "https://"))
		if err := runGit("-C", clonePath, "remote", "add", "forgejo", pushURL); err != nil {
			fmt.Printf("%s: remote add failed - %v\n", giteaRepo.FullName, err)
			continue
		}
		if err := runGit("-C", clonePath, "push", "--mirror", "forgejo"); err != nil {
			fmt.Printf("%s: push failed - %v\n", giteaRepo.FullName, err)
			continue
		}

		fmt.Printf("%s: migrated\n", giteaRepo.FullName)
	}
}

func read_repos(baseURL string, token string) []Repo {
	req, _ := http.NewRequest("GET", baseURL+"/api/v1/user/repos", nil)
	req.Header.Set("Authorization", "Bearer "+token)

	client := &http.Client{
		Transport: &http.Transport{TLSClientConfig: &tls.Config{InsecureSkipVerify: true}},
	}
	resp, err := client.Do(req)
	if err != nil {
		log.Fatal(err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Fatal(err)
	}

	var repos []Repo
	if err := json.Unmarshal(body, &repos); err != nil {
		log.Fatal(err)
	}
	return repos
}

func create_repo(baseURL string, token string, name string, private bool) Repo {
	body, _ := json.Marshal(CreateRepoRequest{Name: name, Private: private})

	req, _ := http.NewRequest("POST", baseURL+"/api/v1/user/repos", bytes.NewBuffer(body))
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{
		Transport: &http.Transport{TLSClientConfig: &tls.Config{InsecureSkipVerify: true}},
	}
	resp, err := client.Do(req)
	if err != nil {
		log.Fatal(err)
	}
	defer resp.Body.Close()

	responseBody, _ := io.ReadAll(resp.Body)
	var repo Repo
	if err := json.Unmarshal(responseBody, &repo); err != nil {
		log.Fatal(err)
	}
	return repo
}

func runGit(args ...string) error {
	cmd := exec.Command("git", args...)
	cmd.Env = append(os.Environ(), "GIT_TERMINAL_PROMPT=0", "GIT_SSL_NO_VERIFY=1")
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("%w: %s", err, string(output))
	}
	return nil
}
