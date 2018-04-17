#
# openssl Docker container
#
# Version 0.0

FROM debian:8
MAINTAINER Joseph Lutz <Joseph.Lutz@novatechweb.com>

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
    openssl \
    ca-certificates && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# copy over files
COPY ./docker-entrypoint.sh /

# create the openssl directory volumes
VOLUME ["/etc/ssl", "/usr/share/ca-certificates", "/usr/local/share/ca-certificates", "/etc/grid-security"]

ENTRYPOINT ["/docker-entrypoint.sh"]
