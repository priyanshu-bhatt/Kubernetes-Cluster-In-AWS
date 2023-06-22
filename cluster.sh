#!/bin/bash
echo " Setting up Kubernetes Master in Cluster "

echo " installing docker"

yum install docker -y
systemctl enable docker --now

# Setting up netfilter

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

#Setting Up Kubernetes repo

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

#Disabling SELINUX

sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Installing Software essesntials:
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

#Enabling kubelet

systemctl enable kubelet

# Installing Images
#
kubeadm config images pull

## Changing  Docker Driver

cat <<EOF | sudo tee /etc/docker/daemon.json
{
"exec-opts": ["native.cgroupdriver=systemd"]
}
EOF


## installing iproute-tc
yum install iproute-tc

# Setting Up bridge routing
echo "1" > /proc/sys/net/bridge/bridge-nf-call-iptables

#Initialization cluster

echo " setting up cluster in few seconds "

kubeadm init --pod-network-cidr=10.240.0.0/16  --ignore-preflight-errors=NumCPU --ignore-preflight-errors=Mem &> /etc/null

echo "cluster setup successfully"

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

token=$(kubeadm token create --print-join-command)
echo $token
