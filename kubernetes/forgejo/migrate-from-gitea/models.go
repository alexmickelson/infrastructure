package main

type RepoOwner struct {
	Id    int    `json:"id"`
	Login string `json:"login"`
}
type Repo struct {
	ID            int       `json:"id"`
	Name          string    `json:"name"`
	FullName      string    `json:"full_name"`
	Description   string    `json:"description"`
	Owner         RepoOwner `json:"owner"`
	Private       bool      `json:"private"`
	Fork          bool      `json:"fork"`
	Mirror        bool      `json:"mirror"`
	CloneURL      string    `json:"clone_url"`
	SSHURL        string    `json:"ssh_url"`
	HTMLURL       string    `json:"html_url"`
	DefaultBranch string    `json:"default_branch"`
	Language      string    `json:"language"`
	Archived      bool      `json:"archived"`
	Empty         bool      `json:"empty"`
	CreatedAt     string    `json:"created_at"`
	UpdatedAt     string    `json:"updated_at"`
}
type CreateRepoRequest struct {
	Name string `json:"name"`
	Private bool `json:"private"`
	Description string `json:"description"`
}
