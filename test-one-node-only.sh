#!/bin/bash
kubectl label node skip-rke-upgrade-sles=true --all
kubectl label node rke-test-master-03 skip-rke-upgrade-sles-
# to run all execute:
#kubectl label node skip-rke-upgrade-sles- --all
