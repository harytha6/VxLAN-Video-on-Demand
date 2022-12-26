# Miscellaneous Pings, Tests and Hints
  
### 1.IPv6 Ping format
Initially, when LXC containers are launched, they are assigned only IPv6 addresses. To test connecvitivity, we need to test them. ping6 command without interface name returns an error : "Invalid argument - connect failed". The relevant ethernet interface of the container can be read from ifconfig  command.
```bash
$ping6 fe80::201:5cff:fe63:f846%eth0
```
Output : 
```bash
PING fe80::201:5cff:fe63:f846%eth0(fe80::201:5cff:fe63:f846) 56 data bytes
64 bytes from fe80::201:5cff:fe63:f846: icmp_seq=1 ttl=64 time=13.7 ms
``` 
(Hint : In our example, container r1 has an interface also named r1 (if name changed))

### 2.IP Link add VxLAN command
Example of command inside each container to configure and meaning of each argument
```bash
ip link add vxlan0 type vxlan id 10 remote 10.0.3.20 local 10.0.3.10 dev eth0
``` 
Format : 
```bash
ip link add DEVICE type vxlan id VNI [ dev PHYS_DEV  ] [ { group | remote } IPADDR ] [ local { IPADDR | any } ] [ ttl
              TTL ] [ tos TOS ] [ df DF ] [ flowlabel ]  [ dstport PORT ]
```
 - id VNI - specifies the VXLAN Network Identifier (or VXLAN Segment Identifier) to use.
 - dev PHYS_DEV - specifies the physical device to use for tunnel endpoint communication. (Basically, it is just the interface name)
 - remote IPADDR - specifies the unicast destination IP address to use in outgoing packets when the destination link layer address is not known in the VXLAN device forwarding database. This parameter cannot be specified with the group parameter.
 - local IPADDR - specifies the source IP address to use in outgoing packets.
 - ttl TTL - specifies the TTL value to use in outgoing packets.
 - tos TOS - specifies the TOS value to use in outgoing packets.
 - df DF - specifies the usage of the Don't Fragment flag (DF) bit in outgoing packets with IPv4 headers. The value inherit causes the bit to be copied from the original IP header. The values unset and set cause the bit to be always unset or always set, respectively. By default, the bit is not set.
 - flowlabel FLOWLABEL - specifies the flow label to use in outgoing packets.
 - dstport PORT - specifies the UDP destination port to communicate to the remote VXLAN tunnel endpoint(usual value : 4789) (If the argument is missing in the command, possible error : "vxlan : destination port not specified, use dstport 4789 or dstport 0 ")

### 3.IP Link show command
To see link-layer information of all available devices and their state (UP or DOWN)
```bash
ip link show
``` 
To display the information for one specific device
```bash
ip link show dev [DEVICE]
``` 
This command can be used to verify the state after "ip link set" command is used, to verify changes.  

### 4.Cloning and Deleting containers
To Clone (existing c1 container):
```bash  
  sudo lxc-clone c1 c2
  sudo lxc-start -n c2 -d
```
To Delete :
  First stop the container with 
```bash
  lxc-stop -n containername
``` 
  Then delete the LXC by 
```bash
  lxc-destroy -n containername
```

### 5. View and Delete Bridges created using brctl  
To view the list of bridges created , use  
```bash
brctl show
```
To view the learned MAC addresses of ports connected to the bridge, use  
```bash
brctl showmacs bridgename
```
---------
First set the running status of the bridge to down status and then delete it :
```bash
ip link set br100 down
brctl delbr br100
```

### 6. LXC failed to start
Launch start command with a logfile and view it
```bash
lxc-start -n r1 --logfile log
```
In the current folder, there is a new 'log' file created, open it to view detailed errors

### 7. Ethernet address change when using brctl command
When using brctl command to add an interface (eg: vxlan0) to an existing bridge (eg : superbr0), then the 'ether address' of the bridge will change to the 'ether address' of the interface device added to it (eg: MAC address of vxlan0).This can be verified by running ifconfig -a command 
```bash
brctl addif superbr0 vxlan0
ifconfig -a
```
When a second interface(eg: eth1) is added to the same bridge (eg:superbr0), now the 'ether address' of the bridge is updated to the 'ether address' of this second interface(eg: eth1's MAC address)
```bash
brctl addif superbr0 eth1
ifconfig -a
```
### 8. Exit from Container lxc-console
Press 'Ctrl + a' together, release both the keys and then press 'q'. (Make sure caps lock is not ON, as the command is case sensitive)

### 9. dnsmasq service failed to start
Launch dnsmasq service or query the status with one of the commands below
```bash
service dnsmasq status
service dnsmasq start
systemctl status dnsmasq.service
```
When a 'failed to start' error occurs, then navigate to the log file to find the exact error description. To navigate to the logs,
```bash
cd /var/logs
cat syslogs
```
Look for the lines regarding dnsmasq.service in this and see the exact error description )( Eg: it could be 'failed to assign 192.168.1.1 address' or 'failed to create a listening socket for port 53' and so on)
- If the error is 'failed to create a listening socket for port 53', then view what is running on port 53 by the command : 
```bash
sudo netstat -tulpn | grep LISTEN
```
Run the above command with root privilege to see all services. Sometimes on port 53, system-md resolve is running.
To disable this service, further steps can be found here :
https://github.com/MobComp/Group5/blob/main/setup-vxlan-between-two-router.md#troubleshoot

