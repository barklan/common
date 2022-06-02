#!/usr/bin/env bash

set -euo pipefail
set -x
IFS=$'\n\t'

uname -a
cat /etc/*-release
hostnamectl
w
free -h
df -h
echo "maximum number of processes: $(cat /proc/sys/kernel/pid_max); user limit: $(ulimit -u)"
printf "failed systemd services:\n %s" "$(systemctl --failed)"
journalctl -p 5 -b
echo "$PATH"
printf "CPU info:\n"
printf "Number of cores: %s" "$(nproc --all)"
lscpu

if which apt &>/dev/null; then
	echo "number of packages that can be upgraded:"
	apt list --upgradeable 2>/dev/null | wc -l
fi
