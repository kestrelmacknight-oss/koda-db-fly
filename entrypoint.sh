#!/bin/sh
# Koda LiveKit entrypoint.
# Substitutes LIVEKIT_API_KEY / LIVEKIT_API_SECRET (set via fly secrets)
# into the config template, then starts the LiveKit server.

set -e

: "${LIVEKIT_API_KEY:?LIVEKIT_API_KEY must be set. Run: fly secrets set LIVEKIT_API_KEY=... --app koda-livekit}"
: "${LIVEKIT_API_SECRET:?LIVEKIT_API_SECRET must be set. Run: fly secrets set LIVEKIT_API_SECRET=... --app koda-livekit}"

sed -e "s|__API_KEY__|${LIVEKIT_API_KEY}|" \
    -e "s|__API_SECRET__|${LIVEKIT_API_SECRET}|" \
    /etc/livekit.yaml.template > /etc/livekit.yaml

echo "[koda-livekit] Starting LiveKit server with key: ${LIVEKIT_API_KEY}"

exec /livekit-server --config /etc/livekit.yaml
