#!/bin/bash
# ScyllaDB entrypoint for Fly.io
#
# Reverted from all-IPv6 (::1/::/::1) -- that combination failed to
# start at all (no scylla process ever appeared across 20+ minutes of
# checks, worse than the periodic-restart behavior seen before it).
# Back to listen-address=127.0.0.1 / rpc-address=:: /
# broadcast-rpc-address=127.0.0.1, which DID achieve full healthy
# boots (state=normal, schema applied, cqlsh connecting) even though
# it cycled roughly every 15-20 minutes. That periodic cycling is a
# separate, lower-priority issue to revisit -- this combination is
# the one that has actually demonstrated working CQL service.

set -e

SMP="${SCYLLA_SMP:-2}"
MEMORY="${SCYLLA_MEMORY:-1500M}"

echo "[koda-entrypoint] Starting ScyllaDB -- smp=$SMP memory=$MEMORY"

exec /docker-entrypoint.py \
    --smp           "$SMP" \
    --memory        "$MEMORY" \
    --overprovisioned 1 \
    --listen-address       127.0.0.1 \
    --rpc-address           :: \
    --broadcast-rpc-address 127.0.0.1 \
    --api-address           0.0.0.0 \
    --seed-provider-class-name \
        org.apache.cassandra.locator.SimpleSeedProvider \
    --seed 127.0.0.1 \
    --authenticator AllowAllAuthenticator \
    --authorizer   AllowAllAuthorizer
