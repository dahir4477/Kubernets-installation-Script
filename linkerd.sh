# 1. Install Linkerd CLI (pin version instead of latest for stability)
curl -sL https://run.linkerd.io/install | sh

# 2. Add Linkerd to PATH (persist correctly)
export PATH=$PATH:$HOME/.linkerd2/bin
echo 'export PATH=$PATH:$HOME/.linkerd2/bin' >> ~/.bashrc

# 3. Verify CLI installation
linkerd version

# 4. Pre-flight checks (CRITICAL before install)
linkerd check --pre

# 5. Install CRDs first (required separation step)
linkerd install --crds | kubectl apply -f -

# 6. Install Linkerd control plane
linkerd install | kubectl apply -f -

# 7. Verify installation
linkerd check

# 8. Install Linkerd Viz extension (observability)
linkerd viz install | kubectl apply -f -

# 9. Verify Viz extension
linkerd viz check

# 10. Access dashboard (foreground for stability)
linkerd viz dashboard
