package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

func main() {
	var workspaceDir, dstRegistry, ignorePrefix string
	flag.StringVar(&workspaceDir, "dir", "", "Workspace directory")
	flag.StringVar(&dstRegistry, "dst", "", "Destination registry")
	flag.StringVar(&ignorePrefix, "ignore", "", "Ignore prefix")
	flag.Parse()
	if workspaceDir == "" || dstRegistry == "" {
		panic("empty workspace or destination string")
	}

	if string(dstRegistry[len(dstRegistry)-1]) == "/" {
		dstRegistry = dstRegistry[:len(dstRegistry)-1]
	}

	log.Println("will be pushed to registry: ", dstRegistry)
	time.Sleep(2 * time.Second)

	// images := make([]string, 0)
	reg, err := regexp.Compile(`(\.yml$)|(\.yaml$)|(\.dockerfile$)|(^Dockerfile$)`)
	fatalOnErr("", err)
	files := filesOfInterest(workspaceDir, reg)

	reg, err = regexp.Compile(`\${(DOCKER_IMAGE_PREFIX|CI_REGISTRY_IMAGE).*}([^\s'"]+)('?)`)
	fatalOnErr("", err)
	allImages := make([]string, 0)
	for _, file := range files {
		images, ok := findImagesInFile(file, reg, ignorePrefix)
		if !ok {
			continue
		}
		allImages = append(allImages, images...)
	}

	log.Println(allImages)
	time.Sleep(2 * time.Second)

	for _, image := range allImages {
		pushAndPull(image, dstRegistry)
	}
	log.Println("All done!")
}

func findImagesInFile(file string, reg *regexp.Regexp, ignorePrefix string) ([]string, bool) {
	contents, err := ioutil.ReadFile(file)
	fatalOnErr("", err)
	matches := reg.FindAllStringSubmatch(string(contents), -1)
	if len(matches) == 0 {
		return nil, false
	}

	images := make([]string, 0)
	for _, match := range matches {
		image := match[2]
		if image[0] == '/' {
			image = image[1:]
		}
		if !strings.HasPrefix(image, ignorePrefix) {
			images = append(images, image)
		}
	}
	return images, true
}

func pushAndPull(image string, dstRegistry string) {
	log.Println("pullling image: ", image)
	pull := fmt.Sprintf("docker pull %s", image)
	if out, err := exec.Command("bash", "-c", pull).Output(); err != nil {
		fatalOnErr(string(out), err)
	}
	log.Println("pulled image: ", image)

	target := fmt.Sprintf("%s/%s", dstRegistry, image)
	retag := fmt.Sprintf("docker tag %s %s", image, target)
	if out, err := exec.Command("bash", "-c", retag).Output(); err != nil {
		fatalOnErr(string(out), err)
	}
	push := fmt.Sprintf("docker push %s", target)
	if out, err := exec.Command("bash", "-c", push).Output(); err != nil {
		fatalOnErr(string(out), err)
	}
	log.Println("pushed image: ", target)
}

func filesOfInterest(path string, reg *regexp.Regexp) []string {
	files := make([]string, 0)
	filepath.Walk(path, func(path string, info os.FileInfo, err error) error {
		fatalOnErr("", err)
		filename := info.Name()

		if strings.Contains(path, "node_modules") {
			return nil
		}

		if reg.Match([]byte(filename)) {
			files = append(files, path)
		}
		return nil
	})
	return files
}

func fatalOnErr(msg string, err error) {
	if err != nil {
		log.Fatalln(msg, err)
	}
}
