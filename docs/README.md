

# What is VXLAN?
[Webinar - VLAN vs VXLAN (Video)](https://www.youtube.com/watch?v=HDo7XVLRd9E)

VXLAN is an encapsulation protocol that provides data center connectivity using tunneling to stretch Layer 2 connections over an underlying Layer 3 network.

In data centers, VXLAN is the most commonly used protocol to create overlay networks that sit on top of the physical network, enabling the use of virtual networks. The VXLAN protocol supports the virtualization of the data center network while addressing the needs of multi-tenant data centers by providing the necessary segmentation on a large scale.

 
## What Problem Does VXLAN Solve?

Data centers have rapidly increased their server virtualization over the past decade, resulting in dramatic increases in agility and flexibility. Virtualization of the network and decoupling the virtual network from the physical network makes it easier to manage, automate, and orchestrate.

VXLAN is a technology that allows you to segment your networks (as VLANs do) but also solves the scaling limitation of VLANs and provides benefits that VLANs cannot. Some of the important benefits of using VXLANs include:

    You can theoretically create as many as 16 million VXLANs in an administrative domain (as opposed to 4094 VLANs).
    VXLANs provide network segmentation at the scale required by cloud builders to support very large numbers of tenants.
    With traditional Layer 2 networks you are constrained by Layer 2 boundaries and forced to create large or geographically stretched Layer 2 domains. 
    VXLAN's functionality allows you to dynamically allocate resources within or between data centers and enables migration of virtual machines between servers that exist in separate Layer 2 domains by tunneling the traffic over Layer 3 networks.

 
## How Does VXLAN Work?

The VXLAN tunneling protocol that encapsulates Layer 2 Ethernet frames in Layer 3 UDP packets, enables you to create virtualized Layer 2 subnets, or segments, that span physical Layer 3 networks. Each Layer 2 subnet is uniquely identified by a VXLAN network identifier (VNI) that segments traffic.

The entity that performs the encapsulation and decapsulation of packets is called a VXLAN tunnel endpoint (VTEP). To support devices that can’t act as a VTEP on their own, like bare-metal servers, a Juniper Networks device can encapsulate and de-encapsulate data packets. This type of VTEP is known as a hardware VTEP. VTEPs can also reside in hypervisor hosts, such as kernel-based virtual machine (KVM) hosts, to directly support virtualized workloads. This type of VTEP is known as a software VTEP.

## Hardware and software VTEPs.
![Hardware and software VTEPs.](https://www.juniper.net/content/dam/www/assets/images/us/en/research-topics/what-is/diagram-what-is-vx-wan-1.png/_jcr_content/renditions/cq5dam.web.1280.1280.png)
<p align=center>Hardware and software VTEPs are shown above.</p></br>

![](https://www.juniper.net/content/dam/www/assets/images/us/en/research-topics/what-is/diagram-what-is-vx-wan-2.png/_jcr_content/renditions/cq5dam.web.1280.1280.png)

>In the figure above, when VTEP1 receives an Ethernet frame from Virtual Machine 1 (VM1) addressed to Virtual Machine 3 (VM3), it uses the VNI and the destination MAC to look up in its forwarding table for the VTEP to send the packet to. VTEP1 adds a VXLAN header that contains the VNI to the Ethernet frame, encapsulates the frame in a Layer 3 UDP packet, and routes the packet to VTEP2 over the Layer 3 network. VTEP2 decapsulates the original Ethernet frame and forwards it to VM3. VM1 and VM3 are completely unaware of the VXLAN tunnel and the Layer 3 network between them.


</br>
- Ref: [Juniper](https://www.juniper.net/us/en/research-topics/what-is-vxlan.html)
                
                
            
