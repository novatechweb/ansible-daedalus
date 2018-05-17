#!/bin/bash
set -e

# Create certificate directories
mkdir -p /etc/grid-security/certificates
mkdir -p /etc/ssl/certs/
mkdir -p /etc/ssl/private

# comment out apache2 config file lines that reference the environment variables
sed -i 's|^Mutex file|#Mutex file|' /etc/apache2/apache2.conf
sed -i 's|^PidFile |#PidFile |' /etc/apache2/apache2.conf
sed -i 's|^User |#User |' /etc/apache2/apache2.conf
sed -i 's|^Group |#Group |' /etc/apache2/apache2.conf
sed -i 's|^ErrorLog |#ErrorLog |' /etc/apache2/apache2.conf

# place the hard coded environment variables
cat << EOF >> /etc/apache2/apache2.conf

# hard code the environment variables
Mutex file:/var/lock/apache2 default
PidFile /var/run/apache2/apache2.pid
User www-data
Group www-data
ErrorLog /proc/self/fd/2
CustomLog /proc/self/fd/1 combined
EOF

sed -i 's|^CustomLog.*|CustomLog /proc/self/fd/1 combined|' /etc/apache2/conf-available/other-vhosts-access-log.conf

# set the SSLSessionCache directory
sed -i 's|\$[{]APACHE_RUN_DIR[}]|/var/run/apache2|' /etc/apache2/mods-available/ssl.conf

# create apache domainname config
echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf
a2enconf servername.conf

# enable modules
a2enmod \
  rewrite \
  ssl

# Enable the site
a2ensite \
  000-default-ssl.conf \
  000-default.conf \
  000-mantisbt.conf

rm -f /var/www/html/index.html ${0}
