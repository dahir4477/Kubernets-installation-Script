#!/bin/bash

set -e

### ====== CONFIG (REPLACE THESE VALUES) ======
API_SERVER="LOAD_BALANCER_IP:6443"
TOKEN="abcdef.1234567890abcdef"
DISCOVERY_HASH="sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
CERT_KEY="1234567890abcdef1234567890abcdef"

K8S_VERSION="1.34.5-1.1"   # match your cluster version

echo ">>> Disabling swap..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo ">>> Loading kernel modules..."
modprobe overlay
modprobe br_netfilter

cat <<EOF | tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

echo ">>> Setting sysctl params..."
cat <<EOF | tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system

echo ">>> Installing containerd..."
apt-get update -y
apt-get install -y containerd

mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml >/dev/null

systemctl restart containerd
systemctl enable containerd

echo ">>> Installing Kubernetes components..."
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubelet=$K8S_VERSION kubeadm=$K8S_VERSION kubectl=$K8S_VERSION

apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet

echo ">>> Join the CP node as Secondary CONTROL PLANE..."

echo ">>> Node successfully joined as control-plane"
