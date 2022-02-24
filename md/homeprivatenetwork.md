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
* [9 - Mitigate double tagging vulnerability](#vuln)
* [10 - Wifi AP](#wifi)
* [11 - Restrictive rules](#rules)
* [12 - Suricata IDS/IPS](#rules)
* [13 - Further improvements](#further)

<br>

<a name="reqs"></a>
## [1 - Requirements](#reqs)

<br>

* Some familiarity with Linux, running Linux commands, ssh and other introductory Linux concepts
* Some familiarity with networking, and its components (You will leanr a bunch here as well).
* Some familiarity with Linux networking (You will learn a bunch here as well).
* Your Personal Machine
    * It can be a Windows or a Linux machine. Preferable if it is a Linux machine since during the course I will show inputs and outputs from a Linux machine. It does not matter the distribution.
    * This machine needs to have a ethernet socket (CAT 6 - simple internet cable thingy). If your laptop does not have it, you can buy an ethernet to USB adapter.
* A VLAN aware router/firewall. More specifically for our examples, a hardware appliance were we can install Pfsense.
* A VLAN aware switch (smart switch).
* At least 6 ethernet cables, of various lengths, depending of how you mount everything.
* A Wifi Access Point.
* Your ISP modem/router (We can maybe get rid of it, we will talk about that).
    

Being a bit more specific about the hardware that we will be using as an example:

* For the Pfsense compatible appliance, you can use any Netgate routers, Protectli Vault routers or similar. For this example we will be using a Protectli Vault 6, which can be a bit expensive, but you can follow same steps with Netgate cheaper hardware.
* We will be using a TP-Link TL-SG108E smart switch. You can use any smart switch capable of dealing with 802.1Q VLANs.
* For the wifi Access point, you can use any available. I will be just showing the simple steps with the Unifi nanohd from Ubiquiti.

<br>

<a name="wherepfsense"></a>
## [2 - Pfsense appliance options for your house](#wherepfsense)

<br>

### First option Protectli Vault

This is the option that I am using for this demo. It is very powerful, and you can easily change/replace components on it like in a laptop or PC. Some versions of it come without storage or RAM, and you are expected to install those yourself. Protectli Vault 6 comes with 6 ports, intel **i** series processors, and you are supposed to install a mSATA SSD and RAM on it. You can go up to 64 GB of RAM with 2 DDR4 16GB RAM units. You can also put less than that. This is a router that, in all reality, you can use as a PC, if you some reason need that. It has HDMI output and multiple USBs sockets.

Link: https://eu.protectli.com/products/

### Netgate

The advantage of going with Netgate and using Pfsense, is the fact that they are the company helping maintain the community and enterprise edition of the software. They have really interesting options for appliances, some even allowing you to just put your fiber cable directly on the router and completely throw away your ISP's modem (Not all ISPs would be happy with that, byt the way - in Brazil they even artificially jam your signal if you do that). The other advantage of going with Netgate is that they provide some very interesting cheap options, like the Netgate 1100, for $189. They even provide hardware that already comes with Pfsense installed, which would make you skip some steps in this course.

Link for the products that already come with Pfsense: https://www.netgate.com/pfsense-plus-software/how-to-buy#appliances

### Other options

Simply search for Pfsense on any e-commerce website, and you will get back some other options that will let you install Pfsense on them. It is as simple as that, and you can decide based on what you plan to do at your home. If you don't have heavy load planned, maybe going for something less powerful could be interesting to you. 

<br>

<a name="preparingpfsense"></a>
## [3 - Preparing pfsense](#preparingpfsense)

<br>

If you have one of the hardware appliances that comes clean, with no operating system, the first thing we have to do is install Pfsense on it.

### Downloading Pfsense

Let's go to the [official download page](https://www.pfsense.org/download/) and fill the form according to our preference. For Protectli Vault, since we have HDMI output, you would fill this fields as:

* Version: choose the latest
* Architecture: AMD64
* Installer: USB Memstick Installer
* Console: VGA
* Mirror: Anything that is closer to you for faster download

### Creating bootable USB Stick

If you are on Windows, you can use Rufus for writing the image to the stick. If you are on Linux/Mac, you can use anything that you want, like dd, or something like [balenaetcher](https://www.balena.io/etcher/). Simply write that image file that you downloaded to the USB stick that you want to use as bootable device.

### Installing Pfsense to the Appliance

For Protectli Vault, you can now plug a keyboard and the USB stick to any of its USB ports. Turn it on while being plugged to the power socket. If it beeps 4 times (initial turn on beep and 3 different beeps) and gives you no video output, you probably forgot to install an SSD and RAM memory units (Or you did not realize that this appliance comes without them 😅).

For installation steps, you can go simple with:

* Accept copyright notice
* Install
* Default Keymap
* Auto ZFS
* Install
* Stripe
* Then choose The appliance SSD from the list (select with space bar, enter to continue)
* Last chance warning, just accept it

It should be finished pretty quickly.


### Booting it up

Unplug your keyboard and USB stick, and reboot the device. It will boot up and sing for you. It you print its IP to the HDMI output monitor, and now you can use it to login to it.

![IP on screen](https://github.com/knelasevero/home-server-infra/blob/main/md/images/photo_2022-02-24_13-25-08.jpg?raw=true)

### Plugin it in

Plug the internet cable, coming from your modem in the WAN port of the appliance, and plug the LAN port to you laptop. If you did not configure your ISP's modem to stay in bridge modem, it will just assign a private IP to your Pfsense router. If you managed to do that before, your Pfsense will get a public IP assigned by your ISP. For some modems you need to leave ISP account details wrong on purpose, or similar strategies, while also enabling PPPoE passthrough. Then you would have to configure PPPoE credentials on your Pfsense.

You can completely ignore above paragraph if you just want to let Pfsense get a private IP and if you don't mind configuring port forwarding on both your modem and router.

<br>

<a name="pfsensesetup"></a>
## [4 - Pfsense setup](#pfsensesetup)


<br>

Let's type that ip address that we took note before in our web browser and access Pfsense admin console. Accept the insecure notice, since the connection is not behind ssl (which you can fix, but wont be covered here), and login with default credentials for now:

![login screen](https://github.com/knelasevero/home-server-infra/blob/main/md/images/photo_2022-02-24_13-49-33.jpg?raw=true)

* Usename: admin
* Pass: pfsense

![wizard1](https://github.com/knelasevero/home-server-infra/blob/main/md/images/image_2022-02-24_15-07-39.png?raw=true)

Go over the wizard configuration. Click next on the welcome notice. Click next on the Netfate support notice. Use any hostname that you want. Set DNS servers that you like, maybe 1.1.1.1 for primary and 8.8.8.8 for secondary. Uncheck override DNS. Click next.

At the WAN configuration, If you managed to put your modem in bridge passthrough mode, you will need to fill credentials here (not covering this, since this can vary a lot). If not, leave everything as is, and **uncheck** block private networks from entering via WAN, since your modem will give your Pfsense a private IP. Keep the block bogon option checked.

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

Before starting talking about VLANS I want to sit down a bit and talk about the simple network topology that we want to create in our home. Looking at it you can adapt to anything that makes sense to you, but this one is the generic "Servers and Personal stuff don't mix up" design.

So this is what we are trying to do:

![vlan topology](https://github.com/knelasevero/home-server-infra/blob/main/md/images/photo_2022-02-24_14-35-58.jpg?raw=true)

Very simple, modem to firewall/router, then to smart switch, and then separating into 2 VLANs. VLAN 1 (or more semantically, VLAN 10, so we start thinking about those VLAN IDs and IP ranges) will host our servers, where we plan to run web services or anything that is not personal. And VLAN 20 hosts our WIFI Access Point, which provides internet and connectivity to our personal devices. If an attacker reaches out your personal devices, your are making it a bit more difficult for them to attack you servers (pretty hard). Same thing if the attacker reaches out your servers, they would not easily jump to your personal devices, and you are reducing the blast radios.

Let's get right to it then.

### Setting VLANs up in Pfsense

Go to "Interfaces" > "Assignments", in the admin console. Click the VLAN tab. Click the Add button.

![vlan 10](https://github.com/knelasevero/home-server-infra/blob/main/md/images/image_2022-02-24_16-12-22.png?raw=true)

Create a new VLAN that you want to use the port igb2 (WAN is igb0, LAN is igb1). We want another port (igb2), that is not the LAN port, since in the LAN port we want to leave the admin console available, but that is not true for anything else. We assigned the VLAN tag 10 here, and this is what our smart switch will later use to know what is owned by one VLAN of the other. Click Save.

![vlan 20](https://github.com/knelasevero/home-server-infra/blob/main/md/images/image_2022-02-24_16-07-22.png?raw=true)

Do the same for your VLAN 20, write descriptions that make sense to you.

### Assign the VLANs to interfaces

![VLANs created](https://github.com/knelasevero/home-server-infra/blob/main/md/images/image_2022-02-24_16-19-32.png?raw=true)

Navigate to "Interfaces" > "Assignments", in the admin console. Click the "Interface Assignments" tab. Click the last dropdown, next to the Add button. Select the "VLAN 10 on igb2" option. Click Add. Do the same for VLAN 20.

Congrats, you have VLANs configured, but we still need to enable them, let them do dhcp, and set firewall rules for them.

### Enabling and configuring VLANs

![Enable Vlan 10](https://github.com/knelasevero/home-server-infra/blob/main/md/images/image_2022-02-24_16-25-54.png?raw=true)

Navigate to "Interfaces" > "Assignments", and click OTP1 interface. Let's enable it and assign a static ip to it. 

![Enable Vlan 20](https://github.com/knelasevero/home-server-infra/blob/main/md/images/image_2022-02-24_16-25-54.png?raw=true)

Do the same for OTP2.