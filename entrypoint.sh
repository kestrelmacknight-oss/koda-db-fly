#!/bin/bash
# ScyllaDB entrypoint for Fly.io
#
# rpc-address was 0.0.0.0 (IPv4 wildcard) -- which is why cqlsh over
# loopback (IPv4) worked perfectly while koda-server's connection
# attempt over Fly's IPv6-only private network (6PN) got
# econnrefused. Nothing was actually listening on the IPv6 side at
# all. Switched to "::" (the IPv6 wildcard), which accepts inbound
# connections on every IPv6 interface, including Fly's private
# network -- this is the actual fix for cross-app connectivity.
#
# listen-address stays 127.0.0.1 (gossip-only, irrelevant for a
# single node). broadcast-rpc-address stays 127.0.0.1 too -- Scylla
# still requires it whenever rpc-address is a wildcard (true for "::"
# same as it was for 0.0.0.0), and its value still doesn't matter
# functionally since Phoenix connects directly via DNS, not via
# Scylla's self-reported broadcast address.

set -e

SMP="${SCYLLA_SMP:-2}"
MEMORY="${SCYLLA_MEMORY:-1500M}"

echo "[koda-entrypoint] Starting ScyllaDB -- smp=$SMP memory=$MEMORY"
echo "[koda-entrypoint] rpc-address=:: (IPv6 wildcard -- required for Fly's private network)"

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
