#!/bin/bash
cat rke-upgrade-sles-script.yaml.template > rke-upgrade-sles-script.yaml
sed 's/^/    /g' start.sh >>rke-upgrade-sles-script.yaml
