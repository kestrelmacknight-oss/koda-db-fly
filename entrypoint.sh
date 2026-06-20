#!/bin/bash
# ScyllaDB entrypoint for Fly.io
#
# Confirmed: Scylla's c-ares resolver performs genuine network DNS
# queries for broadcast_rpc_address -- it does NOT consult /etc/hosts
# at all (a fake local hostname there got "Connection refused" from
# real DNS, since nothing outside this container had ever heard of
# it). Since it does real DNS lookups successfully, giving it a REAL,
# already-registered DNS name -- this app's own Fly .internal
# hostname, the same one koda-server already uses to reach this
# database -- should resolve correctly through Fly's actual internal
# DNS infrastructure rather than failing on a name nobody's heard of.

set -e

SMP="${SCYLLA_SMP:-2}"
MEMORY="${SCYLLA_MEMORY:-1500M}"

echo "[koda-entrypoint] Starting ScyllaDB -- smp=$SMP memory=$MEMORY"
echo "[koda-entrypoint] broadcast-rpc-address=koda-db-fly.internal (real Fly DNS name)"

exec /docker-entrypoint.py \
    --smp           "$SMP" \
    --memory        "$MEMORY" \
    --overprovisioned 1 \
    --listen-address       127.0.0.1 \
    --rpc-address           0.0.0.0 \
    --broadcast-rpc-address koda-db-fly.internal \
    --api-address           0.0.0.0 \
    --seed-provider-class-name \
        org.apache.cassandra.locator.SimpleSeedProvider \
    --seed 127.0.0.1 \
    --authenticator AllowAllAuthenticator \
    --authorizer   AllowAllAuthorizer
