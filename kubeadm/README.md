# Kubernetes Home Lab

## Technologies
1. [pfSense][pfsense-download] - an open-source firewall and routing platform
2. [Proxmox VE][proxmox-download] - an open-source platform for enterprise virtualization
3. [Ubuntu Server][ubuntu-download] - a Linux distribution based on Debian and composed mostly of free and open-source software

## Overview

For this lab, I'm using Proxmox as a hypervisor to create VMs.
Here is a breakdown of the VMs.

|       Machine       |  Type  |  CPU   | RAM | Storage |  IP Address   |
|:-------------------:|:------:|:-------------:|:---:|:-------:|:-------------:|
| k8s-control-plane-1 | Master |   4    | 12  |   48    | 192.168.1.200 |
|    k8s-compute-1    | Worker |   4    | 12  |   48    | 192.168.1.205 |
|    k8s-compute-2    | Worker |   4    | 12  |   48    | 192.168.1.206 |

## Prerequisites
1. Upload the ISO to Proxmox storage

## Create Base Template VM

### Provision Resources
1. In Proxmox, create a VM
2. Give the VM a new of `base-vm-template` with ID 199
3. Select the ISO image uploaded earlier as the OS
4. Enable the Qemu Agent
5. Set the disk size to 48GiB
6. Set the cores to 4
7. Set the memory to 12288MiB
8. Don't start after created

### Setup DHCP
1. In Proxmox, select the new `base-vm-template` VM
2. Select `Hardware`
3. Copy the Network Device MAC address
4. In pfSense, select `Services -> DHCP Server`
5. At the bottom, click `Add` to add a DHCP Static Mapping
6. Enter the MAC Address, IP Address, Hostname, and enable ARP table entry
7. Click save and apply

### Install Ubuntu on VM 
1. Start the VM
2. Select `Install Ubuntu`
3. Follow install process
4. Update dependencies and install QEMU agent
   ```shell
   sudo apt update -y
   sudo apt upgrade -y
   sudo apt install -y qemu-guest-agent
   ```
5. Shutdown VM

## Create Kubernetes Template VM

1. Clone `base-vm-template` and name it `k8s-template` with ID 219
2. Follow the same [Setup DHCP](#setup-dhcp) steps for the `k8s-template` VM
3. Run host rename
   ```shell
   curl -s https://raw.githubusercontent.com/pstickney/homelab/master/rename-host.sh | bash -s HOST
   ```
4. Reboot the VM
   ```shell
   sudo reboot
   ```
5. Install Docker and Kubernetes with this script
   ```shell
   curl -s https://raw.githubusercontent.com/pstickney/homelab/master/setup.sh | bash
   ```

## Create Kubernetes Control Plane
1. Clone the `k8s-template` and name it `k8s-master-1` with ID 200
2. Follow the same [Setup DHCP](#setup-dhcp) steps for the `k8s-master-1` VM
3. Run host rename
   ```shell
   curl -s https://raw.githubusercontent.com/pstickney/homelab/master/rename-host.sh | bash -s HOST
   ```
4. Reboot the VM
   ```shell
   sudo reboot
   ```
5. Pull the latest kubeadm images
   ```shell
   sudo kubeadm config images pull
   ```
6. Initialize control plane
   ```shell
   sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --service-cidr=10.246.0.0/16 \
          --control-plane-endpoint=192.168.1.200 --apiserver-advertise-address=192.168.1.200
   ```
7. Copy kubeconfig file
   ```shell
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown -R $(id -u):$(id -g) $HOME/.kube
   ```
8. Install the Flannel CNI or Calico CNI
   ```shell
   kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml
   ```
   ```shell
   kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/master/manifests/calico.yaml
   ```

## Create Kubernetes Worker Nodes
1. Clone the `k8s-template` and name it `k8s-worker-1` with ID 205
2. Follow the same [Setup DHCP](#setup-dhcp) steps for the `k8s-worker-1` VM
3. Run host rename
   ```shell
   curl -s https://raw.githubusercontent.com/pstickney/homelab/master/rename-host.sh | bash -s HOST
   ```
4. Reboot the VM
   ```shell
   sudo reboot
   ```
5. Join the worker node to the cluster
   ```shell
   sudo kubeadm join 192.168.1.200:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
   ```
6. Repeat for any more worker nodes

[pfsense-download]: https://www.pfsense.org/download/
[proxmox-download]: https://www.proxmox.com/en/downloads/category/iso-images-pve
[ubuntu-download]: https://ubuntu.com/download/server
