# Build VXLAN network between two host (two system in different network)

## Description
The basic idea is that we have two networks. This is realized by two virtual machines (eg: running on virtual box) with Ubuntu 18.04.6. The first virtual machine is HOST A and the second virtual machine is the HOST B. We install LXC and add two containers on each HOST running Ubuntu. Then, we create a VXLAN interface and Bridge and then add the VXLAN interface we created to the bridge (on both the HOSTs). Now, with the bridges on both, the Hosts are connected to each other via the VXLAN tunnel. Finally, we setup the DHCP server on Host A, and through the VXLAN tunnel all the 4 containers (2 from HOST A and 2 from HOST B) are connected to each other in the same subnet even though they are in different physical network.

## Prerequisite:
1. Download virtual box or vmware
2. Download Ubuntu 18.04.6 image
- https://releases.ubuntu.com/18.04.6/ubuntu-18.04.6-desktop-amd64.iso
3. Make sure both virtual machine's network is running the network adapter on bridge mode so that two virtual machines can ping each other.
- https://linuxhint.com/use-virtualbox-bridged-adapter/
4. Clone the virtual machine 
- Once a virutal machine is setuped and ubuntu is properly installed then we can just clone it to create another virtual machine without having to install ubuntu on the second VM all over again.
- https://www.lifewire.com/create-virtual-machines-clones-and-snapshots-in-virtualbox-4177998

Note: Run all the commands (including LXC's command) with sudo

```bash
$ sudo su
```

## Table of Contents
1. [Setup LXC, container and user](#1-setup-lxc-container-and-user)
2. [(Optional Step) Change the veth name of the container shown during `ifconfig -a`](#2-optional-step-change-the-veth-name-of-the-container-shown-during-ifconfig--a)
3. [Setup Bridge and VXLAN on the HOSTs](#3-setup-bridge-and-vxlan-on-the-hosts-not-the-containers)
4. [Link the containers virtual eth to the new bridge on the HOST](#4-link-the-containers-virtual-eth-to-the-new-bridge-on-the-host)
5. [Setup dnsmasq for dhcp on HOST A at the bridge interface](#5-setup-dnsmasq-for-dhcp-on-host-a-at-the-bridge-interface)

&nbsp;

### 1. Setup LXC, container and user 
1. **Install LXC on the host (Run this command on both the HOSTs -- i.e the two containers)**
```bash
$ add-apt-repository ppa:ubuntu-lxc/lxc-stable
$ apt-get update
$ apt-get install lxc
```

2. **Check if lxc is setup correctly**
```bash
$ lxc-checkconfig
```

3. **Check your lxc version**
```bash
$ lxc-ls —version
```

4. **Create a new LXC continer**
```bash
$ lxc-create -t download -n container1
```
- If there is problem with the keyserver then you can pass  `--no-validate` to bypass the validation check
  ```bash
  $ lxc-create -t download -n container1 -- --no-validate
  ```
- In the experiment we are using, Ubuntu distribution, bionic release and amd64 architecture

> Note: create 2 containers on Host A and two containers on Host B

5. **View the created containers and their current state**
```bash
$ lxc-ls --fancy
```

6. **Create user for each created container**
```bash
$ lxc-attach -n container1
$ adduser username
$ usermod -aG sudo username
```

6. **To login to the container**
```bash
$ lxc-console -n container1
```

7. **To exit from the container console**
```bash
$ exit
```
```
Press `Ctrl+a` and `q`
```

### 2. (Optional Step) Change the veth name of the container shown during `ifconfig -a`
In the HOST, when we have many containers, if we do `ifconfig -a` its hard to know which veth belongs to which container. We can assign custom name (usually the name of the container) to the veth.
```bash
$ cd /var/lib/lxc/container1/
$ nano config

# Add the following line to the config file, save and exit
lxc.net.0.veth.pair = container1

$ lxc-stop -n container1
$ lxc-start -n container1

$ ifconfig -a
# Now you will see the veth adapter name is changed to container1
```
Do the same for all the container in both HOSTs
<hr/>

### 3. Setup Bridge and VXLAN on the HOSTs (Not the containers)

1. Add VXLAN
```bash
$ ip link add vxlan0 type vxlan id 10 remote 2.2.2.2 local 1.1.1.1 dev eth0
$ ip link set up dev vxlan0
```
Run the command for both the HOSTs. If the command is run on Host A the, 1.1.1.1 should be replaced by the ip of HOST A (virtual machine) at interface eth0 and 2.2.2.2 should be replaced by the ip of HOST B at interface eth0. The vxlan id 10 can be anynumber but it should be the same on both HOSTs

2. Create a bridge and add the vxlan0 interface to it.
```bash
$ brctl addbr superbr0
$ ip link set up superbr0
$ brctl addif superbr0 vxlan0
```
Run the command for both the HOSTs

<hr/>

### 4. Link the container's virtual eth to the new bridge on the HOST
```bash
$ cd /etc/lib/lxc/container1
$ nano config

# Append the following network configuration for eth0
$ lxc.net.0.link = superbr0
$ lxc.net.0.name = eth0
$ lxc.net.0.mtu = 1500
```
Do this for all the containers in both the HOSTs

<hr/>

### 5. Setup dnsmasq for dhcp on HOST A at the bridge interface
 - In Host A
```bash
$ apt-get install dnsmasq
$ vi /etc/dnsmasq.conf

# Modify the file with these values, save and exit
interface=superbr0
listen-address=192.168.1.1
bind-interfaces
dhcp-range=192.168.1.2,192.168.1.254,12h
```
- Add and IP to the superbr0 interface on Host A
```bash
ip addr add 192.168.1.1/24 dev superbr0
```
- Restart the dnsmasq to apply the changes
```bash
service dnsmasq restart
```

## Miscellaneous 

### 1. Change the dhcp range for the lxc containers
```bash 
$ vi /etc/default/lxc-net

# Change LXC_DHCP_RANGE, LXC_NETWORK, etc and then save and exit

$ service lxc-net restart
```

### 2. Give static IP to the container
```bash 
$ vi /etc/default/lxc-net
Uncomment “#LXC_DHCP_CONFILE=/etc/lxc/dnsmasq.conf“, then save and exit

$ vi /etc/lxc/dnsmasq.conf
# Add the following static ip to the file, then save and exit
dhcp-host=container1, 10.0.3.55

$ service lxc-net restart
```

## Troubleshoot
- dnsmasq: failed to create listening socket for port 53: Address already in use
   - https://askubuntu.com/questions/191226/dnsmasq-failed-to-create-listening-socket-for-port-53-address-already-in-use 
   - https://stanislas.blog/2018/02/setup-network-bridge-lxc-net/    
- ifconfig not found
   - apt-get install net-tools
- bctrl command not found
   - apt-get install bridge-utils 
