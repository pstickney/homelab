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

output "Initializing log file"
echo "" > "${LOG_FILE}" 2>&1
result "$?"

output "Creating keyring"
sudo mkdir -p /etc/apt/keyrings/ >> "${LOG_FILE}" 2>&1
result "$?"

output "Installing preliminary packages"
sudo apt update -y >> "${LOG_FILE}" 2>&1
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common >> "${LOG_FILE}" 2>&1
result "$?"

# Add Docker Repo
output "Getting Docker GPG key"
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
result "$?"
output "Creating Docker APT source"
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list >> "${LOG_FILE}" 2>&1
result "$?"

# Add Kubernetes repo
output "Getting Kubernetes GPG key"
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg >> "${LOG_FILE}" 2>&1
result "$?"
output "Creating Kubernetes APT source"
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/kubernetes.gpg] \
      http://apt.kubernetes.io/ kubernetes-xenial main" | \
      sudo tee /etc/apt/sources.list.d/kubernetes.list >> "${LOG_FILE}" 2>&1
result "$?"

# Get requirements
output "Update Packages"
sudo apt update -y >> "${LOG_FILE}" 2>&1
result "$?"
output "Install Dependencies"
sudo apt install -y qemu-guest-agent emacs tree git golang gcc make ebtables ethtool net-tools nfs-common curl wget gnupg openssh-server docker-ce docker-ce-cli containerd.io kubelet kubeadm kubectl >> "${LOG_FILE}" 2>&1
result "$?"

# Turn off swap
output "Disable Swap"
sudo swapoff -a >> "${LOG_FILE}" 2>&1
result "$?"
output "Remove Swap Mount"
sudo sed -i '/swap/d' /etc/fstab
result "$?"

# Disable Firewall
output "Stop Firewall"
sudo systemctl stop ufw >> "${LOG_FILE}" 2>&1
result "$?"
output "Disable Firewall"
sudo systemctl disable ufw >> "${LOG_FILE}" 2>&1
result "$?"

# Disable SELinux
output "Disable SELinux"
echo 'SELINUX=disabled' | sudo tee /etc/selinux/config >> "${LOG_FILE}" 2>&1
result "$?"

# Configure Modules
output "Probe Overlay Module"
sudo modprobe overlay >> "${LOG_FILE}" 2>&1
result "$?"

output "Probe Netfilter Module"
sudo modprobe br_netfilter >> "${LOG_FILE}" 2>&1
result "$?"

output "Create k8s Modules Config"
sudo wget -O /etc/modules-load.d/k8s.conf https://raw.githubusercontent.com/pstickney/homelab/master/config/k8s-modules.conf >> "${LOG_FILE}" 2>&1
result "$?"

output "Disable IPv6"
sudo wget -O /etc/sysctl.d/90-disable-ipv6.conf https://raw.githubusercontent.com/pstickney/homelab/master/config/k8s-sysctl.conf >> "${LOG_FILE}" 2>&1
result "$?"

output "Reload sysctl config"
sudo sysctl -p
result "$?"

output "Restart procps"
sudo systemctl restart procps
result "$?"

output "Create rc.local"
sudo wget -O /etc/rc.local https://raw.githubusercontent.com/pstickney/homelab/master/config/rc.local >> "${LOG_FILE}" 2>&1
result "$?"

output "Apply Sysctl System Config"
sudo sysctl --system >> "${LOG_FILE}" 2>&1
result "$?"

# Switch Docker cgroup driver to systemd
output "Create /etc/docker/"
sudo mkdir -p /etc/docker/ >> "${LOG_FILE}" 2>&1
result "$?"

output "Update Docker cgroup driver to systemd"
sudo wget -O /etc/docker/daemon.json https://raw.githubusercontent.com/pstickney/homelab/master/config/docker-daemon.json >> "${LOG_FILE}" 2>&1
result "$?"

# Delete containerd config
output "Delete containerd config"
sudo rm -f /etc/containerd/config.toml >> "${LOG_FILE}" 2>&1
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

# Setting permissions
output "Add user to docker group"
sudo usermod -aG docker ${USER}
result "$?"

# Done
echo ""
echo "You can now shutdown and clone this VM."
