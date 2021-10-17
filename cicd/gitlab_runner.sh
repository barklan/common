#!/bin/bash

# bash <(curl -s https://raw.githubusercontent.com/barklan/common/main/cicd/gitlab_runner.sh)

set -e

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo groupadd docker || true
sudo usermod -aG docker "${USER}" || true
newgrp docker || true

docker volume create gitlab-runner-config

docker run -d --name gitlab-runner --restart always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v gitlab-runner-config:/etc/gitlab-runner \
    gitlab/gitlab-runner:latest


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

sudo echo "${runnerconfig}" > /var/lib/docker/volumes/gitlab-runner-config/_data/config.toml

sudo sed -i "s/changemename/runner${RANDOM}/g" /var/lib/docker/volumes/gitlab-runner-config/_data/config.toml

echo "Enter token: "
read token
sudo sed -i "s/changemetoken/${token}/g" /var/lib/docker/volumes/gitlab-runner-config/_data/config.toml

docker restart gitlab-runner
