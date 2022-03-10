#!/bin/bash

# bash <(curl -s https://raw.githubusercontent.com/barklan/common/main/sys/newsrv.sh)

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

    # sudo bash -c "echo 'vm.swappiness = 60' >> /etc/sysctl.conf"
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
    docker network create --driver=overlay --attachable traefik-public

    # This is needed for elasticsearch
    sudo sysctl -w vm.max_map_count=262144
    sudo bash -c "echo 'vm.max_map_count=262144' >> /etc/sysctl.conf"
}

function set_docker_system_prune_timer {
    cd /etc/systemd/system
    sudo curl -O https://raw.githubusercontent.com/barklan/common/main/sys/timers/docker-system-prune.service
    sudo curl -O https://raw.githubusercontent.com/barklan/common/main/sys/timers/docker-system-prune.timer
    sudo systemctl enable --now docker-system-prune.timer
}

yes_or_no "Add swap?" && add_swap

yes_or_no "Add ubuntu user?" && add_ubuntu_user

yes_or_no "Install Docker?" && install_docker

yes_or_no "Set hostname?" && set_hostname

yes_or_no "Init swarm?" && init_docker_swarm

yes_or_no "Set daily docker system prune timer?" && set_docker_system_prune_timer

echo "All done!"
