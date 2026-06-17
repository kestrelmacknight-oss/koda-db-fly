# Koda LiveKit -- Self-hosted voice/video server for Fly.io

## What this is

A self-hosted LiveKit server, deployed as its own Fly.io app (`koda-livekit`),
separate from `koda-server` (Phoenix) and `koda-scylla` (ScyllaDB).

Important correction from earlier guidance: this version uses the SAME two
secret names on both koda-livekit and koda-server -- LIVEKIT_API_KEY and
LIVEKIT_API_SECRET. If you previously set a secret called LIVEKIT_KEYS on
koda-livekit, that was an earlier draft of the instructions and is no longer
needed with these files -- just use LIVEKIT_API_KEY / LIVEKIT_API_SECRET
consistently everywhere.

## Step-by-step deploy

### 1. Create the app

    fly apps create koda-livekit

### 2. Allocate a dedicated public IPv4

LiveKit needs a real, dedicated public IP for WebRTC media (UDP) to work
reliably. Fly's default shared anycast IPv4 is fine for plain HTTP/HTTPS
but is not reliable for UDP voice/video traffic.

    fly ips allocate-v4 --app koda-livekit

This may have a small monthly cost (a couple dollars) -- check current
Fly.io pricing for dedicated IPv4 addresses.

### 3. Generate your API key and secret

Pick any key name -- "kodakey" is fine. Generate a strong secret:

    openssl rand -hex 32

Copy the output. You'll use this exact value in two places (step 4 and
the matching koda-server secret in step 5).

### 4. Set the secrets on koda-livekit

    fly secrets set \
      LIVEKIT_API_KEY="kodakey" \
      LIVEKIT_API_SECRET="PASTE_YOUR_GENERATED_SECRET_HERE" \
      --app koda-livekit

### 5. Set the matching secrets on koda-server

These must be IDENTICAL to what you set in step 4 -- same key name,
same secret value. Phoenix uses these to sign tokens that LiveKit
then validates.

    fly secrets set \
      LIVEKIT_API_KEY="kodakey" \
      LIVEKIT_API_SECRET="PASTE_SAME_SECRET_HERE" \
      LIVEKIT_PUBLIC_URL="wss://voice.koda.fyi" \
      --app koda-server

### 6. Deploy

    fly deploy --app koda-livekit

### 7. Add DNS for voice.koda.fyi

In Cloudflare DNS:

    Type:   CNAME
    Name:   voice
    Target: koda-livekit.fly.dev
    Proxy:  ON (orange cloud)

Then register the cert with Fly:

    fly certs add voice.koda.fyi --app koda-livekit

Check cert status (may take a few minutes to issue):

    fly certs check voice.koda.fyi --app koda-livekit

### 8. Verify it's running

    fly logs --app koda-livekit

You should see a line like:

    [koda-livekit] Starting LiveKit server with key: kodakey
    INFO livekit server is starting ...

### 9. Redeploy koda-server to pick up the new secrets

    fly deploy --app koda-server

## Testing voice end-to-end

1. Open Koda on two different machines (or one machine + a friend)
2. Both join the same server
3. Both join the same voice channel
4. Confirm audio works in both directions

If signaling connects (you see other participants) but no audio
flows, it's almost always the UDP/public-IP issue -- double check:

    fly ips list --app koda-livekit

You should see a dedicated v4 address listed (not "shared"). If it
still doesn't work, the TCP fallback on port 7881 should kick in
automatically -- audio will work but with slightly higher latency.

## Files in this package

    Dockerfile               -- builds from livekit/livekit-server:v1.7.2
    livekit.yaml.template     -- LiveKit config, key/secret injected at boot
    entrypoint.sh              -- substitutes secrets into the config, starts server
    fly.toml                   -- Fly app config: signaling, TCP fallback, UDP media

## Reference: matching key table

| App           | Variable             | Value                          |
|---------------|----------------------|---------------------------------|
| koda-livekit  | LIVEKIT_API_KEY       | kodakey                        |
| koda-livekit  | LIVEKIT_API_SECRET    | (your generated secret)        |
| koda-server   | LIVEKIT_API_KEY       | kodakey (same as above)        |
| koda-server   | LIVEKIT_API_SECRET    | (same secret as above)         |
| koda-server   | LIVEKIT_PUBLIC_URL    | wss://voice.koda.fyi           |
