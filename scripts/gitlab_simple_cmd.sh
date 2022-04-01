#! /usr/bin/env bash

# Exit in case of error
set -e

export ACCESS_KEY=${ACCESS_KEY?Variable not set}
export IP_ADDRESS=${IP_ADDRESS?Variable not set}
export CMD_TO_EXEC=${CMD_TO_EXEC?Variable not set}

eval "$(ssh-agent -s)"
echo "$ACCESS_KEY" | tr -d '\r' | ssh-add -
ssh -o "StrictHostKeyChecking=no" "ubuntu@$IP_ADDRESS" "${CMD_TO_EXEC}"
