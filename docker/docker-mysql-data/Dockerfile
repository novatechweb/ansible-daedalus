#
# mysql-data Docker container
#
# Version 0.1

FROM mysql
MAINTAINER Joseph Lutz <Joseph.Lutz@novatechweb.com>

# copy wrapper script
COPY ./import_configuration_wrapper.sh /

# specify the volumes directly related to this image
VOLUME ["/var/lib/mysql", "/etc/mysql/conf.d"]

# start the entrypoint script
ENTRYPOINT ["/import_configuration_wrapper.sh"]
