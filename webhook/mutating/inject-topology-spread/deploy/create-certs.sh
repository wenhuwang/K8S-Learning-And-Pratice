#! /bin/bash

WEBHOOK_NS=${1:-"default"}
EXAMPLE_NAME=${2:-"inject-topology-spread"}
WEBHOOK_SVC="${EXAMPLE_NAME}-webhook"
CSR_NAME="${WEBHOOK_SVC}-${WEBHOOK_NS}"

# Create certs for our webhook
openssl genrsa -out webhookCA.key 2048

cat <<EOF >> ./csr.conf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${WEBHOOK_SVC}
DNS.2 = ${WEBHOOK_SVC}.${WEBHOOK_NS}
DNS.3 = ${WEBHOOK_SVC}.${WEBHOOK_NS}.svc
EOF


openssl req -new -key ./webhookCA.key -days 36500 -subj "/CN=system:node:${WEBHOOK_SVC}.${WEBHOOK_NS}.svc/O=system:nodes" -out ./webhookCA.csr -config csr.conf

# clean-up any previously created CSR for our service. Ignore errors if not present.
kubectl delete csr ${CSR_NAME} 2>/dev/null || true

cat <<EOF | kubectl create -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${CSR_NAME}
spec:
  signerName: kubernetes.io/kubelet-serving
  groups:
  - system:authenticated
  request: $(cat ./webhookCA.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

kubectl certificate approve ${CSR_NAME}

kubectl get csr ${CSR_NAME} -o jsonpath='{.status.certificate}' | openssl base64 -d -A -out ./webhook.crt

# # Create certs secrets for k8s
kubectl create secret generic \
    ${WEBHOOK_SVC}-certs \
    --from-file=key.pem=./webhookCA.key \
    --from-file=cert.pem=./webhook.crt \
    --dry-run -o yaml > ./webhook-certs.yaml

# # Set the CABundle on the webhook registration
CA_BUNDLE=$(kubectl get configmap -n kube-system extension-apiserver-authentication  -o=jsonpath='{.data.client-ca-file}' | base64)
sed "s/CA_BUNDLE/${CA_BUNDLE}/" ./webhook-registration.yaml.tpl > ./webhook-registration.yaml

# # Clean
rm ./webhookCA* && rm ./webhook.crt && rm ./csr.conf