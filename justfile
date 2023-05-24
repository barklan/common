set shell := ["bash", "-uc"]
set dotenv-load

build target:
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GOGC=off go build \
    -ldflags='-w -s -extldflags "-static"' -a ./scripts/{{target}}
