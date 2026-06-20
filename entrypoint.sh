#!/bin/bash
# ScyllaDB entrypoint for Fly.io
#
# listen-address (127.0.0.1, IPv4) and rpc-address (::, IPv6) were
# mismatched address families for the same single node -- this likely
# explains the periodic restart cycle observed: gossip rounds failing
# intermittently (seastar::gate_closed_exception) every ~15-20
# minutes, followed by a clean self-shutdown and supervisord restart.
# Switching listen-address to ::1 (IPv6 loopback) makes every address
# field consistently IPv6, matching rpc-address and removing the
# cross-family inconsistency.

set -e

SMP="${SCYLLA_SMP:-2}"
MEMORY="${SCYLLA_MEMORY:-1500M}"

echo "[koda-entrypoint] Starting ScyllaDB -- smp=$SMP memory=$MEMORY"
echo "[koda-entrypoint] All addresses now consistently IPv6 (listen=::1, rpc=::, broadcast-rpc=::1)"

exec /docker-entrypoint.py \
    --smp           "$SMP" \
    --memory        "$MEMORY" \
    --overprovisioned 1 \
    --listen-address       ::1 \
    --rpc-address           :: \
    --broadcast-rpc-address ::1 \
    --api-address           0.0.0.0 \
    --seed-provider-class-name \
        org.apache.cassandra.locator.SimpleSeedProvider \
    --seed ::1 \
    --authenticator AllowAllAuthenticator \
    --authorizer   AllowAllAuthorizer
