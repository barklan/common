package main

import (
	"errors"
	"flag"
	"fmt"
	"log"
	"os"
	"regexp"
	"strings"
)

const start = `{
    "version": "2.0.0",
    "tasks": [`

const end = `
    ],
}
`

var runshFilepath, tasksFilepath string

func runShCmds(path string) []string {
	content, err := os.ReadFile(path)
	if err != nil {
		log.Panicln("failed to read run.sh", err)
	}

	r, err := regexp.Compile(`(\S*) *\(\) *({|\()`)
	if err != nil {
		log.Panicln(err)
	}

	matches := r.FindAllStringSubmatch(string(content), -1)

	cmds := make([]string, 0)
	for _, match := range matches {
		cmd := match[1]
		if !(string(cmd[0]) == "_" || cmd == "help") {
			cmds = append(cmds, match[1])
		}
	}
	return cmds
}

func main() {
	flag.StringVar(&runshFilepath, "r", "", "absolute path to run.sh")
	flag.StringVar(&tasksFilepath, "t", "", "absolute path to tasks.json")

	flag.Parse()

	if runshFilepath == "" || tasksFilepath == "" {
		log.Panicln("empty filepaths")
	}

	vscodeDir := strings.TrimSuffix(tasksFilepath, "/tasks.json")
	if err := os.Mkdir(vscodeDir, 0755); err != nil {
		if !errors.Is(err, os.ErrExist) {
			panic(err)
		}
	}

	cmds := runShCmds(runshFilepath)
	var opts string
	for _, cmd := range cmds {
		task := fmt.Sprintf(`
		{
            "label": "r/%s",
            "type": "shell",
            "command": "bash -i run.sh %s",
            "isBackground": true,
        },`, cmd, cmd)
		opts += task
	}

	taskfile := start + opts + end

	err := os.WriteFile(tasksFilepath, []byte(taskfile), 0777)
	if err != nil {
		panic(err)
	}

	log.Println("tasks.json generated!")
}
