#!/bin/bash

# bash <(curl -s https://raw.githubusercontent.com/barklan/common/main/cicd/install_docker.sh)

set -e

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo groupadd docker || true
sudo usermod -aG docker "${USER}"
newgrp docker

echo "Docker Installed!"
