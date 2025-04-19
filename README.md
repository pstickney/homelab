# Kubernetes Home Lab

## Technologies
1. [pfSense][pfsense-download] - an open-source firewall and routing platform
2. [Proxmox VE][proxmox-download] - an open-source platform for enterprise virtualization
3. [Ubuntu Server][ubuntu-download] - a Linux distribution based on Debian and composed mostly of free and open-source software
4. [kind][kind-download] - a tool for running local Kubernetes clusters using Docker

## Prerequisites
1. Download Ubuntu Server ISO
2. Upload the ISO to Proxmox storage

## Create VM

### Provision Resources
1. In Proxmox, create a VM
2. Give the VM a name of `kind-cluster0` with ID 200
3. Select the ISO image uploaded earlier as the OS
4. Enable the Qemu Agent
5. Set the disk size to 512GiB
6. Set the cores to 4
7. Set the memory to 32768MiB
8. Don't start after created

### Setup DHCP
1. In Proxmox, select the new `kind-cluster0` VM
2. Select `Hardware`
3. Copy the Network Device MAC address
4. In pfSense, select `Services -> DHCP Server`
5. At the bottom, click `Add` to add a DHCP Static Mapping
6. Enter the MAC Address, IP Address, Hostname, and enable ARP table entry
7. Click save and apply
8. Go to `Services -> DNS Resolver`
9. Apply changes

### Install Ubuntu on VM 
1. Start the VM
2. Select `Install Ubuntu`
3. Follow install process
4. Update apt repo and install dependencies
   ```shell
   sudo apt update -y
   sudo apt upgrade -y
   sudo apt install -y ca-certificates gcc curl gnupg qemu-guest-agent docker.io
   ```
5. Add your user to docker group
   ```shell
   sudo usermod -aG docker $USER
   ```
6. Restart VM


## Create Cluster

### Dependencies
1. Follow setup instructions for the [dotfiles][dotfiles] repo.

### Create using `kind`
1. Copy the [kind-cluster.yaml](./kind-cluster.yaml) to your VM
   ```shell
   cd ~
   wget https://raw.githubusercontent.com/pstickney/homelab/refs/heads/kind/kind-cluster.yaml
   ```
2. Update the file such that the subnets are the same as the ID of the cluster name.
   ```shell
   Example: cluster1
      apiServerAddress: 192.168.1.201
      podSubnet: "10.1.0.0/17"
      serviceSubnet: "10.1.128.0/17"
   
   Example: cluster5
      apiServerAddress: 192.168.1.205
      podSubnet: "10.5.0.0/17"
      serviceSubnet: "10.5.128.0/17"
   ```
3. Create kind cluster with:
   ```shell
   kind create cluster --name cluster<num> --config kind-cluster.yaml
   ```

### Setup Networking

1. Checkout the [charts][charts] repo 
2. Install Cilium
   ```shell
   helm upgrade --install --create-namespace -n cilium lab cilium
   ```

2. Update CoreDNS
   ```shell
   kubectl apply -f cilium-config/coredns.yaml
   ```

## Configure 

1. Install ArgoCD
   ```shell
   helm upgrade --install --create-namespace -n argocd lab argo-cd
   ```
2. Install app-of-apps from argo-registry
   ```shell
   kubectl apply -f app-of-apps.yaml
   ```

[pfsense-download]: https://www.pfsense.org/download/
[proxmox-download]: https://www.proxmox.com/en/downloads/category/iso-images-pve
[ubuntu-download]: https://ubuntu.com/download/server
[kind-download]: https://kind.sigs.k8s.io/
[dotfiles]: https://github.com/pstickney/dotfiles
[charts]: https://github.com/pstickney/charts
