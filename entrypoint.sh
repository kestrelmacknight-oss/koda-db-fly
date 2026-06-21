#!/bin/bash
# scylla looks for "conf/scylla.yaml" relative to its working
# directory -- cd into /scylla-config (where Dockerfile placed
# conf/scylla.yaml) before launching, so that relative path resolves.

set -e

if [ -n "$FLY_PRIVATE_IP" ]; then
    PRIVATE_ADDR="$FLY_PRIVATE_IP"
else
    PRIVATE_ADDR=$(hostname -I | awk '{print $1}')
fi

echo "$PRIVATE_ADDR koda-broadcast" >> /etc/hosts
echo "[koda-entrypoint] /etc/hosts mapping: koda-broadcast -> $PRIVATE_ADDR"

cd /scylla-config
echo "[koda-entrypoint] Working directory: $(pwd) -- conf/scylla.yaml should now resolve"

exec /usr/bin/scylla \
    --log-to-syslog 0 \
    --log-to-stdout 1 \
    --network-stack posix \
    --developer-mode=1 \
    --memory "${SCYLLA_MEMORY:-1500M}" \
    --smp "${SCYLLA_SMP:-2}" \
    --overprovisioned
