#!/bin/bash
# /etc/scylla/scylla.yaml is the binary's default config path --
# no explicit flag needed to point at it (--config-file isn't a
# recognized option). Our pre-written scylla.yaml is already sitting
# at that exact default location via the Dockerfile COPY, so the
# binary should pick it up automatically with zero extra arguments
# for the config path itself.

set -e

if [ -n "$FLY_PRIVATE_IP" ]; then
    PRIVATE_ADDR="$FLY_PRIVATE_IP"
else
    PRIVATE_ADDR=$(hostname -I | awk '{print $1}')
fi

echo "$PRIVATE_ADDR koda-broadcast" >> /etc/hosts
echo "[koda-entrypoint] /etc/hosts mapping: koda-broadcast -> $PRIVATE_ADDR"
echo "[koda-entrypoint] Relying on default config path /etc/scylla/scylla.yaml (no explicit flag)"

exec /usr/bin/scylla \
    --log-to-syslog 0 \
    --log-to-stdout 1 \
    --network-stack posix \
    --developer-mode=1 \
    --memory "${SCYLLA_MEMORY:-1500M}" \
    --smp "${SCYLLA_SMP:-2}" \
    --overprovisioned
