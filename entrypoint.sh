#!/bin/bash
# ScyllaDB entrypoint for Fly.io
# Fly injects FLY_PRIVATE_IP as the machine's IPv6 address on the
# private 6PN network. ScyllaDB needs to bind to this address so
# other Fly apps (Phoenix) can reach it via koda-scylla.internal.

set -e

# Fly injects the private IPv6 address as FLY_PRIVATE_IP.
# If for any reason it's absent, fall back to detecting from interfaces.
if [ -n "$FLY_PRIVATE_IP" ]; then
    LISTEN_ADDR="$FLY_PRIVATE_IP"
    echo "[koda-entrypoint] Using Fly private IP: $LISTEN_ADDR"
else
    # Fallback: first non-loopback IP
    LISTEN_ADDR=$(hostname -I | awk '{print $1}')
    echo "[koda-entrypoint] FLY_PRIVATE_IP not set, using: $LISTEN_ADDR"
fi

SMP="${SCYLLA_SMP:-2}"
MEMORY="${SCYLLA_MEMORY:-3G}"

echo "[koda-entrypoint] Starting ScyllaDB — smp=$SMP memory=$MEMORY"

exec /docker-entrypoint.py \
    --smp           "$SMP" \
    --memory        "$MEMORY" \
    --overprovisioned 1 \
    --listen-address        "$LISTEN_ADDR" \
    --rpc-address           "$LISTEN_ADDR" \
    --broadcast-rpc-address "$LISTEN_ADDR" \
    --broadcast-address     "$LISTEN_ADDR" \
    --api-address           0.0.0.0 \
    --seed-provider-class-name \
        org.apache.cassandra.locator.SimpleSeedProvider \
    --seed "$LISTEN_ADDR" \
    --authenticator AllowAllAuthenticator \
    --authorizer   AllowAllAuthorizer
