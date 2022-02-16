#!/bin/bash
kubectl delete deployments -n rke-upgrade-sles --all
kubectl delete jobs -n rke-upgrade-sles --all
kubectl delete ns rke-upgrade-sles
kubectl delete ClusterRoleBinding rke-upgrade-sles
kubectl label node skip-rke-upgrade-sles- --all
kubectl label node plan.upgrade.cattle.io/rke-upgrade-sles- --all
kubectl uncordon -l kubernetes.io/os=linux
