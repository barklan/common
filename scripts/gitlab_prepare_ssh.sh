#! /usr/bin/env bash

# IP_ADDRESS=${IP_ADDRESS} ACCESS_KEY=${ACCESS_KEY} bash <(curl -s https://raw.githubusercontent.com/barklan/common/main/scripts/gitlab_prepare_ssh.sh)

set -e

export ACCESS_KEY=${ACCESS_KEY?Variable not set}
export IP_ADDRESS=${IP_ADDRESS?Variable not set}


eval "$(ssh-agent -s)"
echo "$ACCESS_KEY" | tr -d '\r' | ssh-add -
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "$IP_ADDRESS"
ssh-keyscan "$IP_ADDRESS" >> ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts
ssh-keyscan -H 'gitlab.com' >> ~/.ssh/known_hosts

touch stag_key
echo "$ACCESS_KEY" > stag_key
