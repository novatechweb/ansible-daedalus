FROM ubuntu:14.04

#ENV HTTPD_PREFIX /usr/local/apache2
#ENV PATH $PATH:$HTTPD_PREFIX/bin
#RUN mkdir -p "$HTTPD_PREFIX" && \
#	chown www-data:www-data "$HTTPD_PREFIX"

#---------------------------
RUN apt-get update  && \
    apt-get install -y --no-install-recommends \
                    gcc=4:4* \
                    apache2=2.4.7* \
                    libapache2-mod-wsgi=3.4* \
                    libapache2-mod-xsendfile=0.12* \
                    mysql-client=5.5* \
                    libmysqlclient-dev=5.5* \
                    python-pip=1.5* \
                    python-setuptools=3.3* \
                    libpython-dev=2.7* \
                    genisoimage=9:1* && \
    rm -rf /var/lib/apt/lists/*
#---------------------------
RUN rm -rf /var/www/html && \
    mkdir -p /var/lock/apache2 \
             /var/run/apache2 \
             /var/log/apache2 \
             /var/www/html && \ 
    chown -R www-data:www-data /var/lock/apache2 \
                               /var/run/apache2 \
                               /var/log/apache2 \
                               /var/www/html
#---------------------------
RUN pip install "django<1.8" \
                "mysqlclient>=1.3" \
                "pyserial>=2.7" \
                "sqlparse<0.3"
#---------------------------

COPY ./config_files/httpd.conf   /etc/apache2/conf-available/httpd.conf
COPY ./config_files/apache2.conf /etc/apache2/apache2.conf
RUN /usr/sbin/a2enconf httpd
RUN /usr/sbin/a2disconf charset \
                        localized-error-pages \
                        other-vhosts-access-log \
                        security serve-cgi-bin

COPY httpd-foreground /usr/local/bin/
WORKDIR /var/www/html
EXPOSE 80

CMD ["httpd-foreground"]
