#!/bin/bash
# ScyllaDB entrypoint for Fly.io
# Fly injects FLY_PRIVATE_IP as the machine's IPv6 address on the
# private 6PN network. ScyllaDB needs to bind to this address so
# other Fly apps (Phoenix) can reach it via the .internal hostname.
#
# broadcast-address / broadcast-rpc-address are intentionally NOT
# passed -- Scylla's address-resolution path can attempt a DNS lookup
# even on literal IPv6 addresses and fail with "Bad name" (C-Ares).
# Observed evidence: this has hit listen-address on one boot and
# broadcast-address on another, with identical input -- not a bug
# tied to one specific flag, but a startup race where Scylla's
# resolver runs before the container's own networking has fully
# settled. The fix is a short delay before launching Scylla at all,
# giving the network namespace a moment to finish initializing.

set -e

echo "[koda-entrypoint] Waiting for container networking to settle..."
sleep 5

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
