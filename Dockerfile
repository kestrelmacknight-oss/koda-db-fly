# Koda — self-hosted LiveKit voice/video server for Fly.io
#
# Uses LiveKit's official prebuilt image. We only add a config template
# and an entrypoint that injects the API key/secret from Fly secrets
# at container startup -- the key is never baked into the image.

FROM livekit/livekit-server:v1.7.2

COPY livekit.yaml.template /etc/livekit.yaml.template
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
