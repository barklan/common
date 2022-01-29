############################
# STEP 1 build executable binary
############################
ARG DOCKER_IMAGE_PREFIX=
FROM ${DOCKER_IMAGE_PREFIX}rust:1.58.1-alpine3.15 as builder

ARG BUILDKIT_INLINE_CACHE=1

# Install git + SSL ca certificates.
# Git is required for fetching the dependencies.
# Ca-certificates is required to call HTTPS endpoints.
RUN apk update && apk add --no-cache git ca-certificates tzdata && update-ca-certificates

# Create appuser
ENV USER=appuser
ENV UID=1000

# See https://stackoverflow.com/a/55757473/12429735
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    "${USER}"

WORKDIR /appuser

COPY . .

# Build the binary
RUN cargo build --release

############################
# STEP 2 build a small image
############################
FROM scratch

ENV DOCKERIZED=true

# Import from builder.
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# Copy our static executable
COPY --from=builder /go/bin/app /go/bin/app

# Use an unprivileged user.
USER appuser:appuser

# Run the app binary.
ENTRYPOINT ["/go/bin/app"]
