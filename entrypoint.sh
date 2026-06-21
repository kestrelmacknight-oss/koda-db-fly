#!/bin/bash
# Bypassing docker-entrypoint.py's CLI-flag-to-YAML translation
# entirely this time -- invoking the scylla binary directly against
# our own pre-written /etc/scylla/scylla.yaml, which sets rpc_address
# to a hostname (koda-broadcast) mapped in /etc/hosts, plus
# enable_ipv6_dns_lookup: true. Testing whether this genuinely
# different code path (config file vs CLI args) behaves differently
# than every CLI-flag-based attempt today.

set -e

if [ -n "$FLY_PRIVATE_IP" ]; then
    PRIVATE_ADDR="$FLY_PRIVATE_IP"
else
    PRIVATE_ADDR=$(hostname -I | awk '{print $1}')
fi

echo "$PRIVATE_ADDR koda-broadcast" >> /etc/hosts
echo "[koda-entrypoint] /etc/hosts mapping: koda-broadcast -> $PRIVATE_ADDR"
echo "[koda-entrypoint] Using /etc/scylla/scylla.yaml directly, bypassing CLI flag translation"

exec /usr/bin/scylla \
    --log-to-syslog 0 \
    --log-to-stdout 1 \
    --network-stack posix \
    --developer-mode=1 \
    --memory "${SCYLLA_MEMORY:-1500M}" \
    --smp "${SCYLLA_SMP:-2}" \
    --overprovisioned \
    --config-file /etc/scylla/scylla.yaml
