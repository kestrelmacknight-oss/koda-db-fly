#!/bin/bash
# ScyllaDB entrypoint for Fly.io
#
# Definitively proven today: rpc-address=:: (wildcard) gets accepted
# without error but the listener ONLY actually honors 127.0.0.1 --
# confirmed by testing the real address from the SAME machine and
# still getting refused. The wildcard approach was never the real fix.
#
# Going back to what the very first test of the day actually showed:
# rpc-address set directly to the literal Fly address parsed and
# bound successfully that time (only broadcast_address crashed).
# Since rpc-address is NOT a wildcard here, broadcast-rpc-address /
# broadcast-address become unnecessary (Scylla's own validation says
# they're only REQUIRED for wildcard rpc-address) -- so they're
# omitted entirely, avoiding that resolution path altogether.

set -e

if [ -n "$FLY_PRIVATE_IP" ]; then
    LISTEN_ADDR="$FLY_PRIVATE_IP"
else
    LISTEN_ADDR=$(hostname -I | awk '{print $1}')
fi

SMP="${SCYLLA_SMP:-2}"
MEMORY="${SCYLLA_MEMORY:-1500M}"

echo "[koda-entrypoint] Starting ScyllaDB -- smp=$SMP memory=$MEMORY"
echo "[koda-entrypoint] rpc-address=$LISTEN_ADDR (real address, not a wildcard -- no broadcast fields needed)"

exec /docker-entrypoint.py \
    --smp           "$SMP" \
    --memory        "$MEMORY" \
    --overprovisioned 1 \
    --listen-address 127.0.0.1 \
    --rpc-address    "$LISTEN_ADDR" \
    --api-address    0.0.0.0 \
    --seed-provider-class-name \
        org.apache.cassandra.locator.SimpleSeedProvider \
    --seed 127.0.0.1 \
    --authenticator AllowAllAuthenticator \
    --authorizer   AllowAllAuthorizer
