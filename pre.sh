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
    printf '\U2714\UFE0F\n'
  else
    printf '\U274C\UFE0F\n'
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

## Get requirements
output "Update Packages"
sudo yum update -y > "${LOG_FILE}" 2>&1
result "$?"
output "Install Dependencies"
sudo yum install -y epel-release qemu-guest-agent emacs tree git golang gcc gcc-c++ glibc-devel make ebtables ethtool net-tools curl wget gnupg openssh-server >> "${LOG_FILE}" 2>&1
result "$?"
echo ""

# Turn off swap
output "Disable Swap"
sudo swapoff -a >> "${LOG_FILE}" 2>&1
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

## Configure sysctl
output "Create k8s Modules Config"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
result "$?"

output "Probe Overlay Module"
sudo modprobe overlay >> "${LOG_FILE}" 2>&1
result "$?"

output "Probe Netfilter Module"
sudo modprobe br_netfilter >> "${LOG_FILE}" 2>&1
result "$?"

output "Create k8s Sysctl Bridge Config"
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-arptables = 1
net.ipv4.ip_forward = 1
EOF
result "$?"

output "Apply Sysctl System Config"
sudo sysctl --system >> "${LOG_FILE}" 2>&1
result "$?"

## Reboot system
echo ""
echo "Reboot the system"
echo "Press any key to reboot..."
read temp
#sudo shutdown -r now
