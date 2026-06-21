FROM scylladb/scylla:2025.1.13

# Real scylla.yaml, not CLI-flag translation -- testing whether
# /etc/hosts + enable_ipv6_dns_lookup actually works through this
# genuinely different config path.
COPY scylla.yaml /etc/scylla/scylla.yaml
COPY entrypoint.sh /koda-entrypoint.sh
RUN chmod +x /koda-entrypoint.sh

ENTRYPOINT ["/koda-entrypoint.sh"]
