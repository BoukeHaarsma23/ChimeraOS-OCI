#! /bin/bash

set -e
set -x
source /workdir/manifest

# This allows using pacstrap -N in a rootless container.
echo 'root:1000:5000' > /etc/subuid
echo 'root:1000:5000' > /etc/subgid

# Install packages in our mount which we copy into a container
# Prepend chos to make sure the builder variant is used
pacstrap -c -G mnt \
    ${PACKAGES}