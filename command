#!/bin/bash
nmcli connection add type bond con-name bond0 ifname bond0 bond.options "mode=802.3ad,xmit_hash_policy=layer2+3,miimon=100"
nmcli connection modify bond0 ipv4.addresses '10.44.118.114/24'
nmcli connection modify bond0 ipv4.gateway '10.44.118.1'
nmcli connection modify bond0 ipv4.method manual
nmcli connection modify bond0 ipv6.method disabled
nmcli connection add type ethernet slave-type bond con-name ens1f0 ifname ens1f0 master bond0
nmcli connection add type ethernet slave-type bond con-name ens10f0 ifname ens10f0 master bond0
nmcli connection up ens1f0
nmcli connection up ens10f0
nmcli connection up bond0
nmcli connection add type bond con-name bond1 ifname bond1 bond.options "mode=802.3ad,xmit_hash_policy=layer2+3,miimon=100"
nmcli connection modify bond1 ipv4.addresses '10.46.120.19/24'
nmcli connection modify bond1 ipv4.gateway ''
nmcli connection modify bond1 ipv4.method manual
nmcli connection modify bond1 ipv6.method disabled
nmcli connection add type ethernet slave-type bond con-name ens1f1 ifname ens1f1 master bond1
nmcli connection add type ethernet slave-type bond con-name ens10f1 ifname ens10f1 master bond1
nmcli connection up ens1f1
nmcli connection up ens10f1
nmcli connection up bond1

route add -net 198.161.1.0 netmask 255.255.255.0 gw 192.168.206.1 eth0
ip route add 198.161.1.0/24 via 198.168.206.1 dev eth0

ipa-server-install --domain=nbf.local --realm=NBF.LOCAL --ds-password=redhat --admin-password=redhat --hostname=ipa.nbf.ae --ip-address=192.168.0.1 --reverse-zone=0.168.192.in-addr.arpa. --forwarder=172.16.21.21 --allow-zone-overlap --setup-dns --unattended

export HNAME="ipa.server.local"
hostnamectl set-hostname $HNAME --static
hostname $HNAME
https://infotechys.com/installing-and-using-freeipa-server-on-centos8/
https://www.techoism.com/steps-to-install-freeipa-server-on-centos-rhel-8/
https://computingforgeeks.com/how-to-install-and-configure-freeipa-server-on-rhel-centos-8/
https://access.redhat.com/solutions/2259961
https://access.redhat.com/discussions/3945091
https://access.redhat.com/solutions/1182373
https://access.redhat.com/solutions/3578631
https://access.redhat.com/solutions/3380881
https://access.redhat.com/solutions/802003
https://access.redhat.com/solutions/2259961


On both the nodes
dnf -y install pacemaker pcs fence-agents-all

systemctl enable pcsd
systemctl start  pcsd

echo "redhat" | passwd --stdin hacluster
pcs host auth node1 node2
pcs cluster setup nfscluster node1 node2

On 1st node1

pcs cluster start --all
pcs cluster enable --all
pcs cluster status

Set Fence Device on Cluster 
Using RHV 
pcs stonith create rhv-m fence_rhevm ipaddr=172.16.50.81 login='admin@internal' passwd='Root@321' ssl=1 ssl_insecure=1 disable_http_filter=1 pcmk_host_map="drapn1.nbf.ae:DRAPN1;drapn2.nbf.ae:DRAPN2;drapn3.nbf.ae:DRAPN3" power_timeout=30 shell_timeout=30 login_timeout=30
On both the nodes
vi /etc/lvm/lvm.conf
# line 1217: change
system_id_source = "uname"

On 1st node1
parted --script /dev/sdb "mklabel msdos"
parted --script /dev/sdb "mkpart primary 0% 100%"
parted --script /dev/sdb "set 1 lvm on"

pvcreate /dev/sdb1
vgcreate vg_ha /dev/sdb1
vgs -o+systemid
lvcreate -l 100%FREE -n lv_ha vg_ha
mkfs.ext4 /dev/vg_ha/lv_ha
vgchange vg_ha -an
lvm pvscan --cache --activate ay
pcs resource create lvm_ha ocf:heartbeat:LVM-activate vgname=vg_ha vg_access_mode=system_id --group ha_group

On both the nodes
mkdir /nfs-share
pcs resource create nfs_share ocf:heartbeat:Filesystem device=/dev/vg_ha/lv_ha directory=/nfs-share fstype=ext4 --group ha_group
pcs resource create nfs_daemon ocf:heartbeat:nfsserver nfs_shared_infodir=/nfs-share/nfsinfo nfs_no_notify=true --group ha_group
pcs resource create nfs_vip ocf:heartbeat:IPaddr2 ip=192.168.122.100 cidr_netmask=24 --group ha_group
pcs resource create nfs_notify ocf:heartbeat:nfsnotify source_host=192.168.122.100 --group ha_group

