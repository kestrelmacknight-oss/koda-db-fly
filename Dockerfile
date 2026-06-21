FROM scylladb/scylla:2025.1.13

# The scylla binary looks for a RELATIVE path "conf/scylla.yaml" from
# wherever it's launched -- not an absolute path. Placing our config
# at /scylla-config/conf/scylla.yaml and cd'ing there before launch
# (in entrypoint.sh) makes that relative path resolve correctly.
RUN mkdir -p /scylla-config/conf
COPY scylla.yaml /scylla-config/conf/scylla.yaml
COPY entrypoint.sh /koda-entrypoint.sh
RUN chmod +x /koda-entrypoint.sh

ENTRYPOINT ["/koda-entrypoint.sh"]
