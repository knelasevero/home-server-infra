# How to build your home private Cloud

In this course I am goin to teach you how to build a simple home private Cloud with OpenNebula, KVM, Terraform, Nginx, Linux, and a VPN. We are going to also automate the creation of an HA k3s Kubernetes cluster in your private cloud. Even though this is more like a tutorial, I will be explaining some of the concepts that we may encounter along the way.

<br>

## Table of Contents

* [1 - Requirements](#reqs)
* [2 - Preparing your Spare Machine](#preparing)
* [3 - Connecting from our Personal Machine and installing requirements](#installing)
* [4 - Configuring Opennebula](#configone)
* [5 - Starting Opennebula](#startingone)
* [6 - Checking Opennebula](#checkingone)
* [7 - Checking Opennebula webapp (sunstone)](#checkingoneweb)
* [8 - Enable MFA](#mfa)
* [9 - Prepare Server for Opennebula/KVM](#kvm)
* [10 - Configure Bridge Network](#bridge)
* [11 - Getting official images](#image)
* [12 - Create your first VM](#vm)


<br>

<a name="reqs"></a>
## [1 - Requirements](#reqs)

* Some familiarity with Linux, running Linux commands, ssh and other introdutory Linux concepts
* A Spare Machine that you are going to use as a dedicated server (not your personal machine)
	* 4 GiB RAM
	* 20 GiB free space on disk
    * public IP address (FE-PublicIP)
	* privileged user access (root)
	* operating system already installed: Ubuntu 20.04 (just so we keep the same baseline for the course)
	* open ports: 22 (SSH), 80 (Sunstone), 2616 (FireEdge), 5030 (OneGate).
	* internet connection on this machine
* Your Personal Machine
    * It can be a Windows or a Linux machine. Preferable if it is a Linux machine since during the course I will show inputs and outputs from a Linux machine. The distribution doesn't matter.
    * Your personal machine needs to have ssh access to the spare machine
* You need to have access to your Modem/Router to be able to configure port forwarding (we are going to show how to do it)
* Even though we are going to bring up a Kubernetes cluster in the end, and configure some things on it, it will be more to showcase what you can do with the platform. So Kubernetes knowledge is not necessary. If you plan to use that cluster, of course, then it would be necessary.
* In the end we will also deploy an OpenVPN server. Only do this part if you are very familiar with Networking and security (but this is optional).
* One domain owned by you, if you want to have ssl external access to a service ran by you

<br>

<a name="preparing"></a>
## [2 - Preparing your Spare Machine (server)](#preparing)

If you did not yet, let's generate a ssh key pair on your Personal Machine. There are a lot of tutorials explaining how to do that. You can follow github's docs for that:

https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent

After you finish those steps, you can cat your public key and take note of it.

```
$ cat ~/.ssh/id_ed25519.pub

or

$ cat ~/.ssh/id_rsa.pub # if you used the legacy method
```

Now grab you Spare Machine (let's call it server, or home server from now on). Let's install OpenSSH Server on it:

```
$ sudo apt update
$ sudo apt install openssh-server
```

Make sure the sshd service is running and enabled, so it is up even if you reboot the server machine:

```
$ sudo systemctl start sshd.service
$ sudo systemctl enable sshd.service
```

And with the service running, we need now to allow our Personal Machine to ssh into our server. So, on the server, we create an authorized_keys file:

```
$ mkdir -p ~/.ssh
$ chmod 700 ~/.ssh
$ touch ~/.ssh/authorized_keys
$ chmod 600 ~/.ssh/authorized_keys
```

Let's grab this file and echo our public key to it (the one that we took note before):

```
$ echo "YOUR_PUBLIC_KEY_GOES_HERE" >> ~/.ssh/authorized_keys
```

Since your Home Server is meant to be just a sever, it also makes sense to disable Graphical user interface on it, to let it optimize the use of resources. You can read this article to know more about it: [disable-enable-gui-on-boot](https://linuxconfig.org/how-to-disable-enable-gui-on-boot-in-ubuntu-20-04-focal-fossa-linux-desktop), but you can just run these two commands and you will have GUI disabled:

```
$ sudo systemctl set-default multi-user
$ sudo reboot
```

To restart GUI at any time, just run:

```
$ sudo systemctl start gdm3
```

Also advisable to remove some unused packages, both to let your server be a bit more minimal, but also to avoid security problems:

```
$ sudo apt remove telnet cups
```

Just to be sure what user and ip you want to ssh to, from the Personal machine later, run:

```
$ whoami # and take note of the username
$ ip addr # and take note of the ip on the interface that connects your machine to the internet
```

If you don't know what is the interface and the ip that you need to take note, let's try to check a few things first:

If you are connected to the internet via wifi, in Ubuntu 20.04, the network interface will be named something similar to `wlpXs0`, changing the X by some number. If you are connected by cable, it will probably be named `eth0` or something similar to `enpXs0fX`. In any case, to see a list of network interfaces you can run:

```
$ ip link show

or

$ netstat -i
```

And to know your ip, check for one of those, holding a known private ip:

```
$ ip addr
```

The output of the above command for me is:

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp3s0f2: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc fq_codel state DOWN group default qlen 1000
    link/ether 00:90:f5:e3:e8:6f brd ff:ff:ff:ff:ff:ff
3: wlp4s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether a4:17:31:9e:f3:35 brd ff:ff:ff:ff:ff:ff
    inet 192.168.178.31/24 brd 192.168.178.255 scope global dynamic noprefixroute wlp4s0
       valid_lft 857292sec preferred_lft 857292sec
    inet6 2a04:4540:6526:7d00:cd24:cd67:f8fc:c885/64 scope global temporary dynamic 
       valid_lft 7037sec preferred_lft 3437sec
    inet6 2a04:4540:6526:7d00:87f9:80de:d39f:713/64 scope global dynamic mngtmpaddr noprefixroute 
       valid_lft 7037sec preferred_lft 3437sec
    inet6 fe80::89b3:4494:8ec:7d77/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
```

And with it I know I am connected to my home network via the wlp4s0 interface and with private ip 192.168.178.31.

<br>

<a name="installing"></a>
## [3 - Connecting from our Personal Machine and installing requirements](#installing)

Now we can leave our home server lying in a corner in your room, or maybe in your attic, and just use ssh to connect and run commands on it:

```
$ ssh YOUR_USERNAME_THAT_YOU_TOOK_NOTE@IP_THAT_YOU_TOOK_NOTE

in my case:

$ ssh myuser@192.168.178.31
```

If you have problems connecting to your home server, let me know.

Let's now use [Opennebula docs](https://docs.opennebula.io/6.0/installation_and_configuration/frontend_installation/install.html) to be able to install it on our server.

Let's import the repository key:

```
wget -q -O- https://downloads.opennebula.org/repo/repo.key | sudo apt-key add -
```

Add the repo to the system:

```
echo "deb https://downloads.opennebula.org/repo/6.1/Ubuntu/20.04 stable opennebula" | sudo tee /etc/apt/sources.list.d/opennebula.list
```

Install all the opennebula packages:

```
sudo apt-get -y install opennebula opennebula-sunstone opennebula-fireedge opennebula-gate opennebula-flow opennebula-provision
```

You may need to install a few packages that wre dependencies to opennebula packages. If you run above command and run into an error, check the missing dependency and install it. And example error could be:

```
Some packages could not be installed. This may mean that you have
requested an impossible situation or if you are using the unstable
distribution that some required packages have not yet been created
or been moved out of Incoming.
The following information may help to resolve the situation:

The following packages have unmet dependencies:
 opennebula-fireedge : Depends: libnode64
E: Unable to correct problems, you have held broken packages.
```

And then you would need to install it:

```
$ sudo apt install libnode64
```

You can skip the MariaDB step if you want to deploy OpenNebula as quickly as possible. I won't cover it here in this course.

<br>

<a name="configone"></a>
## [4 - Configuring Opennebula](#configone)

Login as the oneadmin user in the server:

```
sudo su oneadmin
```

Create your initial admin password by echoing it to a file (you can change this password later with the `oneuser passwd` command):

```
echo 'oneadmin:create_an_strong_pass_here' > /var/lib/one/.one/one_auth
```

Log out as oneadmin

```
$ exit
```

Change you FireEdge endpoint. For your private one, you can put localhost or your ip from the interface that connects you to your home network. For the public one (optional), You can add your domain later :

```
sudo sed -i "s|:private_fireedge_endpoint: [^ ]*|:private_fireedge_endpoint: http://localhost:2616|g" /etc/one/sunstone-server.conf

and

sudo sed -i "s|:public_fireedge_endpoint: [^ ]*|:public_fireedge_endpoint: http://localhost:2616|g" /etc/one/sunstone-server.conf
```

Configure OneGate host. Please change the ip bellow by your private ip on your home network:

```
sudo sed -i "s|:host: [^ ]*|:host: 0.0.0.0|g" /etc/one/onegate-server.conf

sudo sed -i "s|ONEGATE_ENDPOINT = [^ ]*|ONEGATE_ENDPOINT = \"http://PRIVATE_IP_ON_YOUR_INTERFACE:5030\"|g" /etc/one/oned.conf
```

Configure OneFlow:

```
sudo sed -i "s|:host: [^ ]*|:host: 0.0.0.0|g" /etc/one/oneflow-server.conf
```

<br>

<a name="startingone"></a>
## [5 - Starting Opennebula](#startingone)

You can start all the services with systemctl and wait a bit for everything to be up. You can also go ahead and enable all those services to start at boot time.

```
$ sudo systemctl start opennebula opennebula-sunstone opennebula-fireedge opennebula-gate opennebula-flow

$ sudo systemctl enable opennebula opennebula-sunstone opennebula-fireedge opennebula-gate opennebula-flow
```

<br>

<a name="checkingone"></a>
## [6 - Checking Opennebula](#checkingone)

```
$ sudo su oneadmin
$ oneuser show

Should have output like:

USER 0 INFORMATION
ID              : 0
NAME            : oneadmin
GROUP           : oneadmin
PASSWORD        : 3bc15c8aae3e4124dd409035f32ea2fd6835efc9
AUTH_DRIVER     : core
ENABLED         : Yes

USER TEMPLATE
TOKEN_PASSWORD="ec21d27e2fe4f9ed08a396cbd47b08b8e0a4ca3c"

RESOURCE USAGE & QUOTAS
```

Log out as oneadmin:

```
$ exit
```

<br>

<a name="checkingoneweb"></a>
## [7 - Checking Opennebula webapp (sunstone)](#checkingoneweb)

You can open the webapp in your preferred browser using the ip of your server:

![](https://images.squarespace-cdn.com/content/v1/5dd1513b4e72ce1d58bb3f9c/1639068411036-MPUFPNVLZVUENJQOFPDX/one1.png?format=1500w)

You can login with the password that you inserted in the [Configuring Opennebula](#configone) step.

<br>

<a name="mfa"></a>
## [8 - Enable MFA](#mfa)

This is a security best practice. At least you know that to have access to your system/oneaccount someone would need to also have access to your mobile device.

Go to `oneadmin` > `settings`. And in the `Auth` tab, enable MFA.

You will need to download an authenticator app. With that you can scan the QR code and register it. Then, at every login, you will need to provide the code from the app.

![](https://images.squarespace-cdn.com/content/v1/5dd1513b4e72ce1d58bb3f9c/1639069656125-BMH260GOJRWIVD4O84T4/one3.png?format=2500w)

<br>

<a name="kvm"></a>
## [9 - Prepare Server for Opennebula/KVM](#kvm)

Let's first install every package that is required to manage KVM VMs and their networking:

```
$ sudo apt install kvm qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst virt-manager
```

Ddetermine if this server is capable of running hardware accelerated KVM virtual machines:

```
kvm-ok
```

If you get a negative response, you will need to use another machine that supports this.

Now install opennebula-node for additional integration with KVM:

```
$ sudo apt-get install opennebula-node
```

<br>

---
<center>**NOTE**</center>

<center>I have automated most of what we have done so far using ansible in the following repository: [https://github.com/knelasevero/home-server-infra](https://github.com/knelasevero/home-server-infra).</center>

<center>If you are familiar with ansible, you might want to have a look and use it to avoid manual steps.</center>

---

<a name="bridge"></a>
## [10 - Configure Bridge Network](#bridge)

Before trying to create a Virtual Network on the GUI, let's have a look over what bridges were created by those kvm packages that we installed before. Have a look over what new interfaces appear when you run:

```
$ ip link show

or

$ netstat -i
```

By default, in Ubuntu 20.04, and latest versions of kvm and libvirt packages, a bridge network named virbr0 would have been created. We can use it to configure a new Virtual Network in Opennebula. If we run `ip addr` we can see that (if it does not clash with your home subnet) by default it assigns ips from  192.168.122.1 to 192.168.122.255 (192.168.122.0/24).

With that information, go to Virtual Networks.

![](https://images.squarespace-cdn.com/content/v1/5dd1513b4e72ce1d58bb3f9c/1639070576826-TGKZIKZ1WOJG3QRB4ACW/one4.png?format=2500w)

And create a new network. You can name it anything that you want. If you want inspiration, you can use `kmvbr0`.

In the Conf tab of the creation, paste the name of the bridge that was created by the packages that we installed before: `virbr0`, and choose Network mode `Bridged`.

![](https://images.squarespace-cdn.com/content/v1/5dd1513b4e72ce1d58bb3f9c/1639071252958-LLH88LN2GPK5CSRB3A96/one5.png?format=2500w)

In the Addresses tab of the creation, choose an first ip for your VMs that is within the range that we saw for `virbr0` before. You cannot choose the actual first one, since it will be assigned to the server itself on this interface. So, in my example, you can choose 192.168.122.2, set a size of 200.

![](https://images.squarespace-cdn.com/content/v1/5dd1513b4e72ce1d58bb3f9c/1639071558486-QENRPDWHMHYKP9YKC3K8/one6.png?format=2500w)

You can now go directly to the Context tab of the creation, and set the context for each VM. This context can only be applied to VMs that are created from images available in the opennebula marketplace (or in VMs that you prepare for that). Following my example, set Address to `192.168.122.0`, Network mask to `255.255.255.0`, Gateway to `192.168.122.1` (ip of the actual server, on this network, so VMs know where to find internet on a hop), DNS to `1.1.1.1 8.8.8.8` (these are space separeted values, DNS servers from Cloudflare and Google respectively).

![](https://images.squarespace-cdn.com/content/v1/5dd1513b4e72ce1d58bb3f9c/1639071858689-6OS5YX2J4DA8MSOABWJI/one8.png?format=2500w)

<br>

<a name="image"></a>
## [11 - Getting official images](#image)

To get official images you can simply go to `Storage` > `Apps`. Search for a Distro that you want, and click the little cloud with a down arrow button.

![](https://images.squarespace-cdn.com/content/v1/5dd1513b4e72ce1d58bb3f9c/1639072355696-15LVHX6ILP1EMYKVVGV4/one9.png?format=1500w)


<br>

<a name="vm"></a>
## [12 - Create your first VM](#vm)

Before we create our fisrt VM on our home private cloud, let's generate yet another ssh key, but now in the server. So we can use this key and, from the server, ssh into a VM.

[You can use the guide that we used before to generate it](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent). Just be careful to know which ssh key you are using, and in which VM you are running commands, at each time. 

With your ssh key in hands, go to `oneadmin` > `settings` and update the ssh key there. Be sure to do that for any user that you create in your setup.

![](https://images.squarespace-cdn.com/content/v1/5dd1513b4e72ce1d58bb3f9c/1639073423390-0P637PN80WZS80UMUS5N/one11.png?format=2500w)

Now go to `Instances` > `VMs`, and start creating your new VM. Choose the VM template that is in your list (this VM template is the default one that came together with the image that you downloaded). Configure the VM in any way you like, giving it a bit of RAM and CPU.

You have to add a Network Interface and choose the Virtual Network that we created before, `kmvbr0`. 

Click create and wait for it to be in state `RUNNING`.

You will have to wait a few minutes, if it is an image that is a bit heavier, even if it is in state `RUNNING`. But eventually you will be able to ssh to it! Check the VM IP on its details and ssh into it!

```
$ ssh root@VM_IP
```



<br>

<a name="next"></a>
## [13 - Next Steps](#next)

In the next steps we are going to:

- Configure OpenVPN to have remote access to our setup
- See how to use Opennebula custom provider to create VMs with IaC
- Configure Nginx as a forward proxy with ssl spread to get Public IP traffic into a VM
- Setup ddclient service to update our Domain even if we don't have a static IP
- Bring up a HA k3s Kubernetes Cluster and get an application running with ssl

https://knela.dev/homeprivatecloud2
