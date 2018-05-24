#
# mantisbt Docker container
#
# Version 0.1

FROM php:5.6-apache
MAINTAINER Joseph Lutz <Joseph.Lutz@novatechweb.com>

ENV MANTISBT_VERSION 1.2.19

#         ttf-mscorefonts-installer

RUN sed -i 's| main$| main contrib non-free|' /etc/apt/sources.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
        libcurl3 \
        libjpeg62-turbo \
        libmcrypt4 \
        libpq5 \
        libcurl4-openssl-dev \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libldap2-dev \
        libmcrypt-dev \
        libpng-dev \
        libpq-dev \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu \
    && docker-php-ext-configure gd --with-png-dir=/usr --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install intl mbstring mysql mysqli pgsql opcache ldap iconv mcrypt gd curl fileinfo \
    && DEBIAN_FRONTEND=noninteractive apt-get purge --yes \
        autoconf \
        build-essential \
        libcurl4-openssl-dev \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libldap2-dev \
        libmcrypt-dev \
        libpng12-dev \
        libpq-dev \
    && rm -rf /var/www/html/index.html \
    && DEBIAN_FRONTEND=noninteractive apt-get autoremove --yes \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# download and extract mantisbt
RUN mkdir -p /usr/src/mantisbt /var/www-shared/html && \
    curl -L "http://downloads.sourceforge.net/project/mantisbt/mantis-stable/${MANTISBT_VERSION}/mantisbt-${MANTISBT_VERSION}.tar.gz" | \
        tar xzC /usr/src/mantisbt --strip-components=1

# copy over files
COPY \
    config/000-default-ssl.conf \
    config/000-default.conf \
    config/000-mantisbt.conf \
        /etc/apache2/sites-available/
COPY config/php.ini /usr/local/etc/php/
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
CMD ["mantisbt"]
