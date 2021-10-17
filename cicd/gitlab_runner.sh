#!/bin/bash

set -e

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo groupadd docker
sudo usermod -aG docker "${USER}"
newgrp docker


docker volume create gitlab-runner-config

docker run -d --name gitlab-runner --restart always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v gitlab-runner-config:/etc/gitlab-runner \
    gitlab/gitlab-runner:latest

docker run --rm -it -v gitlab-runner-config:/etc/gitlab-runner gitlab/gitlab-runner:latest register

sed -i "s/changemename/runner${RANDOM}/g" /var/lib/docker/volumes/gitlab-runner-config/_data/config.toml

echo "Enter token: "
read token
sed -i "s/changemetoken/${token}/g" /var/lib/docker/volumes/gitlab-runner-config/_data/config.toml

docker restart gitlab-runner
