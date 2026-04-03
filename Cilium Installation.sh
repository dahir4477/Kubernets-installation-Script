
#!/bin/bash

set -e

echo "=== [1] Understand cluster state ==="
kubectl get nodes
kubectl get pods -A

echo "=== [2] Pre-check cluster ==="
kubectl get nodes

echo "=== [3] Check kernel version ==="
uname -r

echo "=== [4] Install Cilium CLI ==="
curl -LO https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz

sudo tar xzvf cilium-linux-amd64.tar.gz -C /usr/local/bin

rm -f cilium-linux-amd64.tar.gz

echo "=== [5] Verify cluster connectivity ==="
kubectl cluster-info

echo "=== [6] Install Cilium ==="
cilium install

echo "=== [7] Check Cilium status ==="
cilium status --wait

echo "=== CILIUM INSTALLATION COMPLETE ==="


