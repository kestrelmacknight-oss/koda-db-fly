#!/bin/bash
# ScyllaDB entrypoint for Fly.io
#
# listen-address stays 127.0.0.1 -- confirmed working, gossip-only,
# irrelevant for a single standalone node.
#
# rpc-address stays 0.0.0.0 (all interfaces) -- but Scylla's own
# config validation requires broadcast_rpc_address to be explicitly
# set whenever rpc_address is a wildcard. broadcast-rpc-address is
# the one address that genuinely must be the real Fly private IP,
# since it's what Scylla advertises as "connect to me here." Bracket
# notation is used since the evidence so far points to Scylla's
# resolver specifically mishandling unbracketed IPv6 literals (IPv4
# loopback resolved with zero issues; the Fly IPv6 literal is what's
# repeatedly tripped up resolution).

set -e

if [ -n "$FLY_PRIVATE_IP" ]; then
    PRIVATE_ADDR="$FLY_PRIVATE_IP"
else
    PRIVATE_ADDR=$(hostname -I | awk '{print $1}')
fi

SMP="${SCYLLA_SMP:-2}"
MEMORY="${SCYLLA_MEMORY:-1500M}"

echo "[koda-entrypoint] Starting ScyllaDB -- smp=$SMP memory=$MEMORY"
echo "[koda-entrypoint] broadcast-rpc-address=[$PRIVATE_ADDR]"

exec /docker-entrypoint.py \
    --smp           "$SMP" \
    --memory        "$MEMORY" \
    --overprovisioned 1 \
    --listen-address       127.0.0.1 \
    --rpc-address           0.0.0.0 \
    --broadcast-rpc-address "[$PRIVATE_ADDR]" \
    --api-address           0.0.0.0 \
    --seed-provider-class-name \
        org.apache.cassandra.locator.SimpleSeedProvider \
    --seed 127.0.0.1 \
    --authenticator AllowAllAuthenticator \
    --authorizer   AllowAllAuthorizer
