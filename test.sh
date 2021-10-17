#!/bin/bash

set -e

read -d '' runnerconfig << EOF || true
concurrent = 1
check_interval = 0

[session_server]
  session_timeout = 900

[[runners]]
  name = "changemename"
  url = "https://gitlab.com/"
  token = "changemetoken"
  executor = "docker"
  [runners.custom_build_dir]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
  [runners.docker]
    tls_verify = false
    image = "docker:stable"
    privileged = true
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/certs/client", "/cache"]
    shm_size = 0
EOF

echo "${runnerconfig}" > boom.toml
