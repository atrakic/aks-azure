#!/bin/bash

# Usage: ./ssh-to-k8s.sh <node-name>
# Description: This script is used to ssh into a k8s node for debugging purposes
# https://learn.microsoft.com/en-us/azure/aks/node-access

set -e

node=$1
kubectl debug node/"$node" -it --image=mcr.microsoft.com/cbl-mariner/busybox:2.0


