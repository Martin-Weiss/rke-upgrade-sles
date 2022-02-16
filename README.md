To upgrade SLES 15 SP2 to SLES 15 SP3
-------------------------------------

- build a new spacecmd image from local resources
  - adjust Dockerfile
  - add local certificates to anchors
  - adjust build.sh
  - run build.sh

- adjust image source in rke-upgrade-sles.yaml to match to the image build and pushed in build.sh

- create a user in SUSE Manager that has the right to adjust software channel assignments on target systems

- adjust start.sh to the environment (stages, channel-names, SUSE Manager user)

- run create-rke-upgrade-sles-script-secret.sh to update the secret

- optional: set label to run only one node
  - adjust and execute test-one-node-only.sh
  - export KUBECONFIG=~/.kube/<cluster-config>
  - execute ./test-one-node-only.sh

- run the upgrade with ./apply.sh
  - export KUBECONFIG=~/.kube/<cluster-config>
  - ./apply.sh

- monitor the upgrade
  - kubectl get pods -n rke-upgrade-sles
