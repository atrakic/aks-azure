#!/bin/bash

if [ "$1" = "--delete" ]; then
  helm uninstall prometheus --namespace monitoring
  kubectl delete ns monitoring
  exit 0
fi

# Create the namespace for monitoring
kubectl create namespace monitoring

# Add the prometheus-community Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Update your local Helm chart repository cache
helm repo update

# Install the cert-manager Helm chart
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring

kubectl wait --for=condition=Ready pods -n monitoring

kubectl -n monitoring get secret prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

echo "Usage: kubectl --namespace monitoring port-forward svc/prometheus-grafana 8080:80"
