# Setup VXLAN between two routers (in a single Virtual Machine running Ubuntu 18.04.6)

## Description
In a Virtual machine running Ubuntu 18.04.6, two LXC containers (Routers) are created (r1 and r2). Both routers has two interfaces (eth0 and eth1). "eth0" is connected to the internet whereas "eth1" allows other containers to connected to these routers. At the interface "eth0" of both routers, a bridge and VXLAN (with same VLAN id) is created. Also, in the r1, DHCP is installed using dnsmasq (note: no DHCP in R2). All the containers connected to these routers (r1 and r2) will receive IP addresess and can communicate with eacth other. The containers connected to the r2 will also receive IP Address from r1 through the VXLAN tunnel between r1 and r2.  

![initial network topology](https://user-images.githubusercontent.com/95677915/151544704-b22756c4-ae6c-4e38-83b0-da2785484572.png)

## Prerequisite:
1. Download virtual box or vmware
2. Download Ubuntu 18.04.6 image
- https://releases.ubuntu.com/18.04.6/ubuntu-18.04.6-desktop-amd64.iso

Note: Run all the commands (including LXC's command) with sudo

```bash
$ sudo su
```

## Table of Contents
1. [Setup LXC, container and user](#1-setup-lxc-container-and-user)
2. [(Optional Step) Change the veth name of the container shown during `ifconfig -a`](#2-optional-step-change-the-veth-name-of-the-container-shown-during-ifconfig--a)
3. [Create two standalone bridge in the HOST](#3-create-two-standalone-bridge-in-the-host)
4. [Add eth1 interface to the router containers](#4-add-eth1-interface-to-the-router-containers)
5. [Provide static ip to the router containers](#5-provide-static-ip-to-the-router-containers)
6. [Setup Bridge and VXLAN on both routers](#6-setup-bridge-and-vxlan-on-both-router-container)
7. [Enslave the eth1 interface to the bridge in the routers](#7-enslave-the-eth1-interface-to-the-bridge-in-the-routers)
8. [Setup dnsmasq for dhcp on r1](#8-setup-dnsmasq-for-dhcp-on-r1)
9. [Link container's eth0 to the Host bridge](#9-link-containers-eth0-to-the-host-bridge)
<hr/>

### 1. Setup LXC, container and user 
1. **Install LXC on the host (Run this command on both the HOSTs -- i.e the two containers)**
```bash
$ add-apt-repository ppa:ubuntu-lxc/lxc-stable
$ apt-get update
$ apt-get install lxc
$ apt install lxc-utils (run this command, if any further commands are 'not found')
```

2. **Check if lxc is setup correctly**
```bash
$ lxc-checkconfig
```

3. **Check your lxc version**
```bash
$ lxc-ls —-version
```

4. **Create a new LXC continer**
> Note: Create two containers r1 and r2 (routers) and at-least two other containers which will connect to each of these router container respectively.

```bash
$ lxc-create -t download -n r1
```
- If there is problem with the keyserver then you can pass  `--no-validate` to bypass the validation check
  ```bash
  $ lxc-create -t download -n r1 — —no-validate
  ```
- A more faster alternative would be 
  ```bash
  $ lxc-create -t download -n r1 -- --no-validate --dist ubuntu --release bionic --arch amd64
  ```
- In the experiment we are using, Ubuntu distribution, bionic release and amd64 architecture

5. **View the created containers and their current state**
```bash
$ lxc-ls --fancy
```
- Start the containers with command : 
```bash
$ lxc-start -n r1
```

6. **Create user for each created container**
> Note: Create users for all the containers. This is required to login to the container. (Make sure to start container before attaching users, otherwise possible error : Failed to get init pid)
```bash
$ lxc-attach -n r1
$ adduser username
$ usermod -aG sudo username
```

6. **To login to the container**
```bash
$ lxc-console -n r1
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
$ cd /var/lib/lxc/r1/
$ nano config

# Add the following line to the config file, save and exit
lxc.net.0.veth.pair = r1

$ lxc-stop -n r1
$ lxc-start -n r2

$ ifconfig -a
# Now you will see the veth adapter name is changed to r1
```
Do the same for all the containers but with different name
<hr/>

### 3. Create two standalone bridge in the HOST
Create two bridges (eg: br5 and br6) on the Host (Virtual Machine) which will connect to the router's (r1 & r2) eth1 respectively.
```bash
$ brctl addbr br5
$ ifconfig br5 up
$ brctl addbr br6
$ ifconfig br6 up
```
<hr/>

### 4. Add eth1 interface to the router containers
For r1:
1. change directory to /var/lib/lxc
```bash
$ cd /var/lib/lxc
```
2. Edit the file r1/config
```bash
$ nano r1/config
```
3. Add the following to add the eth1 interface
```
lxc.net.1.type = veth
lxc.net.1.link = br5
lxc.net.1.flags= up
lxc.net.1.name = eth1
lxc.net.1.hwaddr = 00:16:3e:55:ba:cf
lxc.net.1.veth.pair = r1eth1
lxc.net.1.mtu = 1500
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
lxc.net.1.type = veth
lxc.net.1.link = br6
lxc.net.1.flags= up
lxc.net.1.name = eth1
lxc.net.1.hwaddr = 00:16:3e:56:26:3f
lxc.net.1.veth.pair = r2eth1
lxc.net.1.mtu = 1500
```
4. Save and exit

<hr/>

### 5. Provide static ip to the router containers
```bash 
$ vi /etc/default/lxc-net
Uncomment “#LXC_DHCP_CONFILE=/etc/lxc/dnsmasq.conf“, then save and exit

$ vi /etc/lxc/dnsmasq.conf
# Add the following static ip to the file, then save and exit
dhcp-host=r1,10.0.3.10
dhcp-host=r2,10.0.3.20

$ service lxc-net restart
```

<hr/>

### 6. Setup Bridge and VXLAN on both router container
1. Login to the r1 container
2. Add VXLAN on r1
```bash
$ ip link add vxlan0 type vxlan id 10 remote 10.0.3.20 local 10.0.3.10 dev eth0
$ ip link set up dev vxlan0
```
3. Create a bridge on r1 and add the vxlan0 interface to it.
```bash
$ brctl addbr superbr0
$ ip link set up superbr0
$ brctl addif superbr0 vxlan0
```
4. Login to the r2 container
2. Add VXLAN on r2
```bash
$ ip link add vxlan0 type vxlan id 10 remote 10.0.3.10 local 10.0.3.20 dev eth0
$ ip link set up dev vxlan0
```
3. Create a bridge on r2 and add the vxlan0 interface to it.
```bash
$ brctl addbr superbr0
$ ip link set up superbr0
$ brctl addif superbr0 vxlan0
```
Note: The vxlan id 10 can be any number but it should be the same on both routers
<hr/>

### 7. Enslave the eth1 interface to the bridge in the routers
Run the command inside both the routers.
```bash
brctl addif superbr0 eth1
```

<hr/>

### 8. Setup dnsmasq for dhcp on r1
1. Login to r1 and install dnsmasq
```bash
$ apt-get install dnsmasq
```
2. Edit the dnsmasq.conf file
```bash
$ vi /etc/dnsmasq.conf

# Modify the file with these values, save and exit
interface=superbr0
listen-address=192.168.1.1
bind-interfaces
dhcp-range=192.168.1.2,192.168.1.254,12h
```
2. Add and IP to the superbr0 interface on Host A
```bash
ip addr add 192.168.1.1/24 dev superbr0
```
3. Restart the dnsmasq to apply the changes
```bash
service dnsmasq restart
```
4. Check if dnsmasq is running without any error
```bash
service dnsmasq status
``` 
<hr/>

### 9. Link container's eth0 to the Host bridge
Eg: If you have two container c1 and c2 where c1 connects to the r1 and c2 connects to r2
1. From the host, go to /etc/lib/lxc
```bash
$ cd /var/lib/lxc
```
2. Open the c1 config file to edit
```bash
$ nano c1/config
```
3. Replace lxcbr0 with br5
`lxc.net.0.link = br5`
4. Save and exit
5. Open the c2 config file to edit
```bash
$ nano c2/config
```
6. Replace lxcbr0 with br6
`lxc.net.0.link = br6`
7. Save and exit
8. Start both the c1 and c2 container

<hr/>

## Results
- Initial state of containers (before VxLAN connection and DNS service)
![before dns](https://user-images.githubusercontent.com/95677915/152028624-5ffe29ce-6b0f-4575-8665-ed10f1acf422.png)

- Final state of containers (after VxLAN connection and DNS service)
![after dnsmasq conf](https://user-images.githubusercontent.com/95677915/152028755-1287b4f8-e418-425d-b127-0764a7c834bc.png)

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


### 3. Check the client leases (IP address provided by the DCHP on a bridge)
- If the bridge name is superbr1, then run the following command in the vm hosting the server container to find the client IP address assigned by the dhcp.
```bash 
cat /var/lib/misc/dnsmasq.superbr1.leases
```

## Troubleshoot
- dnsmasq: failed to create listening socket for port 53: Address already in use
   - https://askubuntu.com/questions/191226/dnsmasq-failed-to-create-listening-socket-for-port-53-address-already-in-use 
   - https://stanislas.blog/2018/02/setup-network-bridge-lxc-net/    
- ifconfig not found
   - apt-get install net-tools
- brctl command not found
   - apt-get install bridge-utils 

## Extensions from this setup

https://github.com/MobComp/Group5/blob/main/VxLAN%20setup%20with%20two%20VNIs%20between%202%20routers.md
