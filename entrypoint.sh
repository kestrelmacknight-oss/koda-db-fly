#!/bin/bash
# ScyllaDB entrypoint for Fly.io
#
# listen-address / rpc-address are deliberately NOT set to Fly's
# private IPv6 address (FLY_PRIVATE_IP). Scylla's bundled c-ares
# resolver has proven unreliable parsing that literal -- the same
# exact value has failed resolution on listen-address on one boot and
# broadcast-address on another, even with a startup delay added. That
# rules out a timing race; it's the resolver itself struggling with
# this address format.
#
# Fix: sidestep address resolution entirely.
#   - listen-address: 127.0.0.1 -- only used for this node's own
#     internal gossip protocol. Irrelevant for a single, standalone
#     node with no clustering, so loopback is fine and never needs
#     any external resolution.
#   - rpc-address: 0.0.0.0 -- binds the CQL listener to every
#     interface, including Fly's private IPv6 address. Phoenix
#     reaches this node via koda-db-fly.internal:9042, which Fly's
#     own DNS resolves independently of anything happening in this
#     container -- the troublesome literal never has to be parsed by
#     Scylla itself at all.

set -e

SMP="${SCYLLA_SMP:-2}"
MEMORY="${SCYLLA_MEMORY:-1500M}"

echo "[koda-entrypoint] Starting ScyllaDB -- smp=$SMP memory=$MEMORY"
echo "[koda-entrypoint] listen-address=127.0.0.1 (internal only) rpc-address=0.0.0.0 (all interfaces)"

exec /docker-entrypoint.py \
    --smp           "$SMP" \
    --memory        "$MEMORY" \
    --overprovisioned 1 \
    --listen-address 127.0.0.1 \
    --rpc-address    0.0.0.0 \
    --api-address    0.0.0.0 \
    --seed-provider-class-name \
        org.apache.cassandra.locator.SimpleSeedProvider \
    --seed 127.0.0.1 \
    --authenticator AllowAllAuthenticator \
    --authorizer   AllowAllAuthorizer
