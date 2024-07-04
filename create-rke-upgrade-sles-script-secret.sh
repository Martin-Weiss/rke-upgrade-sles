#!/bin/bash
VERSION="15sp5-15sp6"
cat rke-upgrade-sles-script.yaml.template > rke-upgrade-sles-script.yaml
sed 's/^/    /g' start.sh-$VERSION >>rke-upgrade-sles-script.yaml
