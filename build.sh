#!/bin/bash
VERSION="15.5.2"

# bot username in each registry and namespace (add robot$rke-dev+ to the name)
RKE_USER="staging"
RKE_PASSWORD='KUSLjyvg8-bKKgfZhtiQ'

# 3 registries, 3 namespaces in each
REGISTRIES="registry01.suse"
NAMESPACES="rke-test rke-int rke-prod"

# for the build process
RKE_DEV_USER='staging'
RKE_DEV_PASSWORD=$RKE_PASSWORD
DEV_REGISTRY="registry01.suse"
DEV_NAMESPACE="rke-test"

rm ~/.docker/config.json
podman login $DEV_REGISTRY --username $RKE_DEV_USER --password $RKE_DEV_PASSWORD
# containerD fails to extract image after pull - see https://github.com/containers/buildah/issues/1589
export BUILDAH_FORMAT=docker
podman build --format docker -t $DEV_REGISTRY/$DEV_NAMESPACE/spacecmd:$VERSION /data/rke-upgrade-sles

for REGISTRY in $REGISTRIES; do
	for NAMESPACE in $NAMESPACES; do
		echo $REGISTRY/$NAMESPACE
		podman login $REGISTRY --username $RKE_USER -p $RKE_PASSWORD
		podman tag $DEV_REGISTRY/$DEV_NAMESPACE/spacecmd:$VERSION $REGISTRY/$NAMESPACE/spacecmd:$VERSION
		podman push --compress=false $REGISTRY/$NAMESPACE/spacecmd:$VERSION
	done
done
