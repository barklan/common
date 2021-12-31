############################
# STEP 1 build executable binary
############################
FROM golang:1.17.3-buster AS build

ARG BUILDKIT_INLINE_CACHE=1

WORKDIR /app

COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY *.go ./

RUN go build -o /changeme

############################
# STEP 2 build a small image
############################
FROM gcr.io/distroless/base-debian10

WORKDIR /

COPY --from=build /changeme /changeme

EXPOSE 8080

USER nonroot:nonroot

ENTRYPOINT ["/changeme"]
