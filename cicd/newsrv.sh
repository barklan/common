#!/bin/bash

function yes_or_no {
    while true; do
        read -p "$* [y/n]: " yn
        case $yn in
            [Yy]*) return 0  ;;
            [Nn]*) echo "Aborted" ; return  1 ;;
        esac
    done
}

function install_docker {
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo groupadd docker
    sudo usermod -aG docker $USER
    newgrp docker
}

function add_swap {
    read -p "How much swap (in GB): " swapgb
    sudo fallocate -l "${swapgb}G" /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

    sudo bash -c "echo 'vm.swappiness = 10' >> /etc/sysctl.conf"
    sudo sysctl -p
}

function add_ubuntu_user {
    sudo adduser ubuntu
}

yes_or_no "Install Docker? [y/n]: " && install_docker

yes_or_no "Add swap? [y/n]: " && add_swap

yes_or_no "Add ubuntu user? [y/n]: " && add_ubuntu_user
