#!/bin/bash

if [ "$1" = "--delete" ]; then
  helm uninstall cert-manager --namespace cert-manager
  kubectl delete ns cert-manager
  exit 0
fi

helm repo add jetstack https://charts.jetstack.io
helm repo update

kubectl create namespace cert-manager
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.5.3 --set installCRDs=true

# wait for cert-manager to be ready
kubectl wait --for=condition=Ready pods -n cert-manager --all

## CS setup with Self-signed certificates
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: selfsigned-issuer
  namespace: cert-manager
spec:
  selfSigned: {}
EOF

cat <<EOF | kubectl apply -f -
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-ca
  namespace: cert-manager
spec:
  isCA: true
  commonName: test-ca
  subject:
    organizations:
      - ACME Inc.
    organizationalUnits:
      - Widgets
  secretName: test-ca-secret
  privateKey:
    algorithm: ECDSA
    size: 256
  issuerRef:
    name: selfsigned-issuer
    kind: Issuer
    group: cert-manager.io
EOF

cat <<EOF | kubectl apply -f -
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: test-ca-issuer
  namespace: cert-manager
spec:
  ca:
    secretName: test-ca-secret
EOF

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-server
  namespace: cert-manager
spec:
  secretName: test-server-tls
  isCA: false
  usages:
    - server auth
    - client auth
  dnsNames:
  - "test-server.test.svc.cluster.local"
  - "test-server"
  issuerRef:
    name: test-ca-issuer
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-client
  namespace: cert-manager
spec:
  secretName: test-client-tls
  isCA: false
  usages:
    - server auth
    - client auth
  dnsNames:
  - "test-client.test.svc.cluster.local"
  - "test-client"
  issuerRef:
    name: test-ca-issuer
EOF


## Verify the setup
openssl verify -CAfile \
<(kubectl -n cert-manager get secret test-ca-secret -o jsonpath='{.data.ca\.crt}' | base64 -d) \
<(kubectl -n cert-manager get secret test-server-tls -o jsonpath='{.data.tls\.crt}' | base64 -d)

exit 0

##
echo "Hello World!" > test.txt
openssl s_server \
  -cert <(kubectl -n cert-manager get secret test-server-tls -o jsonpath='{.data.tls\.crt}' | base64 -d) \
  -key <(kubectl -n cert-manager get secret test-server-tls -o jsonpath='{.data.tls\.key}' | base64 -d) \
  -CAfile <(kubectl -n cert-manager get secret test-server-tls -o jsonpath='{.data.ca\.crt}' | base64 -d) \
  -WWW -port 12345  \
  -verify_return_error -Verify 1

echo -e 'GET /test.txt HTTP/1.1\r\n\r\n' | \
  openssl s_client \
  -cert <(kubectl -n cert-manager get secret test-client-tls -o jsonpath='{.data.tls\.crt}' | base64 -d) \
  -key <(kubectl -n cert-manager get secret test-client-tls -o jsonpath='{.data.tls\.key}' | base64 -d) \
  -CAfile <(kubectl -n cert-manager get secret test-client-tls -o jsonpath='{.data.ca\.crt}' | base64 -d) \
  -connect localhost:12345 -quiet

rm -rf test.txt
