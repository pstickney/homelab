#!/usr/bin/env bash

NAME="$1"
LOG_FILE="./homelab-k8s.log"

echo "${NAME}" | sudo tee /etc/hostname >> "${LOG_FILE}" 2>&1
sudo sed -i "2 s/.*/127.0.1.1 ${NAME}/" /etc/hosts >> "${LOG_FILE}" 2>&1
