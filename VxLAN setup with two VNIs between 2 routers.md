# VxLAN setup with two VNIs

## Description
This setup is an extension to the setup already made in this tutorial :https://github.com/MobComp/Group5/blob/main/setup-vxlan-between-two-router.md.
Now, two further client containers (c3 and c4) are going to be created. c3 is connected to router r1 and c4 is connected to router r2 (See diagram below).
A new VxLAN 1 with a VNI 20 is going to be created and c3 and c4 will be made part of this new VNI. The connections between c3 and c4 on either side of the tunnel
is the desired end result. On the other hand, VxLAN connection should not be possible between c1 and c4 , nor should it be possible between c2 and c3. This must be tested, because, by principle,
hosts that are part of different VxLAN should not be able to communicate with each other.   
  
Recap from Previous setup:  
In the router r1, DHCP is installed using dnsmasq (note: no DHCP in R2). All the containers connected to these routers (r1 and r2) will receive IP addresess and 
can communicate with eacth other. The containers connected to the r2 will also receive IP Address from r1 through the VXLAN tunnel between r1 and r2.  

![initial network topology](https://user-images.githubusercontent.com/95677915/151544704-b22756c4-ae6c-4e38-83b0-da2785484572.png)

## Prerequisite:
1. Follow the steps here - https://github.com/MobComp/Group5/blob/main/setup-vxlan-between-two-router.md
2. Run all commands with root privilege
```bash
$ sudo su
```

## Table of Contents
1. [Setup LXC, container and user](#1-setup-lxc-container-and-user)
2. [(Optional Step) Change the veth name of the container shown during `ifconfig -a`](#2-optional-step-change-the-veth-name-of-the-container-shown-during-ifconfig--a)
3. [Create two standalone bridges in the HOST (br7 and br8)](#3-create-two-standalone-bridges-in-the-host-br7-and-br8)
4. [Add eth2 interface to the router containers](#4-add-eth2-interface-to-the-router-containers)
5. [Setup Bridge and VXLAN on both routers](#5-setup-bridge-and-vxlan-on-both-router-container)
6. [Enslave the eth2 interface to the bridge in the routers](#6-enslave-the-eth2-interface-to-the-bridge-in-the-routers)
7. [Link containers to the Host bridge](#7-link-containers-to-the-host-bridge)

<hr/>

### 1. Setup LXC, container and user 

a. **Check currently running containers**  
View their IP addresses, status with 
```bash
$ lxc-ls --fancy
```

b. **Create 2 new LXC containers**  
> Note: Create two containers c3 and c4 (clients)
 A faster way by using the local cache would be with the following command :
  ```bash
  $ lxc-create -t download -n c3 -- --no-validate --dist ubuntu --release bionic --arch amd64
  $ lxc-create -t download -n c4 -- --no-validate --dist ubuntu --release bionic --arch amd64
  ```


c. **Start the containers and verify state**  
Start the containers with command : 
```bash
$ lxc-start -n c3
$ lxc-start -n c4
```
View the IP address (if any) and the current state with
```bash
$ lxc-ls --fancy
```  
d. **Create user for each created container**
> Note: Create users for all the containers. This is required to login to the container. (Make sure to start container before attaching users, otherwise possible error : Failed to get init pid)
```bash
$ lxc-attach -n c3
$ adduser username
$ usermod -aG sudo username
```

e. **To login to the container**
```bash
$ lxc-console -n r1
```
<hr/>

### 2. (Optional Step) Change the veth name of the container shown during `ifconfig -a`
We can assign custom name (usually the name of the container) to the veth to distinguish easily.
```bash
$ cd /var/lib/lxc/c3/
$ nano config
```

*Add the following line to the config file, save and exit*
lxc.net.0.veth.pair = c3

```bash
$ lxc-stop -n c3
$ lxc-start -n c3
```

Repeat all the steps in section 2, for c4 container also.
<hr/>

### 3. Create two standalone bridges in the HOST (br7 and br8)
Create two bridges (eg: br7 and br8) on the Host (Virtual Machine) which will connect to the router's (r1 & r2) eth2 respectively on one side and to c3 and c4 respectively on the other side (Refer network topology diagram on the top).  
```bash
$ brctl addbr br7
$ ifconfig br7 up
$ brctl addbr br8
$ ifconfig br8 up
```
<hr/>

### 4. Add eth2 interface to the router containers
For r1:
1. change directory to /var/lib/lxc
```bash
$ cd /var/lib/lxc
```
2. Edit the file r1/config
```bash
$ nano r1/config
```
3. Add the following to add the eth2 interface
```
lxc.net.2.type = veth
lxc.net.2.link = br7
lxc.net.2.flags= up
lxc.net.2.name = eth2
lxc.net.2.hwaddr = 00:16:3e:55:ba:cf
lxc.net.2.veth.pair = r1eth2
lxc.net.2.mtu = 1500
```
4. Save and exit

For r2
1. change directory to /var/lib/lxc
```bash
$ cd /var/lib/lxc
```
2. Edit the file r2/config
```bash
$ nano r2/config
```
3. Add the following to add the eth1 interface
```
lxc.net.2.type = veth
lxc.net.2.link = br8
lxc.net.2.flags= up
lxc.net.2.name = eth2
lxc.net.2.hwaddr = 00:16:3e:56:26:3f
lxc.net.2.veth.pair = r2eth2
lxc.net.2.mtu = 1500
```
4. Save and exit

<hr/>

### 5. Setup Bridge and VXLAN on both router container
1. Login to the r1 container
2. Add the new VXLAN 1 on r1
```bash
$ ip link add vxlan1 type vxlan id 20 remote 10.0.3.20 local 10.0.3.10 dev eth0
$ ip link set up dev vxlan1
```
3. Add the vxlan1 interface to the bridge superbr0 (previously created bridge)
```bash
$ brctl addif superbr0 vxlan1
```
4. Login to the r2 container
5. Add VXLAN1 on r2
```bash
$ ip link add vxlan1 type vxlan id 20 remote 10.0.3.10 local 10.0.3.20 dev eth0
$ ip link set up dev vxlan1
```
6. Add the vxlan1 interface to the bridge superbr0 (previously created bridge)
```bash
$ brctl addif superbr0 vxlan1
```
<hr/>

### 6. Enslave the eth2 interface to the bridge in the routers
Run the command inside both the routers.
```bash
brctl addif superbr0 eth2
```

<hr/>

### 7. Link containers to the Host bridge
According to the topology diagram above, c3 connects to r1 and c4 connects to r2
1. From the host, go to /etc/lib/lxc
```bash
$ cd /etc/lib/lxc
```
2. Open the c3 config file to edit
```bash
$ nano c3/config
```
3. Replace lxcbr0 with br7
`lxc.net.0.link = br7`
4. Save and exit
5. Open the c4 config file to edit
```bash
$ nano c4/config
```
6. Replace lxcbr0 with br8
`lxc.net.0.link = br8`
7. Save and exit
8. Start both the c3 and c4 container

<hr/>

## Extensions
With this setup, only VxLAN with unicast has been tested out. But in real world, this is not feasible, as there are more than 2 VTEPs. If we need to use unicast there, it would cause a lot of flooding and unreliability. Thus, we need some kind of discovery mechanism for routing like SSDP or OSPF. To enable this, we use the IP link command now with group option = 239.1.1.1 (for example).

## References  
https://www.youtube.com/c/TravisBonfigli/search?query=networking%20deep%20dive  
https://www.youtube.com/watch?v=a0dzCzpdUfw  

