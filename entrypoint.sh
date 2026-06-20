#!/bin/bash
# ScyllaDB entrypoint for Fly.io
#
# broadcast_rpc_address resolution has now failed against every kind
# of input tried: raw IPv6 (unparseable), bracketed IPv6 (also
# unparseable), a fake hostname (real DNS correctly refuses an
# unregistered name), and the REAL koda-db-fly.internal hostname
# (still refused) -- meaning whatever DNS server Scylla's bundled
# c-ares is configured to query is unreachable from inside this
# container, for any lookup at all. Hostname-based resolution is a
# dead end here, regardless of which name is used.
#
# Falling back to 127.0.0.1 for broadcast-rpc-address. This is the
# one literal that's resolved cleanly on every attempt today. For a
# single, non-clustered node, broadcast_rpc_address exists so Scylla
# can advertise itself to clients doing peer discovery -- irrelevant
# here, since Phoenix connects directly via koda-db-fly.internal:9042
# (resolved by Fly's real DNS, entirely independent of anything
# Scylla reports about itself). The actual value here just needs to
# satisfy Scylla's own startup validation, not be externally routable.

set -e

SMP="${SCYLLA_SMP:-2}"
MEMORY="${SCYLLA_MEMORY:-1500M}"

echo "[koda-entrypoint] Starting ScyllaDB -- smp=$SMP memory=$MEMORY"
echo "[koda-entrypoint] broadcast-rpc-address=127.0.0.1 (satisfies startup validation only -- real client connections go via koda-db-fly.internal, unaffected by this value)"

exec /docker-entrypoint.py \
    --smp           "$SMP" \
    --memory        "$MEMORY" \
    --overprovisioned 1 \
    --listen-address       127.0.0.1 \
    --rpc-address           0.0.0.0 \
    --broadcast-rpc-address 127.0.0.1 \
    --api-address           0.0.0.0 \
    --seed-provider-class-name \
        org.apache.cassandra.locator.SimpleSeedProvider \
    --seed 127.0.0.1 \
    --authenticator AllowAllAuthenticator \
    --authorizer   AllowAllAuthorizer