mkdir -p /nfs-share/nfs-root/share01
pcs resource create nfs_root ocf:heartbeat:exportfs clientspec=192.168.122.0/255.255.255.0 options=rw,sync,no_root_squash directory=/nfs-share/nfs-root fsid=0 --group ha_group
pcs resource create nfs_share01 ocf:heartbeat:exportfs clientspec=192.168.122.0/255.255.255.0 options=rw,sync,no_root_squash directory=/nfs-share/nfs-root/share01 fsid=1 --group ha_group

showmount -e

On client
mount -t nfs4 192.168.122.100:share01 /mnt
mount -t nfs 1192.168.122.100:/home/nfs-share/nfs-root/share01 /mnt

ethtool -i eth0
lshw -class network
lspci | grep -i 'ethernet'
lshw -short -c network
The server has 4 Ethernet links to a layer 3 switch with names:

for i in enp3s0f0 enp3s0f1 enp4s0f0 enp4s0f1; do echo $i; ethtool $i|grep -i "Link detected";done

enp3s0f0, enp3s0f1, enp4s0f0, enp4s0f1

There are two bond interfaces both configured as active-backup

bond0, bond1

enp4s0f0 and enp4s0f1 interfaces are bonded as bond0. Bond0 is for making ssh connections and management only so corresponding switch ports are not configured in trunk mode.

enp3s0f0 and enp3s0f1 interfaces are bonded as bond1. Bond1 is for data and corresponding switch ports are configured in trunk mode.

Bond0 is the default gateway for the server and has IP address 10.1.10.11

Bond1 has three subinterfaces with VLAN 4, 36, 41. IP addresses are 10.1.3.11, 10.1.35.11, 10.1.40.11 respectively.

Proper communication with other servers on the network we should use routing tables. There are three rt_tables. Each of them is dedicated to a subinterface. Gateways for each VLAN are 10.1.10.254, 10.1.3.254, 10.1.35.254, 10.1.40.254 respectively.

Now I can show how slave interface files are configured:

$ cat /etc/sysconfig/network-scripts/ifcfg-enp4s0f0
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
DEFROUTE=no
IPV4_FAILURE_FATAL=no
IPV6INIT=no
IPV6_AUTOCONF=no
IPV6_DEFROUTE=no
IPV6_FAILURE_FATAL=no
NAME=enp4s0f0
DEVICE=enp4s0f0
ONBOOT=yes
MASTER=bond0
SLAVE=yes

$ cat /etc/sysconfig/network-scripts/ifcfg-enp4s0f1
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
DEFROUTE=no
IPV4_FAILURE_FATAL=no
IPV6INIT=no
IPV6_AUTOCONF=no
IPV6_DEFROUTE=no
IPV6_FAILURE_FATAL=no
NAME=enp4s0f1
DEVICE=enp4s0f1
ONBOOT=yes
MASTER=bond0
SLAVE=yes

$ cat /etc/sysconfig/network-scripts/ifcfg-enp3s0f0
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
DEFROUTE=no
IPV4_FAILURE_FATAL=no
IPV6INIT=no
IPV6_AUTOCONF=no
IPV6_DEFROUTE=no
IPV6_FAILURE_FATAL=no
NAME=enp3s0f0
DEVICE=enp3s0f0
ONBOOT=yes
MASTER=bond1
SLAVE=yes

$ cat /etc/sysconfig/network-scripts/ifcfg-enp3s0f1
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
DEFROUTE=no
IPV4_FAILURE_FATAL=no
IPV6INIT=no
IPV6_AUTOCONF=no
IPV6_DEFROUTE=no
IPV6_FAILURE_FATAL=no
NAME=enp3s0f1
DEVICE=enp3s0f1
ONBOOT=yes
MASTER=bond1
SLAVE=yes

Master interfaces:

$ cat /etc/sysconfig/network-scripts/ifcfg-bond0
DEVICE=bond0
NAME=bond0
BONDING_MASTER=yes
BONDING_OPTS="miimon=100 mode=1 primary=enp4s0f1"
ONBOOT=yes
BOOTPROTO=none
NM_CONTROLLED=no
IPADDR=10.1.10.11
NETMASK=255.255.255.0
NETWORK=10.1.10.0

$ cat /etc/sysconfig/network-scripts/ifcfg-bond1
DEVICE=bond1
NAME=bond1
BONDING_MASTER=yes
BONDING_OPTS="miimon=100 mode=1 primary=enp3s0f1"
ONBOOT=yes
BOOTPROTO=none

Subinterfaces for bond1:

$ cat /etc/sysconfig/network-scripts/ifcfg-bond1.4
DEVICE=bond1.4
VLAN=yes
ONBOOT=yes
BOOTPROTO=none
NM_CONTROLLED=no
IPADDR=10.1.3.11
NETMASK=255.255.255.0
NETWORK=10.1.3.0

