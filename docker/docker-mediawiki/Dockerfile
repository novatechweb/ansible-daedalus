#
# mediawiki Docker container
#
# Version 0.1

FROM php:5.6-apache
MAINTAINER Joseph Lutz <Joseph.Lutz@novatechweb.com>

ENV MEDIAWIKI_VERSION 1.25.1
# Extension links are hard coded for particular version of mediawiki

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
        git \
        imagemagick \
        libicu-dev \
        libldap2-dev \
    && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu && \
    docker-php-ext-install intl mysqli opcache ldap && \
    DEBIAN_FRONTEND=noninteractive apt-get purge --yes \
        autoconf \
        build-essential \
        libicu-dev \
        libldap2-dev \
    && \
    rm -rf /var/www/html/index.html && \
    DEBIAN_FRONTEND=noninteractive apt-get autoremove --yes && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# install MediaWIKI:   https://www.mediawiki.org/wiki/Download
# install the LDAP Authentication Extension:   http://www.mediawiki.org/wiki/Extension:LDAP_Authentication
# install the UserMerge Extension:   http://www.mediawiki.org/wiki/Extension:UserMerge
# Extension links are hard coded for particular version of mediawiki
RUN mkdir -p /usr/src/mediawiki /var/www-shared/html && \
    curl "https://releases.wikimedia.org/mediawiki/${MEDIAWIKI_VERSION%.*}/mediawiki-${MEDIAWIKI_VERSION}.tar.gz" | \
        tar xzC /usr/src/mediawiki --strip-components=1 && \
    curl "https://extdist.wmflabs.org/dist/extensions/LdapAuthentication-REL1_23-f266c74.tar.gz" | \
        tar xzC /usr/src/mediawiki/extensions && \
    curl "https://extdist.wmflabs.org/dist/extensions/UserMerge-REL1_23-78f61ac.tar.gz" | \
        tar xzC /usr/src/mediawiki/extensions && \
    curl "https://extdist.wmflabs.org/dist/extensions/Renameuser-REL1_23-469785d.tar.gz" | \
        tar xzC /usr/src/mediawiki/extensions

# copy over files
COPY \
    config/000-default-ssl.conf \
    config/000-default.conf \
    config/000-wiki.conf \
        /etc/apache2/sites-available/
COPY ./docker-entrypoint.sh \
    ./configure.sh \
        /

# run the configuration script
RUN ["/bin/bash", "/configure.sh"]

# specify which network ports will be used
EXPOSE 80 443

# specify the volumes directly related to this image
VOLUME ["/var/www/html"]

# start the entrypoint script
WORKDIR /var/www/html
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["wiki"]
