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
2. Give the VM a name of `kind-cluster1` with ID 200
3. Select the ISO image uploaded earlier as the OS
4. Enable the Qemu Agent
5. Set the disk size to 48GiB
6. Set the cores to 4
7. Set the memory to 32768MiB
8. Don't start after created

### Setup DHCP
1. In Proxmox, select the new `kind-cluster1` VM
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
4. Update dependencies and install QEMU agent
   ```shell
   sudo apt update -y
   sudo apt upgrade -y
   sudo apt install -y qemu-guest-agent
   ```
5. Restart VM

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
      podSubnet: "10.1.0.0/17"
      serviceSubnet: "10.1.128.0/17"
   
   Example: cluster5
      podSubnet: "10.5.0.0/17"
      serviceSubnet: "10.5.128.0/17"
   ```
3. Create kind cluster with:
   ```shell
   kind create cluster --name cluster1 --config kind-cluster.yaml
   ```

### Install CNI

> [!NOTE]
> WIP

[pfsense-download]: https://www.pfsense.org/download/
[proxmox-download]: https://www.proxmox.com/en/downloads/category/iso-images-pve
[ubuntu-download]: https://ubuntu.com/download/server
[kind-download]: https://kind.sigs.k8s.io/
[dotfiles]: https://github.com/pstickney/dotfiles
