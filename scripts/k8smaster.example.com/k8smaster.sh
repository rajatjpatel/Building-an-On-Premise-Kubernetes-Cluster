#!/bin/bash

hostnamectl set-hostname k8smaster.exmaple.com
echo "vagrant:vagrant" | chpasswd
echo "root:centos" | chpasswd

sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sed -i "\$ a $1 192.168.100.8\t\t$NEW_HOST k8smaster.example.com\t$NEW_HOST" /etc/hosts
sed -i "\$ a $1 192.168.122.9\t\t$NEW_HOST node01.example.com\t$NEW_HOST" /etc/hosts
sed -i "\$ a $1 192.168.122.10\t\t$NEW_HOST node02.example.com\t$NEW_HOST" /etc/hosts

systemctl restart sshd
rpm --import http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7
rpm -ivh http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm
yum -y install docker
systemctl enable docker
systemctl restart docker

cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF

setenforce 0

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable kubelet && systemctl start kubelet

systemctl disable firewalld

reboot