$ cat /etc/sysconfig/network-scripts/ifcfg-bond1.36
DEVICE=bond1.36
VLAN=yes
ONBOOT=yes
BOOTPROTO=none
NM_CONTROLLED=no
IPADDR=10.1.35.11
NETMASK=255.255.255.0
NETWORK=10.1.35.0

$ cat /etc/sysconfig/network-scripts/ifcfg-bond1.41
DEVICE=bond1.41
VLAN=yes
ONBOOT=yes
BOOTPROTO=none
NM_CONTROLLED=no
IPADDR=10.1.40.11
NETMASK=255.255.255.0
NETWORK=10.1.40.0

Bonding module aliases should not be forgotten:

$ cat /etc/modprobe.d/bonding.conf
alias bond0 bonding
alias bond1 bonding

Now comes the routing:

$ cat /etc/iproute2/rt_tables
...
...
1 bond0
2 bond1.4
3 bond1.36
4 bond1.41

As I mentioned earlier bond0 is the default GW:

$ cat /etc/sysconfig/network
GATEWAY=10.1.10.254

Route scripts:

$ cat /etc/sysconfig/network-scripts/route-bond0
10.1.10.0/24 dev bond0 src 10.1.10.11 table bond0
default via 10.1.10.254 dev bond0 table bond0

$ cat /etc/sysconfig/network-scripts/route-bond1.4
10.1.3.0/24 dev bond1.4 src 10.1.3.11 table bond1.4
default via 10.1.3.254 dev bond1.4 table bond1.4

$ cat /etc/sysconfig/network-scripts/route-bond1.36
10.1.35.0/24 dev bond1.36 src 10.1.35.11 table bond1.36
default via 10.1.35.254 dev bond1.36 table bond1.36

$ cat /etc/sysconfig/network-scripts/route-bond1.41
10.1.40.0/24 dev bond1.41 src 10.1.40.11 table bond1.41
default via 10.1.40.254 dev bond1.41 table bond1.41

IPRoute Rule scripts:

$ cat /etc/sysconfig/network-scripts/rule-bond0
from 10.1.10.11/32 table bond0
to 10.1.10.11/32 table bond0

$ cat /etc/sysconfig/network-scripts/rule-bond1.4
from 10.1.3.11/32 table bond1.4
to 10.1.3.11/32 table bond1.4

$ cat /etc/sysconfig/network-scripts/rule-bond1.36
from 10.1.35.11/32 table bond1.36
to 10.1.35.11/32 table bond1.36

$ cat /etc/sysconfig/network-scripts/rule-bond1.41
from 10.1.40.11/32 table bond1.41
to 10.1.40.11/32 table bond1.41

When the Linux host boots up clearly, route and rule scripts are executed. They should look like this:

$ ip route show table all
default via 10.1.10.254 dev bond0 table bond0
10.1.10.0/24 dev bond0 table bond0 scope link src 10.1.10.11
default via 10.1.3.254 dev bond1.4 table bond1.4
10.1.3.0/24 dev bond1.4 table bond1.4 scope link src 10.1.3.11
default via 10.1.35.254 dev bond1.36 table bond1.36
10.1.35.0/24 dev bond1.36 table bond1.36 scope link src 10.1.35.11
default via 10.1.40.254 dev bond1.41 table bond1.41
10.1.40.0/24 dev bond1.41 table bond1.41 scope link src 10.1.40.11
default via 10.1.10.254 dev bond0
10.1.3.0/24 dev bond1.4 proto kernel scope link src 10.1.3.11
10.1.10.0/24 dev bond0 proto kernel scope link src 10.1.10.11
10.1.35.0/24 dev bond1.36 proto kernel scope link src 10.1.35.11
10.1.40.0/24 dev bond1.41 proto kernel scope link src 10.1.40.11
169.254.0.0/16 dev bond0 scope link metric 1006
169.254.0.0/16 dev bond1 scope link metric 1007
169.254.0.0/16 dev bond1.36 scope link metric 1008
169.254.0.0/16 dev bond1.4 scope link metric 1009
169.254.0.0/16 dev bond1.41 scope link metric 1010

$ ip rule show
0: from all lookup local
32758: from all to 10.1.40.11 lookup bond1.41
32759: from 10.1.40.11 lookup bond1.41
32760: from all to 10.1.3.11 lookup bond1.4
32761: from 10.1.3.11 lookup bond1.4
32762: from all to 10.1.35.11 lookup bond1.36
32763: from 10.1.35.11 lookup bond1.36
32764: from all to 10.1.10.11 lookup bond0
32765: from 10.1.10.11 lookup bond0
32766: from all lookup main
32767: from all lookup default


I hope, this article is useful and you enjoy it.
