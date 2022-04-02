#! /usr/bin/env bash

set -ex

export ACCESS_KEY=${ACCESS_KEY?Variable not set}
export IP_ADDRESS=${IP_ADDRESS?Variable not set}
export LOCAL_DIR=${LOCAL_DIR?Variable not set}
export REMOTE_DIR=${REMOTE_DIR?Variable not set}

eval "$(ssh-agent -s)"
echo "$ACCESS_KEY" | tr -d '\r' | ssh-add -
rsync -a --delete "$LOCAL_DIR" "ubuntu@$IP_ADDRESS:$REMOTE_DIR"
