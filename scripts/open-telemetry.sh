#!/bin/bash

#helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
#helm repo update

# Single gw instance
kubectl apply -f https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector/v0.97.0/examples/k8s/otel-config.yaml
