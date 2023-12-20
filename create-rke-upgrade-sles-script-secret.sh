#!/bin/bash
VERSION="15sp4-15sp5"
cat rke-upgrade-sles-script.yaml.template > rke-upgrade-sles-script.yaml
sed 's/^/    /g' start.sh-$VERSION >>rke-upgrade-sles-script.yaml
