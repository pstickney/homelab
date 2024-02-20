#!/usr/bin/env bash

NAME="$1"

echo "${NAME}" | sudo tee /etc/hostname
sudo sed -i "2 s/.*/127.0.1.1 ${NAME}/" /etc/hosts
