#!/bin/bash
kubectl label node skip-rke-upgrade-sles=true --all
kubectl label node rancher-master-03 skip-rke-upgrade-sles-
# to run all execute:
#kubectl label node skip-rke-upgrade-sles- --all
