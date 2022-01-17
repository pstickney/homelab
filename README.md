# Kubernetes Home Lab

## Technologies
1. [pfSense][pfsense-download] - an open-source powerful, flexible firewalling and routing platform
2. [Proxmox VE][proxmox-download] - an open-source platform for enterprise virtualization
3. [CentOS 7][centos-download] - a community-driven Linux distribution derived from RHEL

## Prerequisites
1. Upload the CentOS 7 ISO to Proxmox storage

    <img src="images/iso_upload.png" />

## Setup Kubernetes Template VM
1. In Proxmox, create a VM
2. Give the new VM a name of `k8s-template`
3. Select the CentOS 7 image uploaded earlier as the OS
4. Enable the Qemu Agent
5. Set the Disk size to 120GiB
6. Set the Cores to 4
7. Set the Memory to 8192MiB
8. Don't start after created

## Setup DHCP
1. In Proxmox, select the new k8s-template VM
2. Select `Hardware`
3. Copy the Network Device MAC address

   <img src="images/template_mac.png" width="500" />
   
4. In pfSense, select `Services -> DHCP Server`
5. At the bottom, click `Add` to add a DHCP Static Mapping
6. Enter the MAC Address, IP Address, and Hostname

   <img src="images/template_dhcp.png" width="500">

## Install CentOS 7 on VM 
1. Start the VM
2. Select `Install CentOS 7`

   <img src="images/install_centos_7.png" width="500" />

3. Update `Software Selection` to a Compute Node and add additional Add-Ons

   <img src="images/install_centos_7_software_selection.png" width="500" />

4. Update `Network & Host Name` to turn on the Ethernet connection
   
   We can confirm that the IP Address is the same as the IP Address we setup in pfSense  

   <img src="images/install_centos_7_network.png" width="500" />

5. Begin Installation
6. Set `Root Password` and create your user
7. Reboot once installation has completed

## Setup Kubernetes Requirements
1. Login to the VM and run this script

   ```shell
   curl -s https://raw.githubusercontent.com/pstickney/homelab/master/setup.sh | bash
   ```

[pfsense-download]: https://www.pfsense.org/download/
[proxmox-download]: https://www.proxmox.com/en/downloads/category/iso-images-pve
[centos-download]: https://www.centos.org/download/