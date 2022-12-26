# Change allowed frame size to avoid fragmentation and enhance speed

## The Need :  
With Vxlan, we add a lot of headers to the original L2 frame, as shown in the image below.
<img src="https://download-hk.huawei.com/mdl/image/download?uuid=64fc31df6dd34a039499d32c88e39645" alt="MarineGEO circle logo" style="height: 300px; width:500px;"/>  
The overhead sometimes adds upto 80 bytes or more. As a result, there is a high chance that the MTU size of 1500 bytes (standard) may be exceeded. This may result in fragmentation which leads to further overhead than necessary. With this project, the goal is to realize a Data-intensive service, i.e Video-on-demand. Thus it becomes crucial that the MTU size needs to be increased as much as possible. Of course this increase must be done keeping in mind the MTU supported by all parts of the network segment. Jumbo frames can support to 9000 bytes per packet.
  
  
### 1. Check Current MTU size
The current value needs to be read in both the hosts and routers as of now.
```bash
$ ip link show | grep mtu
```
We see that the standard MTU of 1500 bytes is used. Next, we need to see MTU value to know if all of the network segments support jumbo frames. 
  
  
### 2. Setup network to use Jumbo frames
1. ** In the containers for router change MTU size to support jumbo frames**
For router - r1:
a. change directory to /etc/lib/lxc
```bash
$ cd /etc/lib/lxc
```
b. Edit the file r1/config
```bash
$ nano r1/config
```
3. In the eth1 interface, change MTU 
```
lxc.net.1.type = veth
lxc.net.1.link 
lxc.net.1.flags= up
lxc.net.1.name = eth1
lxc.net.1.mtu = 6000
```
4. Save and exit

For router r2
1. change directory to /etc/lib/lxc
```bash
$ cd /etc/lib/lxc
```
2. Edit the file r2/config
```bash
$ nano r2/config
```
3.  In the eth1 interface, change MTU 
```
lxc.net.1.type = veth
lxc.net.1.link = br6
lxc.net.1.flags= up
lxc.net.1.name = eth1
lxc.net.1.mtu = 6000
```
4. Save and exit

### 3. Making it permanent
Create a script that runs at startup to set the MTU
```bash
#! /bin/bash

ip link set veth0 mtu 6000;
ip link set wlan0 mtu 6000;
```
### Reference :  
https://linuxconfig.org/how-to-enable-jumbo-frames-in-linux
