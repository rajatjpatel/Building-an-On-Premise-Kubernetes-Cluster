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
