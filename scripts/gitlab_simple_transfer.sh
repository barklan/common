#! /usr/bin/env bash

# Exit in case of error
set -e

export ACCESS_KEY=${ACCESS_KEY?Variable not set}
export IP_ADDRESS=${IP_ADDRESS?Variable not set}
export LOCAL_DIR=${LOCAL_DIR?Variable not set}
export REMOTE_DIR_FULL=${REMOTE_DIR?Variable not set}

eval "$(ssh-agent -s)"
echo "$ACCESS_KEY" | tr -d '\r' | ssh-add -
scp -r "$LOCAL_DIR" "ubuntu@$IP_ADDRESS:$REMOTE_DIR_FULL"
