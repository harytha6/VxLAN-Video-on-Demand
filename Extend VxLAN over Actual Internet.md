## Mechanism :
To configure VxLAN over the Actual Internet, the VTEPs first need to have public IP addresses and NAT working to pass traffic. 
In real world applications, a router is going to act as a VTEP. Almost all routers have public IP addresses. This public IP is used directly for the vxlan VTEP rules. Similarly, the AWS EC2 instance, which is a virtual machine, has a public IP address to be reachable from the internet. This public IP is going to be used on the VTEPs to configure VxLAN. Thus any cloud VM like AWS/Azure instances give you the advantage of public IP addresses and replicating the scenario over the real time Transport network. 
  
## Topology : 
![VxLAN over Internet underlay](https://user-images.githubusercontent.com/95677915/157277204-5046858c-d6b9-4aac-af2a-30aed382cbbc.png)
 
 The client c1 and server s1 is in the same subnet 10.0.3.0/24 because of VxLAN : VNI 10 .This NAT is enabled by default in AWS instances.
 
## Method 1 - Using AWS EC2 Ubuntu instances:
  
- Create two EC2 Ubuntu instances to act like 2 virtual machines.  
- one instance (VM2) acts as the router and contains a container(c1) inside it, which is the client   
- the second instance again acts as another router (VM1) and contains a container (s1), which is the video server. 
- connection rule between the two instances is realized by the following general VTEP rule :  
```
ip link add vxlan0 type vxlan id 10 remote [remote-public-VM-IP] local [local-private-VM-IP] dev eth0 dstport 4789
```
  
### Step a. Creating VM instances
The VM instances can be created over Azure or AWS, by following the tutorial - https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EC2_GetStarted.html. The specifications are OS : Ubuntu 18.04, 
  
### Step b. Configure the right VPC security group rules
Select the VPC security group that the VM instance is attached to and then add the below shown rules. The below rules are very liberal, the source is mostly configured to accept connections from anywhere (0.0.0.0/24). This can be restricted too, based on the source IP.
![vpc rules](https://user-images.githubusercontent.com/95677915/157283283-e1d904cc-6925-4141-b3f8-4dbba0ac84a0.png)

By default, Ubuntu does not come with a GUI enabled. This can be enabled if one wants, by following the steps as mentioned in https://github.com/MobComp/Group5/blob/main/Miscellaneous%20Pings%2C%20Tests%20and%20Hints.md#23-enabling-gui-on-ubuntu-aws-ec2-instance

### Step c. Making connection to VM Instance
Either through SSH or remote destop connection, if GUI is enabled.
  
### Step d. Creating a container in VM to act as the client
- Install LXC on both VM1 and VM2
```
apt-get update
apt-get install lxc
lxc-checkconfig
lxc-ls --version
```
- Create s1 container on VM1
```
lxc-create -t download -n s1 -- --no-validate --dist ubuntu --release bionic --arch amd64
```
- Create c1 container on VM2
```
lxc-create -t download -n c1 -- --no-validate --dist ubuntu --release bionic --arch amd64
```
- For easy troubleshoot, rename the veth interfaces from the randomly generated names to easier names according to the network diagram (Reference to do this : https://github.com/MobComp/Group5/blob/main/setup-vxlan-between-two-router.md#2-optional-step-change-the-veth-name-of-the-container-shown-during-ifconfig--a)  

### Step e. Configuring VTEP
- Check connection of lxcbr0 bridge to s1 in VM1 and connection of lxcbr0 bridge to c1 in VM2. This is by default existing.
- Configure vxlan0 with VNI 10 to be attached to the eth0 interface in both VMs
- In VM1, adding vxlan0
```
ip link add vxlan0 type vxlan id 10 remote 34.220.245.107 local 172.31.7.181 dev eth0 dstport 4789
ip link set up dev vxlan0
brctl addif lxcbr0 vxlan0
service lxc-net restart
lxc-start -n s1
lxc-ls -f
brctl show
```
- In VM2, adding vxlan0
```
ip link add vxlan0 type vxlan id 10 remote 18.236.240.175 local 172.31.13.60 dev eth0 dstport 4789
ip link set up dev vxlan0
brctl addif lxcbr0 vxlan0
service lxc-net restart
lxc-start -n c1
lxc-ls -f
brctl show
```
The containers c1 and s1 should have been assigned an IP in the same subnet as the lxcbr0 bridge they are connected to. And the brctl show command should display two interfaces for both lxcbr0 bridges (one interface - vxlan0, second interface - container)
### Step f. Ping from within the container using the tunnel
Now that the tunnel is configured, test it by pinging one end to another. In this example, the video server 10.0.3.220 and the client 10.0.3.92 are physically not in the same subnet. But they should be able to ping each other because of VxLAN.
- In VM1, log in the container s1 and ping c1
```
lxc-attach -n s1
ping 10.0.3.92
```
- Similarly, In VM2, log in the container c1 and ping s1
```
lxc-attach -n c1
ping 10.0.3.220
```
![vxlanp ping +public vtep](https://user-images.githubusercontent.com/95677915/157291488-06a712e1-0e8e-450c-b5a5-871dae105503.png)

[Hint : This pinging of 10.0.3.x IPs is not possible outside the containers c1,s1]
  
  
## Method 2: Using port forwarding on router 
  
This is an extension to the setup in https://github.com/MobComp/Group5/blob/main/Extend%20VxLAN%20over%20Transport%20Layer.md. Here, the sample transport network is replaced by the actual Internet. To achieve this, the routers acting as the Virtual Tunnel endpoints must be first reachable from the Internet. 
To do this, forwarding rules have to be tweaked with the Physical router that the home computer connects to. Virtual machine when set in bridged networking mode, acts like a separate device in the local network and is no longer dependent on the IP of the host operating system.
The same logic also needs to be followed for the containers that are going to act as Video Servers. 
  
### 1.Configure NAT for VMs : 
- To change a virtual machine’s network type in VirtualBox, right-click a virtual machine and select Settings.
- Select the Bridged adapter network mode in the Network settings section and click OK.
- Select the Network Adapter virtual hardware device, select the Bridged network connection type, and click OK.
  
Alternatively, NAT mode can also be used in Networking Adapter type. If so, the above steps can be ignored and instead the following needs to be done :   
- Open a virtual machine’s settings window by selecting the Settings option in the menu.
- Select the Network pane in the virtual machine’s configuration window, select NAT in network settings selection 
- Expand the Advanced section, and click the Port Forwarding button. (Note that this button is only active if you’re using a NAT network type – you only need to forward ports if you’re using a NAT.)
- Click on VirtualBox’s Port Forwarding Rules window to forward ports. 
- Add the following rule : Protocol = TCP, Host port = 80, Guest port = 80, Host IP = 127.0.0.1

A few checks at this stage   
- It's better to use bridged mode compared to NAT, as the host computer’s firewall doesn’t interfere in bridged networking mode.
- The firewall software running inside your virtual machine isn’t blocking the connections. (You may need to allow the server program in the guest operating system’s firewall.)
  
### 2. Check port forwarding in actual Home Router : 
https://www.howtogeek.com/66214/how-to-forward-ports-on-your-router/ 
Also port forwarding needs to be enabled only if NAT mode is selected in the previous steps
 - First, find out the publicly used external IP of your router using the website "whatismyip.com"
 - Go to Router Admin page 192.168.1.1
 - Locate the Port Forwarding Rules tab on Your Router homepage
 - Create a Port Forwarding Rule

##### Port Forwarding rules  
- Give a name for the rule (usually based on the application)
- Mention 'both' for protocol (instead of just selecting TCP or UDP)
- Source IP can be mentioned as the static IP of VTEP on the other end of the tunnel. Also, it can be left blank for initial testing purpose. 
- External Port Number : port facing the internet, choose a high value to avoid conflicts with already running services . (A list of common services can be verified here - https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers)
-  Internal IP and port : Enter the interface to which the desired end device is connected (eg : Virtual machine, Video server)

### 3. Test port forwarding  
- port checker available online at YouGetSignal.com
- We can test to see if our virtual server port is reachable or not.
- Plug in your IP address and the port number in the site and click “Check”.
- You should receive a message like “Port X is open on [Your IP]”.
  
Hint : If the port is reported as closed, double check both the settings in the port forwarding menu on router and your IP and port data in the tester.
  
## References : 
https://www.google.com/amp/s/www.howtogeek.com/122641/how-to-forward-ports-to-a-virtual-machine-and-use-it-as-a-server/amp/  
https://www.howtogeek.com/66438/how-to-easily-access-your-home-network-from-anywhere-with-ddns/  
https://www.australtech.net/how-to-enable-gui-on-aws-ec2-ubuntu-server/  

