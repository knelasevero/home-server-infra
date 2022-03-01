# Home private network
## How to build a simple but good home network with multiple VLANs

This course is aimed to assist anyone wanting to setup a more secure and more robust home network so you can avoid just connecting to you ISP's provided modem/router. You will also be able to segregate your network in multiple VLANs, allowing you to separate your personal devices from your servers and in the end give you more control over everything.

We will aim this guide at some specific devices and softwares, but you can adapt where needed. Please reach out if you run into problems.

<br>

## Table of Contents

* [1 - Requirements](#reqs)
* [2 - Pfsense appliance options for your house](#wherepfsense)
* [3 - Preparing pfsense](#preparingpfsense)
* [4 - Pfsense setup](#pfsensesetup)
* [5 - Pfsense VLAN setup](#pfsensevlans)
* [6 - Pfsense easy to miss details](#pfsensedetails)
* [7 - Smart Switch VLAN tagging setup](#smartswitchvlans)
* [8 - How to troubleshoot some problems](#troubleshooting)
* [9 - Wifi AP](#wifi)
* [10 - Restrictive rules](#rules)
* [11 - Suricata IDS/IPS](#rules)
* [12 - Further improvements](#further)

<br>

<a name="reqs"></a>
## [1 - Requirements](#reqs)

<br>

* Some familiarity with Linux, running Linux commands, ssh and other introductory Linux concepts
* Some familiarity with networking, and its components (You will learn a bunch here as well).
* Some familiarity with Linux networking (You will learn a bunch here as well).
* Your Personal Machine
    * It can be a Windows or a Linux machine. Preferable if it is a Linux machine since during the course I will show inputs and outputs from a Linux machine. The distribution doesn't matter.
    * This machine needs to have a ethernet socket (CAT 6/CAT 4 - simple internet cable thingy). If your laptop does not have it, you can buy an ethernet to USB adapter.
* A VLAN aware router/firewall. More specifically for our examples, a hardware appliance were we can install Pfsense.
* A VLAN aware switch (smart switch).
* At least 6 ethernet cables, of various lengths, depending of how you mount everything.
* A Wifi Access Point.
* Your ISP modem/router (We can maybe get rid of it, we will talk about that).
    

Being a bit more specific about the hardware that we will be using as an example:

* For the Pfsense compatible appliance, you can use any Netgate routers, Protectli Vault routers or similar. For this example we will be using a Protectli Vault 6, which can be a bit expensive, but you can follow same steps with Netgate cheaper hardware.
* We will be using a TP-Link TL-SG108E smart switch. You can use any smart switch capable of dealing with 802.1Q VLANs.
* For the wifi Access point, you can use any available. I will be just showing the simple steps with the Unifi Nanohd from Ubiquiti.

<br>

<a name="wherepfsense"></a>
## [2 - Pfsense appliance options for your house](#wherepfsense)

<br>

### First option Protectli Vault

This is the option that I am using for this demo. It is very powerful, and you can easily change/replace components on it like in a laptop or PC. Some versions of it come without storage or RAM, and you are expected to install those yourself. Protectli Vault 6 comes with 6 ports, intel **i** series processors, and you are supposed to install a mSATA SSD and RAM on it. You can go up to 64 GB of RAM with 2 DDR4 16GB RAM units. You can also put less than that. This is a router that, in all reality, you can use as a PC, if you for some reason need that. It has HDMI output and multiple USBs sockets.

Link: https://eu.protectli.com/products/

<br>
### Netgate

The advantage of going with Netgate and using Pfsense is the fact that they are the company helping maintain the community and enterprise edition of the software. They have really interesting options for appliances, some even allowing you to just put your fiber cable directly on the router and completely throw away your ISP's modem (Not all ISPs would be happy with that, by the way - in Brazil they even artificially jam your signal if you do that). The other advantage of going with Netgate is that they provide some very interesting cheap options, like the Netgate 1100, for $189. They even provide hardware that already comes with Pfsense installed, which would make you skip some steps in this course.

Link for the products that already come with Pfsense: https://www.netgate.com/pfsense-plus-software/how-to-buy#appliances

<br>
### Other options

Simply search for Pfsense on any e-commerce website, and you will get back some other options that will let you install Pfsense on them. It is as simple as that, and you can decide based on what you plan to do at your home. If you don't have heavy load planned, maybe going for something less powerful could be interesting to you. 

<br>

<a name="preparingpfsense"></a>
## [3 - Preparing pfsense](#preparingpfsense)

<br>

If you have one of the hardware appliances that comes clean, with no operating system, the first thing we have to do is install Pfsense on it.

<br>
### Downloading Pfsense

Let's go to the [official download page](https://www.pfsense.org/download/) and fill the form according to our preference. For Protectli Vault, since we have HDMI output, you would fill this fields as:

* Version: choose the latest
* Architecture: AMD64
* Installer: USB Memstick Installer
* Console: VGA
* Mirror: Anything that is closer to you for faster download

<br>
### Creating bootable USB Stick

If you are on Windows, you can use Rufus for writing the image to the stick. If you are on Linux/Mac, you can use anything that you want, like dd, or something like [balenaetcher](https://www.balena.io/etcher/). Simply write that image file that you downloaded to the USB stick that you want to use as bootable device.

<br>
### Installing Pfsense to the Appliance

For Protectli Vault, you can now plug a keyboard and the USB stick to any of its USB ports. Turn it on while being plugged to the power socket. If it beeps 4 times (initial turn on beep and 3 different beeps) and gives you no video output, you probably forgot to install an SSD and RAM memory units (Or you did not realize that this appliance comes without them 😅).

For installation steps, you can go simple with:

* Accept copyright notice
* Install
* Default Keymap
* Auto ZFS
* Install
* Stripe
* Then choose the appliance SSD from the list (select with space bar, enter to continue)
* Last chance warning, just accept it

It should be finished pretty quickly.


<br>
### Booting it up

Unplug your keyboard and USB stick, and reboot the device. It will boot up and sing for you. It will print its IP to the HDMI output monitor, and now you can use it to login to it.

![IP on screen](https://github.com/knelasevero/home-server-infra/blob/main/md/images/photo_2022-02-24_13-25-08.jpg?raw=true)

<br>
### Plugin it in

Plug the internet cable, coming from your modem in the WAN port of the appliance, and plug the LAN port to you laptop. If you did not configure your ISP's modem to stay in bridge modem, it will just assign a private IP to your Pfsense router. If you managed to do that before, your Pfsense will get a public IP assigned by your ISP. For some modems you need to leave ISP account details wrong on purpose, or similar strategies, while also enabling PPPoE passthrough. Then you would have to configure PPPoE credentials on your Pfsense.

You can completely ignore above paragraph if you just want to let Pfsense get a private IP and if you don't mind configuring port forwarding on both your modem and router.

<br>

<a name="pfsensesetup"></a>
## [4 - Pfsense setup](#pfsensesetup)


<br>

Let's type that ip address that we took note before in our web browser and access Pfsense admin console. Accept the insecure notice, since the connection is not behind ssl (which you can fix, but won't be covered here), and login with default credentials for now:

![login screen](https://github.com/knelasevero/home-server-infra/blob/main/md/images/photo_2022-02-24_13-49-33.jpg?raw=true)

* Usename: admin
* Pass: pfsense

![wizard1](https://github.com/knelasevero/home-server-infra/blob/main/md/images/image_2022-02-24_15-07-39.png?raw=true)

Go over the wizard configuration. Click next on the welcome notice. Click next on the Netfate support notice. Use any hostname that you want. Set DNS servers that you like, maybe 1.1.1.1 for primary and 8.8.8.8 for secondary. Uncheck override DNS. Click next.

At the WAN configuration, if you managed to put your modem in bridge passthrough mode, you will need to fill credentials here (not covering this, since this can vary a lot). If not, leave everything as is, and **uncheck** block private networks from entering via WAN, since your modem will give your Pfsense a private IP. Keep the block bogon option checked.

![lanconfig](https://github.com/knelasevero/home-server-infra/blob/main/md/images/image_2022-02-24_15-09-17.png?raw=true)

At the LAN configuration, set a new IP for your Pfsense, something less usual than what it comes with, maybe 10.120.0.1, or any other private range that you like.

At the password config, set a new strong password, ideally randomly generated by a password manager.

Review your changes and hit finish. If the browser takes too long to reboot, you can reboot the device yourself.

Now we need to access Pfsense on 10.120.0.1, instead of the IP that we used before.

<br>

---
<center>**NOTE**</center>
<center> Pfsense is a beast, and since you have it already, VLANS are obviously not the only thing that you can do with it. I recommend having a look over YouTube and watching some overview videos if you want to know what more it is capable of. A good introductory and fun video that I can recommend is from NetworkChuck, where he basically shows everything that we have done here, until this point, and a bit more (like setting up Always-On VPN on your router).  </center>

<center><strong><u>[your home router SUCKS!! (use pfSense instead)](https://youtu.be/lUzSsX4T4WQ)</u></strong></center>

---

<br>

<a name="pfsensevlans"></a>
## [5 - Pfsense VLAN setup](#pfsensevlans)

<br>

Before we start talking about VLANS I want to sit down a bit and talk about the simple network topology that we want to create in our home. Looking at it you can adapt to anything that makes sense to you, but this one is the generic "Servers and Personal stuff don't mix up" design.

So this is what we are trying to do:

![vlan topology](https://github.com/knelasevero/home-server-infra/blob/main/md/images/photo_2022-02-24_14-35-58.jpg?raw=true)

Very simple, modem to firewall/router, then to smart switch, and then separating into 2 VLANs. VLAN 1 (or more semantically, VLAN 10, so we start thinking about those VLAN IDs and IP ranges) will host our servers, where we plan to run web services or anything that is not personal. And VLAN 20 hosts our WIFI Access Point, which provides internet and connectivity to our personal devices. If an attacker manages to take hold of your personal devices, you are making it a bit more difficult for them to attack your servers (pretty hard). Same thing if the attacker takes hold of your servers, they would not easily jump to your personal devices, and you are reducing the blast radios.

Let's get right to it then.

<br>
### Setting VLANs up in Pfsense

Go to "Interfaces" > "Assignments", in the admin console. Click the VLAN tab. Click the Add button.

![vlan 10](https://github.com/knelasevero/home-server-infra/blob/main/md/images/image_2022-02-24_16-12-22.png?raw=true)

Create a new VLAN that you want to use the port igb2 (WAN is igb0, LAN is igb1). We want another port (igb2), that is not the LAN port, since in the LAN port we want to leave the admin console available, but that is not true for anything else. We assigned the VLAN tag 10 here, and this is what our smart switch will later use to know what is owned by one VLAN of the other. Click Save.

![vlan 20](https://github.com/knelasevero/home-server-infra/blob/main/md/images/image_2022-02-24_16-07-22.png?raw=true)

Do the same for your VLAN 20, write descriptions that make sense to you.

<br>
### Assign the VLANs to interfaces

![VLANs created](https://github.com/knelasevero/home-server-infra/blob/main/md/images/image_2022-02-24_16-19-32.png?raw=true)

Navigate to "Interfaces" > "Assignments", in the admin console. Click the "Interface Assignments" tab. Click the last dropdown, next to the Add button. Select the "VLAN 10 on igb2" option. Click Add. Do the same for VLAN 20.

Congrats, you have VLANs configured, but we still need to enable them, let them do dhcp, and set firewall rules for them.

<br>
### Enabling and configuring VLANs

![Enable Vlan 10](https://github.com/knelasevero/home-server-infra/blob/main/md/images/image_2022-02-24_16-25-54.png?raw=true)

Navigate to "Interfaces" > "Assignments", and click OPT1 interface. Let's enable it and assign a static ip to it. ☝️ 

![Enable Vlan 20](https://github.com/knelasevero/home-server-infra/blob/main/md/images/image_2022-02-24_16-25-54.png?raw=true)

Do the same for OPT2. ☝️

If the static ip was configured correctly, it should now show up in the DHCP server pages. Please make sure you let it be static, and that you let the mask be /24.

<br>
### Enabling DHCP

![Enable dhcp](https://github.com/knelasevero/home-server-infra/blob/main/md/images/image_2022-02-24_16-32-51.png?raw=true)

You can only enable DHCP if the interface is enabled, if it has a static ip with /24 mask, and if it is not blocking private ips coming from WAN. Navigate to "Services" > "DHCP Server", and you should see all interfaces matching this criteria as tabs at the top of the configuration page.

Enable DHCP and choose a reasonable range for each of the OPT interfaces.

<br>
### Firewall for the new interfaces

Navigate to "Firewall" > "Rules". Have a look over the LAN interface rules. The first one simply lets us access the web admin console, and PFsense does not allow us to delete this rule, so we don't lock ourselves out of it. In any case, rules on top have priority, so if you block everything on top of that rule, you are locked out anyway.

The second and third rules allow IPV4 and IPV6 coming from the LAN subnet, for any protocol (important ones maybe being UDP and TCP here, since we need to reach UDP 53 for DNS, all your "normal" traffic will likely be on TCP).

If you have a look over OPT1 and OPT2, they don't have any rules. Which for Pfsense means block everything. We need to allow some traffic here.

![allow rules](https://github.com/knelasevero/home-server-infra/blob/main/md/images/photo_2022-02-24_15-45-33.jpg?raw=true)

For testing initially just go ahead and create rules that allow all traffic inside the VLAN. And do the same for OPT2.

![alias](https://github.com/knelasevero/home-server-infra/blob/main/md/images/image_2022-02-24_16-43-59.png?raw=true)

You can also create an IP alias for each of the IP ranges that you have (not including gateways) to already explicitly block traffic between those ranges. Navigate to "Firewall" > "Aliases", and create a new one using the range that you configured in the DHCP server.

![block](https://github.com/knelasevero/home-server-infra/blob/main/md/images/image_2022-02-24_16-42-54.png?raw=true)

Then block those ranges from talking on both interfaces (or make a floating rule).

<br>

<a name="pfsensedetails"></a>
## [6 - Pfsense easy to miss details](#pfsensedetails)

<br>

I want to list here some things to re-check in the previous steps.

* Be sure that you include UDP in those Firewall rules, since machines need to reach port 53 UDP to resolve DNS
    * In those print screens I am setting protocol to "any" for the sake of simplicity. You of course will need to come back later and start restricting your network more and more
* If you cant configure DHCP, you probably missed one of these things:
    * You need to enable the interface
    * You need to assign it a Static IP
    * You need to set the /24 mask
    * You can block bogon traffic, but cant block private traffic coming from WAN

<br>

<a name="smartswitchvlans"></a>
## [7 - Smart Switch VLAN tagging setup](#smartswitchvlans)

<br>

Let's now start to configure our switch. You probably want to read its manual to know how to access its admin console and how to setup VLANs. For this example we are going to go through how to setup these 2 VLANs (10 and 20) for TP-Link TL-SG108E smart switch.

<br>
### Choosing Ports

![switch vlans](https://github.com/knelasevero/home-server-infra/blob/main/md/images/photo_2022-02-24_16-43-11.jpg?raw=true)

Before starting, we need to decide which ports will be assigned to which VLANs in our segregated network. To make it visually simple, we can think of port 1 being the trunk port, coming from the router, ports 2-4 being the VLAN 10, and ports 5-8 being VLAN 20.

<br>
### Setting up the switch

Don't connect your switch to the router yet. Let's use it in the standalone mode to make it easy to reach it for sure.

![](https://github.com/knelasevero/home-server-infra/blob/main/md/images/photo_2022-02-24_16-45-53.jpg?raw=true)

First edit your connections, and make the wired connection on your laptop have a static ip in the 192.168.0.x range. Plug the switch to a power socket and connect your laptop to port 1 of the switch. Access the switch in the 192.168.0.1 in a browser (this will be different for different switches).

Login with default credentials (admin:admin), and change your password to something secure, ideally randomly generated by a password manager.

![](https://github.com/knelasevero/home-server-infra/blob/main/md/images/photo_2022-02-24_17-04-00.jpg?raw=true)

Navigate to  "VLAN" > "802.1Q VLAN", and enable "802.1Q VLAN" and apply. Type "10" in the VLAN ID (1-4094) field, and type "servers" in the VLAN Name field. Select Port 1 as tagged, and Ports 2-4 as Untagged. Hit apply.

Type "20" in the VLAN ID (1-4094) field, and type "personal" in the VLAN Name field. Select Port 1 as tagged, and Ports 5-8 as Untagged. Hit apply.

Port 1 needs to be a member of both VLANs, and it will be receiving tagged packages from the router (from the router to the switch). To make your switch know what to do with traffic coming into ports 2-8 (from servers to the switch), we need to configure PVID on the next screen.

![](https://github.com/knelasevero/home-server-infra/blob/main/md/images/image_2022-02-22_02-23-31.png?raw=true)

Navigate to "VLAN" > "802.1Q PVID". Let port one go to PVID 1. Ports 2-4 need to go to PVID 10, Ports 5-8 need to go to PVID 20.


---

<center>**NOTE**</center>
<center> You might want to create another VLAN with different tag for the tagged traffic (stop using default PVID 1), because of a known exploit called double tagging (<strong><u>[VLAN hopping](https://en.wikipedia.org/wiki/VLAN_hopping)</u></strong>). If the attacker gets access to one of your servers, and then creates a virtual interface in the range of the other VLAN, and start tagging packages with known tags, they can send packages to the other interface and nothing would be blocked by your firewall (This is a bit edge case, and optional, your choice). </center>

---

<br>
### Getting an IP on the right VLAN.

Connect igb2 (third port, next to LAN port on Pfsense) to port 1 of your smart switch, and turn it on connecting it to a power socket. If you didn't try rebooting everything (Pfsense included), it won't hurt you. Connect a laptop to one of the ports of your switch. If you connect to ports 2-4, you should get an IP inside the DHCP range that you defined for OTP1, so something in 10.120.10.x. If you connect the laptop to ports 5-8, you should get an IP in the range of 10.120.20.x. You should not be able to talk to anything on the other VLAN.

<br>

<a name="troubleshooting"></a>
## [8 - How to troubleshoot some problems](#troubleshooting)

<br>

![rebooting](https://github.com/knelasevero/home-server-infra/blob/main/md/images/helpdesk-have-you-tried-rebooting.jpg?raw=true)

While testing the tagging setup I went through from different configurations not understanding what was happening and why it was not working, multiple times, when it should. Tried tcpkilling stuff, forcing dhclient to reload stuff, or anything like that, but in the end the good'ol pressing the power buttons and waiting for it to come back was the problem solver.

You can, of course, use all the well known commands to debug each of the network layers, [from my tweet](https://twitter.com/canelasevero/status/1486363495138578438):

- NIC layer:

```
ip -br link show
```

- "Machine" layer:

```
ip neighbor show
```

- "IP" layer:

```
ip -br address show
ping http://example.com
traceroute http://example.com
ip route show
```

- "Socket" or "IP:Port" layer:

```
ss -putan
telnet 10.0.0.1 443
nc 10.0.0.2 -u 80
```


You can also use Package Capture in Pfsense. Navigate to "Diagnostics" > "Packet Capture", Choose OPT1 (or 2) in the interface dropdown, and leave the rest as is (or change something, if you want something specific). Press Start. Start messing around in a laptop connected to an interesting port in the switch, pinging, tracerouting, or anything that you want. Press stop on Pfsense, and you can check all the logs. This is basically a frontend for tcpdump.

Another utility from Pfsense that you might want to check to understand what is happening in case of trouble following this guid is the Firewall system logs. Navigate to "Status" > "System Logs", and there choose the Firewall tab. You can check any role being enforced and packages that are being dropped. Maybe you forgot to allow something.

<br>

<a name="wifi"></a>
## [9 - Wifi AP](#wifi)

<br>

Your network is pretty much setup to be usable up to this point. But you might have noticed that we did not configure any wifi connection so far. By the way, please disable wifi in your ISP modem, if you did not do it already, you don't want it there.

If you have Desktop PCs and laptops that would be connected via cable to your network, just plug them in any of the 5-8 ports of your switch already. But for your wifi devices we need to setup an Access Point. For this example lets setup an Unifi Nanohd from Ubiquiti (You can literally use any other wifi AP, any that serves your needs).

<br>
### Setting up the AP

Go to <strong><u>https://www.ui.com/download/unifi/unifi-nanohd</u></strong> and download the UniFi Network Application for your operating system. Install this software to your laptop. Connect you laptop to VLAN 20 while also connecting UniFi Nanohd to that VLAN (Let's say port 8 and port 7). Fire up the software and let it find the AP. Setup SSID password, and anything that you want, and that's it, you have wifi.


<br>

<a name="rules"></a>
## [10 - Restrictive rules](#rules)

<br>

Under construction! :)

<br>

<a name="suricata"></a>
## [11 - Suricata IDS/IPS](#suricata)


<br>

Under construction! :)

<br>

<a name="further"></a>
## [12 - Further improvements](#further)

<br>

Under construction! :)
