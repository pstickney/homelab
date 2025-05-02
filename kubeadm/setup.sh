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

output "Installing preliminary packages"
sudo apt update -y >> "${LOG_FILE}" 2>&1
sudo apt install -y apt-transport-https ca-certificates software-properties-common lsb-release emacs tree git golang gcc make ebtables ethtool net-tools nfs-common curl wget gnupg openssh-server >> "${LOG_FILE}" 2>&1
result "$?"

output "Creating Keyring"
sudo mkdir -p /etc/apt/keyrings/ >> "${LOG_FILE}" 2>&1
result "$?"

# Add Docker Repo
output "Adding Docker GPG to Keyring"
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg >> "${LOG_FILE}" 2>&1
result "$?"
output "Creating Docker APT source"
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >> "${LOG_FILE}" 2>&1
result "$?"

# Add Kubernetes repo
output "Adding Kubernetes GPG to Keyring"
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg >> "${LOG_FILE}" 2>&1
result "$?"
output "Creating Kubernetes APT source"
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list >> "${LOG_FILE}" 2>&1
result "$?"

# Get requirements
output "Update Packages"
sudo apt update -y >> "${LOG_FILE}" 2>&1
result "$?"
output "Install Containerd and Kubernetes"
sudo apt install -y qemu-guest-agent containerd.io kubelet kubeadm kubectl >> "${LOG_FILE}" 2>&1
result "$?"

output "Create /etc/containerd/"
sudo mkdir -p /etc/containerd/ >> "${LOG_FILE}" 2>&1
result "$?"

output "Create default containerd config"
containerd config default | sudo tee /etc/containerd/config.toml >> "${LOG_FILE}" 2>&1
result "$?"

output "Update containerd cgroup"
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml >> "${LOG_FILE}" 2>&1
result "$?"

output "Download nerdctl"
wget -O /tmp/nerdctl.tar.gz https://github.com/containerd/nerdctl/releases/download/v2.0.3/nerdctl-2.0.3-linux-amd64.tar.gz >> "${LOG_FILE}" 2>&1
result "$?"
output "Extract nerdctl"
sudo tar xvzf /tmp/nerdctl.tar.gz -C /usr/local/bin/ >> "${LOG_FILE}" 2>&1
result "$?"

# Turn off swap
output "Disable Swap"
sudo swapoff -a >> "${LOG_FILE}" 2>&1
result "$?"
output "Remove Swap Mount"
sudo sed -i '/swap/d' /etc/fstab >> "${LOG_FILE}" 2>&1
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
sudo wget -O /etc/modules-load.d/k8s.conf https://raw.githubusercontent.com/pstickney/homelab/refs/heads/master/kubeadm/config/k8s-modules.conf >> "${LOG_FILE}" 2>&1
result "$?"

output "Disable IPv6 in sysctl"
sudo wget -O /etc/sysctl.d/90-disable-ipv6.conf https://raw.githubusercontent.com/pstickney/homelab/refs/heads/master/kubeadm/config/90-disable-ipv6.conf >> "${LOG_FILE}" 2>&1
result "$?"

output "Disable IPv6 in grub"
sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"ipv6.disable=1\"/" /etc/default/grub >> "${LOG_FILE}" 2>&1
result "$?"

output "Update grub"
sudo update-grub >> "${LOG_FILE}" 2>&1
result "$?"

output "Create rc.local"
sudo wget -O /etc/rc.local https://raw.githubusercontent.com/pstickney/homelab/refs/heads/master/kubeadm/config/rc.local >> "${LOG_FILE}" 2>&1
result "$?"

output "Apply Sysctl System Config"
sudo sysctl --system >> "${LOG_FILE}" 2>&1
result "$?"

output "Daemon Reload"
sudo systemctl daemon-reload >> "${LOG_FILE}" 2>&1
result "$?"

output "Enable containerd"
sudo systemctl enable containerd >> "${LOG_FILE}" 2>&1
result "$?"
output "Restart containerd"
sudo systemctl restart containerd >> "${LOG_FILE}" 2>&1
result "$?"

# Kubelet
output "Enable Kubelet"
sudo systemctl enable kubelet >> "${LOG_FILE}" 2>&1
result "$?"
output "Restart Kubelet"
sudo systemctl restart kubelet >> "${LOG_FILE}" 2>&1
result "$?"

output "Create docker -> nerdctl alias"
echo "alias docker='sudo nerdctl'" >> "$HOME/.bash_aliases"
result "$?"

# Done
echo ""
echo "You can now shutdown and clone this VM."
