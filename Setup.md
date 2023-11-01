# RUN THESE COMMANDS IN MASTER AND SLAVE

## Install Docker:
yum install docker 
systemctl start docker --now

## Br_netflter module load:
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

## ADD REPO
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

## Selinux permissive mode
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

## Install kubeadm 
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable kubelet

## Pulling the component images
kubeadm config  images pull

## Changing docker daemon driver

/etc/docker/daemon.json
{ "exec-opts": ["native.cgroupdriver=systemd"] }
systemctl restart docker

## Install iproute-tc to set to set routing path:
yum install iproute-tc

## we need to set the bridge routing to 1 
 echo "1" > /proc/sys/net/bridge/bridge-nf-call-iptables

## RUN ON MASTER ONLY:
kubeadm init --pod-network-cidr=10.240.0.0/16  --ignore-preflight-errors=NumCPU --ignore-preflight-errors=Mem

## After this you'll add the .kube folder

## Run the join command in the slave.