#!/bin/bash
# ScyllaDB entrypoint for Fly.io
#
# broadcast-rpc-address must be the real Fly private address so
# Phoenix can actually reach this node -- but every attempt to give
# Scylla that address as a literal IPv6 string has failed resolution
# (plain and bracketed both fail with the same C-Ares "Bad name").
# 127.0.0.1 resolved cleanly for listen-address, and a real hostname
# would also need to go through genuine resolution -- so instead of
# fighting the "is this already an IP" parsing path, this maps the
# real address to a plain hostname in /etc/hosts (resolved locally,
# no network involved) and gives Scylla that hostname instead.

set -e

if [ -n "$FLY_PRIVATE_IP" ]; then
    PRIVATE_ADDR="$FLY_PRIVATE_IP"
else
    PRIVATE_ADDR=$(hostname -I | awk '{print $1}')
fi

echo "$PRIVATE_ADDR koda-broadcast" >> /etc/hosts

SMP="${SCYLLA_SMP:-2}"
MEMORY="${SCYLLA_MEMORY:-1500M}"

echo "[koda-entrypoint] Starting ScyllaDB -- smp=$SMP memory=$MEMORY"
echo "[koda-entrypoint] broadcast-rpc-address=koda-broadcast -> $PRIVATE_ADDR (via /etc/hosts)"

exec /docker-entrypoint.py \
    --smp           "$SMP" \
    --memory        "$MEMORY" \
    --overprovisioned 1 \
    --listen-address       127.0.0.1 \
    --rpc-address           0.0.0.0 \
    --broadcast-rpc-address koda-broadcast \
    --api-address           0.0.0.0 \
    --seed-provider-class-name \
        org.apache.cassandra.locator.SimpleSeedProvider \
    --seed 127.0.0.1 \
    --authenticator AllowAllAuthenticator \
    --authorizer   AllowAllAuthorizer
