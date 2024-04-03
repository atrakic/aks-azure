#!/bin/bash

if [ "$1" = "--delete" ]; then
  helm uninstall prometheus-blackbox-exporter --namespace monitoring
  kubectl delete ns monitoring
  exit 0
fi

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm update --install prometheus-blackbox-exporter prometheus-community/prometheus-blackbox-exporter \
    --namespace monitoring --create-namespace \
    --set serviceMonitor.enabled=true
