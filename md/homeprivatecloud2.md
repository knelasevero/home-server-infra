*Previous part: https://knela.dev/homeprivatecloud*

# Private Cloud Remote access, IAC and configs

As we listed before, we will cover the follwing topics here:

- Configure OpenVPN to have remote access to our setup
- See how to use Opennebula custom provider to create VMs with IaC
- Configure Nginx as a forward proxy with ssl spread to get Public IP traffic into a VM
- Setup ddclient service to update our Domain even if we don't have a static IP
- Bring up a HA k3s Kubernetes Cluster and get an application running with ssl

<br>

## Table of contents

[1 - OpenVPN config](#vpnconfig)

<br>

<a name="vpnconfig"></a>
## [1 - OpenVPN config](#vpnconfig)

Be very carefull with this step. Avoid doing it if you don't need remote access or if it would be very not frequent. Try to isolate the network where VPN clients will jump in. Do this part at your own risk, and never share VPN client cert files with people that should not have them.

---
<center>**NOTE**</center>
<center> (Optional) If you already want to take a look at how to make this secure, and a tiny bit more professional, please have a look at this other guide that I am building together with [@jufajardini](https://twitter.com/jufajardini) and [@gusfcarvalho](https://twitter.com/gusfcarvalho): </center>

<center><strong><u>[How to build a simple but good home network with multiple VLANs](https://knela.dev/homeprivatenetwork)</u></strong></center>

---



For the sake of simplicity I like to use the Road Warrior VPN script provided at [Nyr/openvpn-install](https://github.com/Nyr/openvpn-install). Please do not use it blindly and read the code before running it. If you are not familiar with shell/bash scripts, ask someone that you know to review it. After doing that, we can download and run it:

```
$ wget https://github.com/Nyr/openvpn-install/blob/master/openvpn-install.sh
$ chmod a+x openvpn-install.sh
$ sudo ./openvpn-install.sh
```

You can choose most of the default options, but for the port, choose something different. In some cases the VPN port will be by default blocked in your router/modem, so you can choose a different one here and take not of it to portforward later. Choose any DNS resolvers of your preference. If you are not sure which to chosse, go with `1.1.1.1`. The final field will ask your for the first client name, and you can choose whatever you like.

Before we can start a VPN connection we need to portforward a port on the modem/router to your port on the Server. To do that first find the IP of your gateway in the Server on the wifi or cabled interface (whichever gives you internet).

```
$ ip route | grep default
```

Access this in your Browser and look for a manual online on how to port forward the router port to your server port (For example, if you use Sagecom [Forward Ports on the Sagemcom 3764 Router](https://portforward.com/sagemcom/3764/)).

The first client vpn config file is place in `/root/chosen_name.ovpn` in your Server. Just cat it, copy its contents, exit the server connection, and paste it into a new file in you Personal Machine.

Install openvpn in your Personal Machine:

```
$ sudo apt install openvpn
```

With that out of the way, we can test our VPN connection. While not on your home network (mobile data, or really at a friends place), use openvpn with the config file that we created before on you Personal Machine:

```
sudo openvpn --config chosen_name.ovpn
```

When it says Succeded, try to ping your Server, and try to ping your VMs. Everything should be reachable.

If you have trouble with DNS resolutions and internet, edit /etc/resolv.conf on your Personal Machine and add as the first line `nameserver 8.8.8.8` (or `nameserver 1.1.1.1`).

If you need a new client file to hand out to someone working in a project in you shared server, simply go to the server and run the Road Warrior OpenVPN script again. It will generate another client configuration file with different certificates for you to hand over to a **VERY** trusted person.

To monitor connections to your cluster you can egrep fro "VPN" and "Data Channel" on your server's `/var/log/syslog`.

```
$ sudo egrep "VPN" /var/log/syslog
Dec 1 17:38:41 yourhost systemd[1]: Stopped OpenVPN service.
Dec 1 17:38:41 yourhost systemd[1]: Stopping OpenVPN service...
Dec 1 17:38:41 yourhost systemd[1]: Starting OpenVPN service...
Dec 1 17:38:41 yourhost systemd[1]: Finished OpenVPN service.
```

```
$ sudo egrep "Data Channel" /var/log/syslog
Dec 19 17:37:19 yourhost openvpn[1629]: EXTERNALIP:PORT Data Channel MTU parms [ L:XXXX D:XXXX EF:XXX EB:XXX ET:X EL:X ]
Dec 19 17:37:20 yourhost openvpn[1629]: personal_host/EXTERNALIP:PORT Data Channel: using negotiated cipher 'XXXXXXX'
Dec 19 17:37:20 yourhost openvpn[1629]: personal_host/EXTERNALIP:PORT Data Channel MTU parms [ L:XXX D:XXX EF:XX EB:XXX ET:X EL:X ]
Dec 19 17:37:20 yourhost openvpn[1629]: personal_host/EXTERNALIP:PORT Outgoing Data Channel: Cipher 'XXXXXXX' initialized with XXX bit key
Dec 19 17:37:20 yourhost openvpn[1629]: personal_host/EXTERNALIP:PORT Incoming Data Channel: Cipher 'XXXXXXX' initialized with XXX bit key
```
