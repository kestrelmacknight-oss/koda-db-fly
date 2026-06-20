#!/bin/bash
# ScyllaDB entrypoint for Fly.io
# Fly injects FLY_PRIVATE_IP as the machine's IPv6 address on the
# private 6PN network. ScyllaDB needs to bind to this address so
# other Fly apps (Phoenix) can reach it via the .internal hostname.
#
# broadcast-address / broadcast-rpc-address are intentionally NOT
# passed explicitly -- Scylla's broadcast_address resolution path
# attempts a DNS lookup even on literal IPv6 addresses and fails with
# "Couldn't resolve broadcast_address" (C-Ares "Bad name"). Per
# Scylla's documented default, broadcast_address falls back to
# listen_address automatically when left unset, which avoids that
# broken resolution path entirely while producing the same result.

set -e

if [ -n "$FLY_PRIVATE_IP" ]; then
    LISTEN_ADDR="$FLY_PRIVATE_IP"
    echo "[koda-entrypoint] Using Fly private IP: $LISTEN_ADDR"
else
    LISTEN_ADDR=$(hostname -I | awk '{print $1}')
    echo "[koda-entrypoint] FLY_PRIVATE_IP not set, using: $LISTEN_ADDR"
fi

SMP="${SCYLLA_SMP:-2}"
MEMORY="${SCYLLA_MEMORY:-1500M}"

echo "[koda-entrypoint] Starting ScyllaDB -- smp=$SMP memory=$MEMORY"

exec /docker-entrypoint.py \
    --smp           "$SMP" \
    --memory        "$MEMORY" \
    --overprovisioned 1 \
    --listen-address "$LISTEN_ADDR" \
    --rpc-address    "$LISTEN_ADDR" \
    --api-address    0.0.0.0 \
    --seed-provider-class-name \
        org.apache.cassandra.locator.SimpleSeedProvider \
    --seed "$LISTEN_ADDR" \
    --authenticator AllowAllAuthenticator \
    --authorizer   AllowAllAuthorizer
