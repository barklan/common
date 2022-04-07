// Backs up all repos from GitHub and GitLab.
package main

import (
	"bufio"
	"bytes"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"
)

const (
	backupDirPrefix = "hashi_"
	shallow         = true
)

var ghOrgs = []string{
	// "barklan",
	// "barklan-junk-yard",
	"hashicorp",
}

// Don't use your GitLab username as organization!
var glOrgs = []string{
	// "nftgalleryx",
	// "hrtalents",
	// "qufiwefefwoyn",
}

type ghJob struct {
	Org       string
	Repo      string
	BackupDir string
}

func prepareDir() (string, error) {
	now := time.Now()
	date := now.Format("2006_01_02")
	backupDir := backupDirPrefix + date
	home, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("failed to get home directory: %w", err)
	}
	fullBackupDir := filepath.Join(home, backupDir)
	log.Println("will be backing up to ", fullBackupDir)
	if err = os.Mkdir(fullBackupDir, 0o755); err != nil {
		return "", fmt.Errorf("failed to create backup directory: %w", err)
	}
	return fullBackupDir, nil
}

func worker(id int, jobs <-chan ghJob, results chan<- struct{}) {
	for j := range jobs {
		if err := cloneOneGHRepo(j.Org, j.Repo, j.BackupDir); err != nil {
			fmt.Printf("failed to clone one repo %q: %v\n", j.Repo, err)
		}
		log.Printf("cloned %q from GitHub (worker %d)\n", j.Repo, id)
		results <- struct{}{}
	}
}

func getGHRepos(org string) ([]string, error) {
	list, err := exec.Command("gh", "repo", "list", org, "--limit", "10000").Output()
	if err != nil {
		fmt.Println(string(list))
		return nil, fmt.Errorf("failed to list GitHub repos: %w", err)
	}
	repos := make([]string, 0)
	scanner := bufio.NewScanner(bytes.NewReader(list))
	for scanner.Scan() {
		repoLine := scanner.Text()
		repo := strings.Fields(repoLine)[0]
		repos = append(repos, repo)
	}
	return repos, nil
}

func cloneOneGHRepo(org, repo, backupDir string) error {
	repoName := strings.Split(repo, "/")[1]
	repoPath := filepath.Join(backupDir, org, repoName)
	extraArgs := []string{}
	if shallow {
		extraArgs = append(extraArgs, "--", "--depth=1")
	}
	args := append([]string{"repo", "clone", repo, repoPath}, extraArgs...)
	if _, err := exec.Command("gh", args...).Output(); err != nil {
		return fmt.Errorf("failed to clone one repo: %w", err)
	}
	return nil
}

func github(backupDir string) error {
	for _, org := range ghOrgs {
		orgDir := filepath.Join(backupDir, org)
		if err := os.Mkdir(orgDir, 0o755); err != nil {
			return fmt.Errorf("failed to create directory for organization %s: %w", org, err)
		}
		repos, err := getGHRepos(org)
		if err != nil {
			return fmt.Errorf("failed to get list of github repos: %w", err)
		}

		numRepos := len(repos)
		jobs := make(chan ghJob, numRepos)
		results := make(chan struct{}, numRepos)
		numWorkers := runtime.NumCPU() * 2
		for w := 1; w <= numWorkers; w++ {
			go worker(w, jobs, results)
		}
		fmt.Printf("Started %d workers to pull from GitHub\n", numWorkers)
		for _, repo := range repos {
			jobs <- ghJob{Org: org, Repo: repo, BackupDir: backupDir}
		}
		for i := 0; i < numRepos; i++ {
			<-results
		}
	}
	return nil
}

func gitlab(backupDir string) error {
	for _, org := range glOrgs {
		orgDir := filepath.Join(backupDir, org)
		if err := os.Mkdir(orgDir, 0o755); err != nil {
			return fmt.Errorf("failed to create directory for organization %s: %w", org, err)
		}
		wd, err := os.Getwd()
		if err != nil {
			return fmt.Errorf("failed to get current working directory: %w", err)
		}
		if err := os.Chdir(orgDir); err != nil {
			return fmt.Errorf("failed to change directory to %s: %w", orgDir, err)
		}
		if _, err := exec.Command("glab", "repo", "clone", "-g", org).Output(); err != nil {
			return fmt.Errorf("failed to clone repos from organization %s: %w", org, err)
		}
		if err := os.Chdir(wd); err != nil {
			return fmt.Errorf("failed to change directory back to %s: %w", wd, err)
		}
		log.Printf("cloned all repos from %q organization from GitLab\n", org)
	}
	return nil
}

func backup() error {
	backupDir, err := prepareDir()
	if err != nil {
		return fmt.Errorf("failed to prepare backup directory: %w", err)
	}

	if err := github(backupDir); err != nil {
		return fmt.Errorf("failed to backup github: %w", err)
	}

	if err := gitlab(backupDir); err != nil {
		return fmt.Errorf("failed to backup gitlab: %w", err)
	}

	log.Println("all done!")
	return nil
}

func main() {
	if err := backup(); err != nil {
		log.Fatal(err)
	}
}
