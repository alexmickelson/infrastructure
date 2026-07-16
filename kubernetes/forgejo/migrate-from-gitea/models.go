package main

type User struct {
	ID        int64  `json:"id"`
	Login     string `json:"login"`
	FullName  string `json:"full_name"`
	Email     string `json:"email"`
	AvatarURL string `json:"avatar_url"`
	HTMLURL   string `json:"html_url"`
}

type Permission struct {
	Admin bool `json:"admin"`
	Push  bool `json:"push"`
	Pull  bool `json:"pull"`
}

type InternalTracker struct {
	EnableTimeTracker            bool `json:"enable_time_tracker"`
	AllowOnlyContributorsToTrack bool `json:"allow_only_contributors_to_track_time"`
	EnableIssueDependencies      bool `json:"enable_issue_dependencies"`
}

type Repo struct {
	ID                          int64           `json:"id"`
	Name                        string          `json:"name"`
	FullName                    string          `json:"full_name"`
	Description                 string          `json:"description"`
	Owner                       User            `json:"owner"`
	Private                     bool            `json:"private"`
	Fork                        bool            `json:"fork"`
	Mirror                      bool            `json:"mirror"`
	Template                    bool            `json:"template"`
	Parent                      *Repo           `json:"parent,omitempty"`
	CloneURL                    string          `json:"clone_url"`
	SSHURL                      string          `json:"ssh_url"`
	HTMLURL                     string          `json:"html_url"`
	URL                         string          `json:"url"`
	LanguagesURL                string          `json:"languages_url"`
	DefaultBranch               string          `json:"default_branch"`
	Language                    string          `json:"language"`
	Archived                    bool            `json:"archived"`
	ArchivedAt                  string          `json:"archived_at"`
	Empty                       bool            `json:"empty"`
	CreatedAt                   string          `json:"created_at"`
	UpdatedAt                   string          `json:"updated_at"`
	Size                        int64           `json:"size"`
	Stars                       int64           `json:"stars_count"`
	Forks                       int64           `json:"forks_count"`
	Watchers                    int64           `json:"watchers_count"`
	OpenIssues                  int64           `json:"open_issues_count"`
	OpenPulls                   int64           `json:"open_pr_counter"`
	Releases                    int64           `json:"release_counter"`
	Permissions                 Permission      `json:"permissions"`
	HasIssues                   bool            `json:"has_issues"`
	HasWiki                     bool            `json:"has_wiki"`
	HasWikiContents             bool            `json:"has_wiki_contents"`
	HasPullRequests             bool            `json:"has_pull_requests"`
	HasProjects                 bool            `json:"has_projects"`
	HasReleases                 bool            `json:"has_releases"`
	HasPackages                 bool            `json:"has_packages"`
	HasActions                  bool            `json:"has_actions"`
	InternalTracker             InternalTracker `json:"internal_tracker"`
	AllowMergeCommits           bool            `json:"allow_merge_commits"`
	AllowRebase                 bool            `json:"allow_rebase"`
	AllowRebaseExplicit         bool            `json:"allow_rebase_explicit"`
	AllowSquashMerge            bool            `json:"allow_squash_merge"`
	AllowFastForwardOnly        bool            `json:"allow_fast_forward_only_merge"`
	AllowRebaseUpdate           bool            `json:"allow_rebase_update"`
	Topics                      []string        `json:"topics"`
	ObjectFormatName            string          `json:"object_format_name"`
	WikiBranch                  string          `json:"wiki_branch"`
}

type CreateRepoRequest struct {
	Name        string `json:"name"`
	Private     bool   `json:"private"`
	Description string `json:"description"`
}
