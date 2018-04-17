#
# LDAP Docker container
#
# Version 0.1

#FROM debian:8
FROM ubuntu:14.04
MAINTAINER Joseph Lutz <Joseph.Lutz@novatechweb.com>

ENV OPENLDAP_VERSION 2.4

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
        ldap-utils=${OPENLDAP_VERSION}* \
        slapd=${OPENLDAP_VERSION}* \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# backup distribution ldap config and delete the config
RUN \
  cd /etc && \
  tar -cavf /etc/ldap.tar.gz ldap && \
  rm -rf /etc/ldap /var/lib/ldap

# copy over files
COPY ./docker-entrypoint.sh /
COPY ./config/config.ldif /etc/

# specify which network ports will be used
EXPOSE 389 636

# specify the volumes directly related to this image
VOLUME ["/etc/ldap", "/var/lib/ldap"]

# start the entrypoint script
WORKDIR /var/lib/ldap
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["openldap"]
