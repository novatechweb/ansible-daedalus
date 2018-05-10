#
# openssl Docker container
#
# Version 0.0

FROM debian:latest

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
    openssl && \
  rm -rf /var/lib/apt/lists/*

# copy over files
COPY ./docker-entrypoint.sh /

# create the openssl directory volumes
VOLUME ["/etc/ssl/private"]

ENTRYPOINT ["/docker-entrypoint.sh"]
