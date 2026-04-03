#!/bin/bash

set -e

echo "=== [1] Pre-check cluster ==="
kubectl get nodes

echo "=== [2] Install Cilium CLI ==="
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64

curl -L --fail --remote-name-all \
https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz

tar xzvf cilium-linux-${CLI_ARCH}.tar.gz
mv cilium /usr/local/bin/
rm cilium-linux-${CLI_ARCH}.tar.gz

echo "=== [3] Verify CLI ==="
cilium version

echo "=== [4] Install Cilium ==="

# Basic install (safe default)
cilium install

echo "=== [5] Wait for Cilium to be ready ==="
cilium status --wait

echo "=== [6] Validate networking ==="
cilium connectivity test

echo "=== [7] Final cluster check ==="
kubectl get pods -n kube-system
kubectl get nodes

echo "=== CILIUM INSTALLATION COMPLETE ==="
