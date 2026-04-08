mkdir -p ~/k8s-users
cd ~/k8s-users
#!/bin/bash
# Usage: ./create-k8s-user.sh <username> <group> <namespace>

USERNAME=$1
GROUP=$2
NAMESPACE=$3

if [ -z "$USERNAME" ] || [ -z "$GROUP" ] || [ -z "$NAMESPACE" ]; then
  echo "Usage: $0 <username> <group> <namespace>"
  exit 1
fi

echo "Creating Kubernetes user: $USERNAME in group $GROUP"

# 1️⃣ Generate private key
openssl genrsa -out ${USERNAME}.key 2048
echo "Private key generated: ${USERNAME}.key"

# 2️⃣ Generate CSR
openssl req -new -key ${USERNAME}.key -out ${USERNAME}.csr -subj "/CN=${USERNAME}/O=${GROUP}"
echo "CSR generated: ${USERNAME}.csr"

# 3️⃣ Encode CSR for Kubernetes
CSR_BASE64=$(cat ${USERNAME}.csr | base64 | tr -d '\n')

# 4️⃣ Create CSR YAML
cat <<EOF > ${USERNAME}-csr.yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${USERNAME}-csr
spec:
  request: ${CSR_BASE64}
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
    - client auth
EOF

kubectl apply -f ${USERNAME}-csr.yaml
echo "CSR applied to Kubernetes: ${USERNAME}-csr.yaml"

# 5️⃣ Approve CSR
kubectl certificate approve ${USERNAME}-csr
echo "CSR approved for user: $USERNAME"

# 6️⃣ Extract signed certificate
kubectl get csr ${USERNAME}-csr -o jsonpath='{.status.certificate}' | base64 -d > ${USERNAME}.crt
echo "Signed certificate saved: ${USERNAME}.crt"

# 7️⃣ Create kubeconfig
kubectl config set-credentials ${USERNAME} \
  --client-certificate=${USERNAME}.crt \
  --client-key=${USERNAME}.key \
  --embed-certs=true

kubectl config set-context ${USERNAME}-context \
  --cluster=$(kubectl config view -o jsonpath='{.contexts[0].context.cluster}') \
  --user=${USERNAME} \
  --namespace=${NAMESPACE}

kubectl config use-context ${USERNAME}-context
echo "Kubeconfig context created: ${USERNAME}-context"
echo "User $USERNAME setup complete"
