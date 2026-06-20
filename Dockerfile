FROM scylladb/scylla:2025.1.13

# Copy custom entrypoint that handles Fly.io's private network addressing
COPY entrypoint.sh /koda-entrypoint.sh
RUN chmod +x /koda-entrypoint.sh

ENTRYPOINT ["/koda-entrypoint.sh"]
