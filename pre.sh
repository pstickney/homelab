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

set -e
# Get requirements
echo "Update Packages"
sudo yum update -y
echo "Install Dependencies"
sudo yum install -y epel-release qemu-guest-agent emacs tree git golang gcc gcc-c++ glibc-devel make ebtables ethtool net-tools curl wget gnupg openssh-server google-noto-emoji-color-fonts
echo ""
set +e

# Turn off swap
output "Disable Swap"
sudo swapoff -a > "${LOG_FILE}" 2>&1
result "$?"
output "Remove Swap Mount"
sudo sed -i '/swap/d' /etc/fstab
result "$?"

# Disable Firewall
output "Stop Firewall"
sudo systemctl stop firewalld >> "${LOG_FILE}" 2>&1
result "$?"
output "Disable Firewall"
sudo systemctl disable firewalld >> "${LOG_FILE}" 2>&1
result "$?"

# Disable SELinux
output "Disable SELinux"
sudo setenforce 0 >> "${LOG_FILE}" 2>&1
result "$?"
output "Set SELinux to Permissive"
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
result "$?"

# Configure Modules
output "Probe Overlay Module"
sudo modprobe overlay >> "${LOG_FILE}" 2>&1
result "$?"

output "Probe Netfilter Module"
sudo modprobe br_netfilter >> "${LOG_FILE}" 2>&1
result "$?"

output "Create k8s Modules Config"
sudo wget -O /etc/modules-load.d/k8s.conf https://raw.githubusercontent.com/pstickney/homelab/master/config/k8s-modules.conf
result "$?"

# Configure Sysctl
output "Create k8s Sysctl Bridge Config"
sudo wget -O /etc/sysctl.d/k8s.conf https://raw.githubusercontent.com/pstickney/homelab/master/config/k8s-sysctl.conf
result "$?"

output "Apply Sysctl System Config"
sudo sysctl --system >> "${LOG_FILE}" 2>&1
result "$?"

# Reboot system
echo ""
echo "Complete!"
echo "You can now reboot the system"
