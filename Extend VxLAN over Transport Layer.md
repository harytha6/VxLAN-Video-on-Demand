# Extend VxLAN over Transport Layer  

## The Need :  
As known from literature, VxLAN topology only is an underlay to the existing IP transport network. So, the huge globally spread Transport network cannot all be configured again to support VxLAN. Instead, the transport layer needn't know the difference, yet just transmit the packet.
  
## Mechanism :
In this sense, the transport network which is the public Internet, will not know whether a packet has a VxLAN frame inside it or not. Only on reaching the router at the other end (i.e VxLAN Tunnel End Point), the decoding happens. To simulate this, the basic idea is to have 3-4 containers created to act as routers which is going to act as the small transport network between VTEP A and VTEP B (as seen in figure)
  
### 1.Configure NAT for VMs
The current network topology diagram as displayed in : https://github.com/MobComp/Group5/blob/main/setup-vxlan-between-two-router.md is going to be split into two virtual machines. 

![distributed network](https://user-images.githubusercontent.com/95677915/152438098-1412b0d9-6443-4aeb-bcce-074771dda8fe.png)  https://serverfault.com/a/225161
As a result router r1 with hosts c1,c3 and c5 are going to be retained in one VM and the router r2 with the hosts c2 and c4 are going to be moved to the new VM. First connection between Virtual machines must be tested. Configure a new NAT rule in virtualbox by following the step as shown in this tutorial : https://serverfault.com/a/225161. Then, both the VMs get IP addresses in the same subnet and test by pinging one from the other. 
Eg: VM1 = 192.168.0.17 and VM2 = 192.168.0.18. This subnet should match the same subnet as used in the Host OS (outside virtual box)
In VM1 terminal:
```bash
ping 192.168.0.18
```
Test this vice versa. Extend the same logic for how many ever VMs need to be connected together.   
  
### 2. Bypass lxcbr0 default bridge and create new lxcbr1  
By default, lxcbr0 has a set of NAT rules attached to it. These rules allow us to reach internet from inside the container through port forwarding logic, but does not allow discovery of containers from the internet. But the essential feature of VxLAN is that it is a private virtual network that spans over the Internet. To solve this, we need to create a new bridge 'lxcbr1' to bypass 'lxcbr0' and configure our own NAT rules. 

We need our video servers to be publicly accessible.
1. We create a video server container - 's1'
a. 
```bash
$ lxc-create -t download -n s1 -- --no-validate --dist ubuntu --release bionic --arch amd64
```
b. Edit the file network/interfaces to add the bridge 'lxcbr1'. It connects directly to the eth0 interface of Ubuntu VM. 
```bash
$ cd /etc/network/
$ nano interfaces
```
c.  Add the following lines 
```bash
auto lxcbr1 
iface lxcbr1 inet dhcp
            bridge_ports eth0
            bridge_stp off
            bridge_fd 0
            bridge_maxwait 0
```
Save the file and exit

d. When the new container is not running, it does not fetch an address using the DHCP configured on lxcbr0. This can be verified by 
```bash
$ cat /var/lib/misc/dnsmaq.lxcbr0.leases
```  
Verify the lines shown above, such that it does not include container s1.  

### 3. Configuring s1 container's link to lxcbr1
a. Edit the file s1/config
```bash
$ cd /var/lib/lxc
$ nano s1/config
```
b. Edit/Add the following lines
```bash
lxc.net.0.link = lxcbr1
lxc.net.0.veth.pair = s1eth0
lxc.net.0.ipv4 = 192.168.1.65/24 192.168.1.255
lxc.net.0.ipv4.gateway = 192.168.1.1
lxc.start.auto = 1
lxc.start.delay = 20
```
(For the ipv4 address statically, use a subnet range that your local PC is in. Hint : This same subnet is used when lxcbr1 brige gets an IP dynamically once it goes up. Verify
using ifconfig for lxcbr1. The second address seen in this command is the broadcast address.)  
(The gateway address is usually the router/default address and is mostly 192.168.1.1 or 192.168.1.254)  
(The last two commands are to automatically start the container when the VM is up, after a certain delay.)  

c.Save and exit

d. Start the lxcbr1 bridge
```
$ ifup lxcbr1
```  
After running this command, a lot of information regarding the DHCP address got using (DHCP discover,request, offer, ack) is shown.
Also, further information can be viewed with 
```bash
$ brctl show
```  
e. Turn off DHCP for s1
We try to set static address for s1 in the above steps (i.e 192.168.1.65). To ensure this, we need to turn of the automatic DHCP feature by editing the interfaces file inside s1. Log in to s1 container
```bash
$lxc-console -n s1
```
```bash
$ cd /etc/network
$ nano interfaces
```
Edit the following line in the file
``` 
auto eth0
iface eth0 inet manual
```  
Save and exit 
### 3. Start s1 container and test connectivity
a Start the s1 container
```bash
$ lxc-start -n s1
```
Verify the IP assignment of s1 container,  if its the same as assigned by us earlier in the config file (Eg : 192.168.1.65)
```bash
$ lxc-ls --fancy
```

### 4. Configure VxLAN rule for Guest OS

```bash
$ ip link add vxlan0 type vxlan id 10 remote 192.168.0.18 local 192.168.0.17 dev enp0s3
$ ip link set up dev vxlan0
```
Add bridge to connect this to interface 
```bash
$ brctl addbr superbr0 
$ ifconfig superbr0 up
$ brctl addif superbr0 vxlan0
```

### 5. Configure forwarding rules in actual router 

```bash

```
## Miscellaneous :   
Always copy the config file or network/interfaces file before editing, if unsure of changes. To do so, go to the directory where the file exists.  
```bash
$ cp filename filename.original
```  
Even if something goes wrong, we can recover the setup from these original files.
## Reference :  
https://www.youtube.com/watch?v=vReAkOq-59I - Connect 2 VMs
https://www.youtube.com/watch?v=a0dzCzpdUfw&t=2241s - Connect to internet  (46:50)
https://serverfault.com/a/225161
