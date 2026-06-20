#!/bin/bash
# ScyllaDB entrypoint for Fly.io
#
# The raw-literal-IPv6 resolution failure for broadcast_address /
# broadcast_rpc_address has now been confirmed on BOTH 6.2.3 and the
# 2025.1 LTS line with identical error text -- this is not a recent
# regression that version-bumping fixes, it appears to be a
# longstanding quirk in how these specific fields get resolved.
#
# listen-address=127.0.0.1 has resolved cleanly on every attempt.
# rpc-address=0.0.0.0 is accepted but requires broadcast-rpc-address
# to be explicitly set. Routing broadcast-rpc-address through a real
# hostname (resolved locally via /etc/hosts, never touching the
# literal-IP code path that's been failing) got further than any
# other attempt on 6.2.3 -- past every resolution error, only
# segfaulting afterward. Retesting that exact combination here on
# 2025.1.13 to see if the crash itself is fixed on this version even
# if the underlying literal-IP quirk persists.

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
