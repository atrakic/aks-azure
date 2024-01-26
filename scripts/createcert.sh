#!/bin/bash

set -e
set -x
set -o pipefail

#DOCKER_CONTAINER=${DOCKER_CONTAINER:?"You need to configure the DOCKER_CONTAINER environment variable, eg. 'containous/whoami' !"}

Hostname=${1:?"hostname is missing, eg. demo.adtr.kp.dk"}
KeyVaultName=${2:?"keyvaultname is missing, eg. DemoAppKeyVault"}
KeyVaultCertificateName=${3:?"keyvault certificate name is missing, eg. DemoAppCertificate"}
ResourceGroupName=${4:?"resource group is missing"}
ClusterName=${5:?"aks cluster name is missing"}

openssl req -new -x509 -nodes -out aks-ingress-tls.crt -keyout aks-ingress-tls.key -subj "/CN=$Hostname" -addext "subjectAltName=DNS:$Hostname"
openssl pkcs12 -export -in aks-ingress-tls.crt -inkey aks-ingress-tls.key -out aks-ingress-tls.pfx

az keyvault create -g "$ResourceGroupName" -n "$KeyVaultName" --enable-rbac-authorization true
az keyvault certificate import --vault-name "$KeyVaultName" -n "$KeyVaultCertificateName" -f aks-ingress-tls.pfx #[--password <certificate password if specified>]

KEYVAULTID=$(az keyvault show --name "$KeyVaultName" --query "id" --output tsv)
az aks approuting update -g "$ResourceGroupName" -n "$ClusterName" --enable-kv --attach-kv "${KEYVAULTID}"

KeyVaultCertificateUri=$(az keyvault certificate show --vault-name "$KeyVaultName" -n "$KeyVaultCertificateName" --query "id" --output tsv)
cat <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.azure.com/tls-cert-keyvault-uri: "$KeyVaultCertificateUri"
  name: YOUR-INGRESS
  namespace: hello-web-app-routing
spec:
  ingressClassName: webapprouting.kubernetes.azure.com
  rules:
  - host: "$Hostname"
    http:
      paths:
      - backend:
          service:
            name: YOUR-SERVICE
            port:
              number: 80
        path: /
        pathType: Prefix
  tls:
  - hosts:
    - "$Hostname"
    secretName: keyvault-YOUR-INGRESS-NAME
EOF
