#!/bin/bash

set -e

echo "=== [1] Disable swap ==="
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo "=== [2] Load kernel modules ==="
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

echo "=== [3] Set sysctl params ==="
cat <<EOF | tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

echo "=== [4] Install containerd ==="
apt-get update
apt-get install -y containerd

mkdir -p /etc/containerd

containerd config default | \
sed 's/SystemdCgroup = false/SystemdCgroup = true/' | \
tee /etc/containerd/config.toml > /dev/null

systemctl restart containerd
systemctl enable containerd

echo "=== [5] Install Kubernetes packages ==="

apt-get update
apt-get install -y apt-transport-https ca-certificates curl

mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | \
gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /" | \
tee /etc/apt/sources.list.d/kubernetes.list

apt-get update

apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

echo "=== Worker node ready to join cluster ==="
