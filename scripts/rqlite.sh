#!/bin/sh

helm repo add rqlite https://rqlite.github.io/helm-charts
helm repo update

helm upgrade -n rqlite --create-namespace rqlite \
  --install rqlite/rqlite --version 1.1.0 \
  --set readonly.replicaCount=0 \
  --set persistence.size=1Gi --set replicaCount=3

if [ "$1" = "--delete" ]; then
  helm uninstall rqlite --namespace rqlite
  kubectl delete ns rqlite
fi