### 10. dnsmasq service failed to stop
The service does not stop and it may indicate an error : "The name org.freedesktop.PolicyKit1 was not provided by any .service files". This could be just a permissions issue, try running the same command with root priviliege to avoid this error.
```bash
sudo service dnsmasq stop
```
### 11. SSDP and multicast address seen in Wireshark
The multicast address (239.255.255.250) is used mainly by SSDP (Simple Service Discovery Protocol) by various vendors to advertise the capabilities of (or discover) devices on a VLAN. Since each client device will most likely be using this protocol to advertise its capabilities to other devices, SSDP traffic volume can quickly increase due to flooding of the traffic on a network proportional to the amount of new devices.

### 12. More information on vxlan interface
```bash
ip -d link show vxlan0
```

### 13. VxLAN Routing tables
```bash
bridge fdb show dev vxlan0
```

### 14. IP Routing Table  
```bash
netstat -rn
```
(or)
```bash
sudo route -n
```

### 15. Forwarding Tables with unicast VxLAN 
https://blogs.vmware.com/vsphere/2013/05/vxlan-series-how-vtep-learns-and-creates-forwarding-table-part-5.html

### 16. Failed to  download http://images.linuxcontainers.org/ubuntu....during lxc-create container:
This happens sometimes due to incorrect permissions or it could be also a server issue (server that is hosting the image). According to some sources, this error rarely occurs due to a mirror sync operation at the data centers. Usually this causes a 30 minute to 1 hour outage. But trying later would resolve the issue. To check first if the image is accessible over HTTP, run
```bash
wget http://images.linuxcontainers.org//images/ubuntu/bionic
```
The exact URL to paste here can be found in the error description itself.
If 'wget' command also fails, it returns a '404 - Not Found' error. This means, we have to wait or use an image from the local cache if available.  
Alternative to the wget command is through browser navigation as shown in image below
![image](https://user-images.githubusercontent.com/95677915/152251345-cc94c6b1-851d-4138-909f-29c767770e13.png)   
If there are files like in the image, then issue could be quickly solved, if no items are listed, then issue remains at the server side.  

### 17. Fix : Cant close terminal. Kill process?  
Usually this happens due to the following services left running
  - bridges running (ie listening to interfaces connected) 
  - dhcp service running  
To safely save the work, these services can be stopped (eg: ifdown br0) and then close the terminal.  

### 18. To viewthe chain of rules in iptables
```
iptables -vnL -t nat
iptables -S
iptables -L --line-numbers
```
### 19. To view the IP address of bridge, etc...
```
ip addr show <bridgename>
ip address
```
### 20. To view routing tables
```
ip r  
netstat -rn
```
### 21. To add static routes 
```
ip route add 192.168.1.0/24 via 192.168.1.1 dev superbr0
```
### 22. To give internet access to containers, add the below rule to iptables
```
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o br0 -j MASQUERADE
```
### 23. Enabling GUI on ubuntu AWS EC2 instance
https://www.australtech.net/how-to-enable-gui-on-aws-ec2-ubuntu-server/ 

### 24. Install Wireshark & Handle Errors
https://linuxhint.com/install_configure_wireshark_ubuntu/

- Fix Error : Couldn't run /usr/bin/dumpcap in child process: Permission denied
- Solution : Reboot the instance (https://techoverflow.net/2019/06/10/how-to-fix-wireshark-couldnt-run-usr-bin-dumpcap-in-child-process-permission-denied-on-linux/)
  
### Reference :  
https://community.ui.com/questions/ipv6-Invalid-argument-Solved/86c26388-05a3-4148-9131-52040884fc0f  
https://man7.org/linux/man-pages/man8/ip-link.8.html  
https://phoenixnap.com/kb/linux-ip-command-examples  
https://online.visual-paradigm.com/app/diagrams/#diagram:proj=0&type=NetworkDiagram&width=11&height=8.5&unit=inch  
https://unix.stackexchange.com/questions/31763/bring-down-and-delete-bridge-interface-thats-up  
https://github.com/lxc/lxc/issues/1457  
https://www.cyberciti.biz/faq/unix-linux-check-if-port-is-in-use-command/  
https://stanislas.blog/2018/02/setup-network-bridge-lxc-net/ - Ip tables, lxc-net
https://extremeportal.force.com/ExtrArticleDetail?an=000091058 
https://archives.flockport.com/flockport-labs-lxc-and-vxlan/
https://github.com/lxc/lxd/issues/1260#issuecomment-616982911  
https://www.thegeekstuff.com/2017/06/brctl-bridge/#:~:text=brctl%20stands%20for%20Bridge%20Control,it%20as%20one%20logical%20network.&text=Delete%20Existing%20Ethernet%20Bridge%20using%20delbr



