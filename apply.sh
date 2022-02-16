#!/bin/bash
kubectl apply -f system-upgrade-controller.yaml
kubectl apply -f rke-upgrade-sles-script.yaml
# wait on CRD to be available
sleep 30
kubectl apply -f rke-upgrade-sles.yaml
