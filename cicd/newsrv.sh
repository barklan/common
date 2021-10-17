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
    sudo usermod -aG docker ubuntu
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
    mkdir -p /home/ubuntu/.ssh/
    touch /home/ubuntu/.ssh/authorized_keys

    sudo chown -R ubuntu:ubuntu /home/ubuntu
    sudo chmod 0700 /home/ubuntu/.ssh
    sudo chmod 0600 /home/ubuntu/.ssh/authorized_keys
}

function set_hostname {
    read -p "IP address?" ipaddress
    read -p "Hostname?" newhostname
    echo "${ipaddress} ${newhostname}" | sudo tee -a /etc/hosts
    sudo hostnamectl set-hostname "${newhostname}"
    sudo systemctl restart docker
}

function init_docker_swarm {
    docker swarm init
    docker network create --driver=overlay traefik-public

    # This is needed for elasticsearch
    sudo sysctl -w vm.max_map_count=262144
    sudo bash -c "echo 'vm.max_map_count=262144' >> /etc/sysctl.conf"
}

yes_or_no "Add swap?" && add_swap

yes_or_no "Add ubuntu user?" && add_ubuntu_user

yes_or_no "Install Docker?" && install_docker

yes_or_no "Set hostname?" && set_hostname

yes_or_no "Init swarm?" &&

echo "You should now copy public ssh key from client and call this script to install docker."
# cat ~/.ssh/personal.pub | ssh test 'cat > /root/.ssh/authorized_keys && echo "Key copied"'
