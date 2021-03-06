#!/bin/bash

# bash <(curl -s https://raw.githubusercontent.com/barklan/common/main/sys/install_docker.sh)

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
