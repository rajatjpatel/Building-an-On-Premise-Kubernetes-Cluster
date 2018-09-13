# Building-an-On-Premise-Kubernetes-Cluster
Building an On-Premise Kubernetes Cluster
While preparing the CKA exam, I have been using minikube and kubeadm or Rancher’s rke to bootstrap kubernetes clusters. Those tools are very nice but I wanted to understand all the details of a full setup. The best for this is the excellent “Kubernetes The Hard Way” tutorial from Kelsey Hightower.

I wanted to do the setup on-premises, meaning no using centos 7 vm's. As I have spent some time getting everything up and running.
The tutorial is using VMs, but should be applicable any non cloud setup like bare metal or other.

At the end of this guide, you will have a HA Kubernetes up and running with containerd, Weave Net and CoreDNS.
ON-PREMISES KUBERNETES STEP BY STEP
Using Kubernetes URL https://kubernetes.io/docs/setup/independent/install-kubeadm/ I have create vagrant file for creating cluster, I am using Fedore 28 with libvirt & vagrant. 

# Prerequisites:

Build a Kubernetes cluster using Ansible with kubeadm. The goal is easily install a Kubernetes cluster on machines running:

CentOS 7 
Fedora 28
Ubuntu 16
MAC OS & Windows user need to edit vagrantfile replace libvirt to virtualbox
Vagrant & Libvirt

For machine example:

IP Address	   Role	     CPU	Memory
192.168.122.8	k8smaster 	2	  2G
192.168.122.9	k8s-node01	1	  2G
192.168.122.10	k8s-node02	1	  2G

# Step to follow.

systemctl restart libvirt
systemctl enable libvirt

vagrant up --no-paralle

vagrant ssh k8smaster.example.com

#If the ip address in the above command is correct, run the following.
#Otherwise manually provide the correct address for apiserver-advertise-address
$kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$(hostname --ip-address)

#The kubeadm command will take a few minutes and it will print a 'kubeadm join'
#command once completed. Make sure to capture and store this 'kubeadm join'
#command as it is required to add other nodes to the Kubernetes cluster
Once the cluster is initialized, we can copy the generated configuration file (admin.conf) to the home directory ($HOME/.kube/config) for easy cluster administration using the kubectl cli:

#Deploy kube config
$mkdir -p $HOME/.kube
$sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$sudo chown $(id -u):$(id -g) $HOME/.kube/config

To allow the pods and containers to communicate over the network with each other, a cluster network is required to set up. Flannel is one of the various cluster networking solutions that we will use in this blog. For more information on Kubernetes networking, visit: https://kubernetes.io/docs/concepts/cluster-administration/networking/

#Install Flanner for network
#Doc: https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#44-joining-your-nodes
$kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
Per default,Kubernetes doesn't run pods on the master node as that could potentially result in a resource as well as security conflict. Pods might require such a large amount of system resources that the Kubernetes master might be negatively impacted. For single node clusters, however, (in case of testing, etc.), you can enforce pods to run on the master node as follows:

#Validate all pods are running
$kubectl get pods --all-namespaces
You can manage Kubernetes completely via the command line tool kubectl, but having a visual and graphical user interface to manage the cluster state can be very useful as well. To do so, let’s deploy the Kubernetes Dashboard:

#Deploy Dashboard web ui
#https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/
$kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
As the Kubernetes dashboard is also running in a Docker container, we need to modify its networking to access the dashboard from the outside world:

#Edit the dashboard to be open to the world (for demos only!)
#Change type from 'ClusterIP' to 'NodePort'
$kubectl -n kube-system edit service kubernetes-dashboard
Kubernetes user administration Instead, we will be allowing the default kube-system user to become a cluster administrator user. Again: not for production clusters!

#Make default user part of cluster admin
#not for production clusters, for demos only!
$kubectl create clusterrolebinding --user system:serviceaccount:kube-system:default kube-system-cluster-admin --clusterrole cluster-admin
To log on into the Kubernetes dashboard, a login token is required. To obtain the login ticket:

#Get the login token
$kubectl describe serviceaccount default -n kube-system
$kubectl describe secret default-token -n kube-system
Alternatively, it is possible to open the dashboard without login required (once again: not required for production systems). Simply click the 'skip' button in the Kubernetes dashboard login page after applying the following:

#Allow opening the k8 dashboard without login (not for production clusters, for demos only!)
$cat <<EOF > k8auth.yaml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: kubernetes-dashboard
  labels:
    k8s-app: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kube-system
EOF
$kubectl create -f k8auth.yaml
Pods on Kubernetes will, by default, open networking ports in the 30000+ range. To get the Kubernetes Dashboard port number, execute the following:

#Get the port that kubernetes dashboard runs on (should be a port in 30000+ range)
$kubectl -n kube-system get service kubernetes-dashboard
Launch the Kubernetes dashboard in your favorite internet browser:

#Open browser and connect to the Kubernetes Dashboard
https://<kubernetes_masternode_ip>:<port>
If you run into networking issues when connecting to the Dashboard, try using the Kubernetes proxy to connect to the Kubernetes internal networking:

#If unable to connect to Dashboard, try using the Kubernetes proxy:
$kubectl proxy

#With proxy running, open the Dashboard using the following url:
http://127.0.0.1:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
With the master node up and running, it is possible to add additional nodes to your Kubernetes cluster. To do so, use the 'kubeadm join …' command, as noted earlier in this blog. Please note, however, that the kubeadm command uses security tokens to authenticate itself with the master node. These tokens will expire after 24 hours, after which a new token has to be generated as explained below:

#Add additional nodes to the cluster (if required) using the earlier noted kubeadm join command
$kubeadm join …

#On Master, show all nodes part of the cluster:
$kubectl get nodes

#In case the token to join has expired, create a new token:
#On Master, list the existing tokens:
$kubeadm token list

#On Master, if there are no valid tokens, create a new token and list it:
$kubeadm token create
$kubeadm token list

#Join additional nodes in the cluster with the newly created token, e.g.,:
$kubeadm join 192.168.122.8:6443 --discovery-token-unsafe-skip-ca-verification --token nsndjiecsbchsidhas87686ehbdjhb23hdh
That's it: you now have a multi-node Kubernetes environment running!

Troubleshooting and Reset

When running into issues, use the following command to print logging information:

# Troubleshooting
$journalctl -xeu kubelet
To remove a node from the cluster:

#On master, remove a node from the cluster (hard)
$kubectl get nodes
$kubectl delete nodes <nodename>

#On the removed node, reset and uninstall kubernetes installation
$kubeadm reset
$yum erase kube* -y



