#!/bin/bash
kubectl label ns rke-upgrade-sles pod-security.kubernetes.io/enforce=permissive --overwrite
kubectl apply -f system-upgrade-controller.yaml
kubectl apply -f rke-upgrade-sles-script.yaml
# wait on CRD to be available
sleep 30
kubectl apply -f rke-upgrade-sles.yaml
