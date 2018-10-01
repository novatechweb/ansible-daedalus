#
# exim4 Docker container
#
# Version 0.1

FROM debian:latest
MAINTAINER Joseph Lutz <Joseph.Lutz@novatechweb.com>

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
        ca-certificates \
        dnsutils \
        exim4-daemon-heavy \
        libnet-ssleay-perl \
        mailutils \
        openssl \
        spf-tools-perl \
        swaks \
        whois \
    && rm -rf /var/lib/apt/lists/*

# copy over files
COPY docker-entrypoint.sh /
COPY etc/ /etc/
RUN update-exim4.conf

# specify which network ports will be used
EXPOSE 25 465 587

# specify the volumes directly related to this image
VOLUME ["/var/spool/exim4"]

# start the entrypoint script
WORKDIR /var/spool/exim4
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["exim4"]
