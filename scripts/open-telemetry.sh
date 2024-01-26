#!/bin/bash

helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

helm install my-otel-demo open-telemetry/opentelemetry-demo --values ${BASEDIR}/monitoring/values.yaml
