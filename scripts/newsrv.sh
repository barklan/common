#!/bin/bash

# bash <(curl -s https://raw.githubusercontent.com/barklan/common/main/scripts/newsrv.sh)

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

function add_ubuntu_user_sudo {
    sudo adduser ubuntu
    mkdir -p /home/ubuntu/.ssh/
    touch /home/ubuntu/.ssh/authorized_keys

    sudo chown -R ubuntu:ubuntu /home/ubuntu
    sudo chmod 0700 /home/ubuntu/.ssh
    sudo chmod 0600 /home/ubuntu/.ssh/authorized_keys
}

function add_ubuntu_user_nosudo {
    adduser ubuntu
    mkdir -p /home/ubuntu/.ssh/
    touch /home/ubuntu/.ssh/authorized_keys

    chown -R ubuntu:ubuntu /home/ubuntu
    chmod 0700 /home/ubuntu/.ssh
    chmod 0600 /home/ubuntu/.ssh/authorized_keys
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

function install_extra_tools {
    if which pacman &>/dev/null; then
        echo "Arch Linux detected, using pacman"
        sudo pacman -Syu mcfly bottom choose sd fd xh strace ripgrep lua fzf neovim
    elif which apt &>/dev/null; then
        apt update && apt install -y curl git
        echo "Debian-based distibution detected, will install and use Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        brew tap cantino/mcfly
        brew install cantino/mcfly/mcfly
        brew install bottom choose-rust sd fd xh ripgrep lua fzf neovim
    else
        echo "Unknown distibution, skipping extra tools"
    fi

    cat << EOF >> ~/.bashrc
alias ..="cd .."
alias ...="cd ../.."

shopt -s histappend
shopt -s cmdhist

export HISTSIZE=20000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE="rm *:#*"

function j() {
    if [[ "$#" != 0 ]]; then
        builtin cd "$@";
        return
    fi
    while true; do
        local lsd=$(echo ".." && ls -p | grep '/$' | sed 's;/$;;')
        local dir="$(printf '%s\n' "${lsd[@]}" |
            fzf --reverse --preview '
                __cd_nxt="$(echo {})";
                __cd_path="$(echo $(pwd)/${__cd_nxt} | sed "s;//;/;")";
                echo $__cd_path;
                echo;
                ls -p --color=always "${__cd_path}";
        ')"
        [[ ${#dir} != 0 ]] || return 0
        builtin cd "$dir" &> /dev/null
    done
}

eval "$(mcfly init bash)"
EOF

}

yes_or_no "Add swap?" && add_swap

yes_or_no "Add ubuntu user? (sudo)" && add_ubuntu_user_sudo

yes_or_no "Add ubuntu user? (no sudo)" && add_ubuntu_user_nosudo

yes_or_no "Install Docker?" && install_docker

yes_or_no "Set hostname?" && set_hostname

yes_or_no "Init swarm?" && init_docker_swarm

yes_or_no "Set daily docker system prune timer?" && set_docker_system_prune_timer

yes_or_no "Install extra tools? " && install_extra_tools "$@"

echo "All done!"
