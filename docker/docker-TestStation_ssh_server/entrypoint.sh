#!/bin/bash

# chown tftp:tftp "/opt/tftp_files"

DIRECTORIES=(/opt/ipkg /opt/iso_temp_files /opt/ncd_release /opt/protocol /opt/test_client_files)
for directory in ${DIRECTORIES[*]} 
do
    if [ -d  $directory ]; then
        chown www-data:www-data $directory
    fi
done

case ${1} in 
    sshd)
        exec /usr/sbin/sshd -D
    ;;

    *)
        exec "$@"
    ;;

esac

