#!/bin/bash

# bash <(curl -s https://raw.githubusercontent.com/barklan/common/main/cicd/install_docker.sh)

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
bash -c "sudo groupadd docker"
bash -c "sudo usermod -aG docker ${USER}"
newgrp docker

echo "Docker Installed!"
