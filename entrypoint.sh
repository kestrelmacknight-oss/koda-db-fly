#!/bin/bash
# ScyllaDB entrypoint for Fly.io
# Fly injects FLY_PRIVATE_IP as the machine's IPv6 address on the
# private 6PN network. ScyllaDB binds to this address directly so
# other Fly apps (Phoenix) can reach it via the .internal hostname.
#
# This is the clean, originally-intended version -- no loopback
# substitution, no wildcard binding, no bracket notation, no /etc/hosts
# workaround. All of that was compensating for an IPv6 address-parsing
# bug in ScyllaDB 6.2.3 (segfaulted even after working around the
# resolution error). Now running on the 2025.1 LTS lane, which should
# not have that regression.

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
