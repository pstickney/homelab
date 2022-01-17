#!/usr/bin/env bash

set +x

LOG_FILE="./homelab-k8s.log"

output() {
  LINE='--------------------------------------------------------'
  OUTPUT="$1"
  printf "%s %s " "${OUTPUT}" "${LINE:${#OUTPUT}}"
}
result() {
  if [ "$1" -eq "0" ]; then
    printf '[OK] \U2714\UFE0F\n'
  else
    printf '[Error] \U274C\UFE0F\n'
    echo ""
    echo "An error has occurred."
    echo "Review the log at ${LOG_FILE}"
    exit 1
  fi
}

# Login to sudo
echo "Enter password for sudo access: "
sudo -v
echo ""

# Get Repos
output "Add K8s Yum Repo"
sudo yum-config-manager --add-repo https://raw.githubusercontent.com/pstickney/homelab/master/repos/kubernetes.repo > "${LOG_FILE}" 2>&1
result "$?"

output "Add Docker Yum Repo"
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo >> "${LOG_FILE}" 2>&1
result "$?"

# Get requirements
set -e
echo ""
echo "Update Packages"
sudo yum update -y
echo "Install Dependencies"
sudo yum install -y docker-ce docker-ce-cli containerd.io kubelet kubeadm kubectl
echo ""
set +e

# Switch Docker cgroup driver to systemd
output "Create /etc/docker/"
sudo mkdir -p /etc/docker/ >> "${LOG_FILE}" 2>&1
result "$?"
output "Update Docker cgroup driver to systemd"
sudo wget -O /etc/docker/daemon.json https://raw.githubusercontent.com/pstickney/homelab/master/config/docker-daemon.json >> "${LOG_FILE}" 2>&1
result "$?"

# Daemon Reload
output "Daemon Reload"
sudo systemctl daemon-reload >> "${LOG_FILE}" 2>&1
result "$?"

# Docker
output "Enable Docker"
sudo systemctl enable docker >> "${LOG_FILE}" 2>&1
result "$?"
output "Restart Docker"
sudo systemctl restart docker >> "${LOG_FILE}" 2>&1
result "$?"

# Kubelet
output "Enable Kubelet"
sudo systemctl enable kubelet >> "${LOG_FILE}" 2>&1
result "$?"
output "Restart Kubelet"
sudo systemctl restart kubelet >> "${LOG_FILE}" 2>&1
result "$?"
