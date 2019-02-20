#!/bin/sh

set -ex

eval $(ssh-agent)
ssh-add /root/.ssh/aws-private-key

cd /local

parallel-rsync \
    -avrz  \
     $PSSH_HOSTNAMES \
     -l ubuntu \
    -O StrictHostKeyChecking=no  \
    -O UserKnownHostsFile=/local/known_hosts \
    ./provisioning/ \
    /home/ubuntu/provisioning/