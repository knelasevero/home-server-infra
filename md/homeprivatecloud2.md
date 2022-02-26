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

* [1 - OpenVPN config](#vpnconfig)
* [2 - Terraforming Opennebula](#terraform)

<br>

<a name="vpnconfig"></a>
## [1 - OpenVPN config](#vpnconfig)

<br>

Be very carefull with this step. Avoid doing it if you don't need remote access or if it would be infrequent. Try to isolate the network where VPN clients will jump in. Do this part at your own risk, and never share VPN client cert files with people that should not have them.

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

Before we can start a VPN connection we need to portforward a port on the modem/router to your port on the Server. To do that first find the IP of your gateway in the Server on the wifi or cabled interface (whichever gives you internet). **If you followed the [Home private network](https://knela.dev/homeprivatenetwork) guide, this will of course be different. And you would need to port forward on both your modem and your Pfsense router. If you did not follow that guide yet, you can just go forward here.**

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

When it says Succeeded, try to ping your Server, and try to ping your VMs. Everything should be reachable. If you cannot reach your opennebula VMs from your Personal Machine, it is not a big deal, since we are going to configure the host server as a bastion hop in a bit. You should, of course, be able to reach your Host Server and ssh to it now, while on VPN. If you can't, you need to debug it.

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

<br>

<a name="terraform"></a>
## [2 - Terraforming Opennebula](#terraform)

<br>

Opennebula is not the biggest hit when you look for terraform providers. There were a few, made by individual contributors, but now you can find one provider in their official repository. It is still in early stages, but it is actively maintained, and it works well.

<br>
### Requirements for running terraform on our opennebula

Let's list some assumptions here to start:

- You are going to need a bit of terraform knowledge here, but just to understand what we have written already, and how to change it.
- You need terraform (1.1.4) and ansible (2.12) installed.
- You need to have gone through all the steps from the previous guide, where we added some images and had a Virtual Network created on Opennebula.
- You need to create a user with enough rights for terraform to use.
- You of course need to be with your VPN connected or have your Server reachable somehow.

Before starting, you can find the markdown code that generates this post and all the other relevant code at [knelasevero/home-server-infra](https://github.com/knelasevero/home-server-infra). Please clone the repo and have it handy.

<br>
### Let's avoid using IPs

If you are using Pfsense, and you are also using it to resolve you LAN DNS (from the private network guide that I mentioned before), you can already create an entry in it for your Server. If you are not, simply add some entries in your /etc/hosts file:

```
echo "IP_OF_YOUR_SERVER homeinfra" >> /etc/hosts
echo "IP_OF_YOUR_SERVER opnb.homeinfra" >> /etc/hosts
echo "192.168.122.2 control.opnb.homeinfra" >> /etc/hosts
```

<br>
### Configuring ssh hop with ssh config

There is a file in the repository that you can use to configure your ssh to set your Server as the bastion to ssh to your created VMs. We use a ProxyCommand to ssh from your Personal Machine to a created VM, hopping first to your Server. Here is the [config.cfg](https://github.com/knelasevero/home-server-infra/blob/main/ansible_k3s/config.cfg) file contents:

```
Host opnb.homeinfra
  Hostname opnb.homeinfra
  Port 22
  User YOURUSER

Host control.opnb.homeinfra
  Hostname 192.168.122.2
  User root
  ProxyCommand ssh opnb.homeinfra -W %h:%p

Host node1.opnb.homeinfra
  Hostname 192.168.122.3
  User root
  ProxyCommand ssh opnb.homeinfra -W %h:%p

Host node2.opnb.homeinfra
  Hostname 192.168.122.4
  User root
  ProxyCommand ssh opnb.homeinfra -W %h:%p
```

If you are login into the Server with another user, different from the user that you have on your Personal Machine, you have to set it there for the opnb.homeinfra connection. To use it natively, simply copy it to the .ssh folder:

```
cp ansible_kes/config.cfg ~/.ssh/config
chmod 600 ~/.ssh/config
```

With the file at the right place your can now already use it to ssh to your server using it:

```
ssh opnb.homeinfra
```

<br>
### Walkthrough the Terraform code

If you cloned the [repo](https://github.com/knelasevero/home-server-infra) You will notice that we have a `terraform` folder there. Inside it we have a very basic structure. A modules folder, where we only have a module defining how to create a Opennebula VM instance, and our `main.tf` entrypoint calling that module.

We also have our `variables.tf` files both for the main entrypoint and for the module. Some variables are being overwritten from above, and some are left as null on purpose, so we can pass them as environment variables or as inputs in the terminal.

Please change `main.tf` to what makes sense to you, but right now it tries to create the following VMs on Opennebula:

Control Plane node:
```
  cpu = 2
  vcpu = 2
  memory = 7168 (7GB)
  ip = "192.168.122.2"
```

Follower node1:
```
  cpu = 1
  vcpu = 1
  memory = 4096 (4GB)
  ip = "192.168.122.3"
```

Follower node2:
```
  cpu = 1
  vcpu = 1
  memory = 4096 (4GB)
  ip = "192.168.122.4"
```

We are fixing these IPs to make it easier to make them see themselves and when we add Kubernetes to them, to make it easy for them to know who is the control plane node. Before applying this terraform code, you want to do some preparation first.

Open variables.tf, and add you ssh public key where you can see mine. Since you also added opnb.homeinfra entry to your dns resolution file (or server), you should be fine regarding that. If you did not, you should add the IP of your server on those places mentioning opnb.homeinfra.

Since you enabled MFA for your user, you cant use it here for terraform to apply resources. You will have to create another use on Opennebula that does not have MFA enabled. Be careful with that user, and don't share its credentials.

While inside the terraform folder, run terraform init to download providers and do the initial setup:
```
terraform init -upgrade
```

Now you can decide if you want terraform to ask you for Opennebula every time or if you want to export them to be apple apply or destroy terraform without it asking you for them. If you want to export them, just do it like this:

```
export TF_VAR_one_username=NAME_OF_THE_USER_THAT_YOU_CREATED_FOR_THIS
export TF_VAR_one_password=THIS_USER'S_PASSWORD
```

With that out of the way, you can apply terraform (type `yes` when it asks you):

```
terraform apply
```

And when it is done, you should have VMs created in your Opennebula web console.