#!/bin/bash

CONFIG_PATH=/etc/exim4

# if the config directory is empty load up the debain default configuration files
if [[ "$(cd ${CONFIG_PATH};ls -1)" == '' ]]; then
    echo >&2 "Use the default configuration"
    tar -xavf /demian.default.exim4.config.tar.gz -C /etc 
fi

# Make certain the directory exists for storing the PID files
[ -e /var/run/exim4 ] || \
    install -d -oDebian-exim -gDebian-exim -m750 /var/run/exim4

# Specify the permissions of the mounted volumes and their subdirectories
chown Debian-exim:Debian-exim ${CONFIG_PATH}
chown -R Debian-exim:Debian-exim /var/spool/exim4
chown -R Debian-exim:adm /var/log/exim4
chown -R root:mail /var/mail

case ${1} in
    exim4)
        if   [[ -f ${CONFIG_PATH}/update-exim4.conf.conf ]] \
          && [[ ! -f ${CONFIG_PATH}/exim4.conf ]]
        then
            # set the hostname
            echo "${HOSTNAME}" > /etc/mailname
            # set local IP addr
            LOCAL_IP_ADDR=$(getent hosts $HOSTNAME | cut -d ' ' -f 1)
            sed -i 's|dc_local_interfaces=.*|dc_local_interfaces='"'${LOCAL_IP_ADDR}'"'|' ${CONFIG_PATH}/update-exim4.conf.conf
            # copy certificate
            [ -e /etc/ssl/private/exim.crt ] \
                && install -oroot -gDebian-exim -m640 $(realpath /etc/ssl/private/exim.crt) ${CONFIG_PATH}/exim.crt
            # copy key
            [ -e /etc/ssl/private/exim.key ] \
                && install -oroot -gDebian-exim -m640 $(realpath /etc/ssl/private/exim.key) ${CONFIG_PATH}/exim.key
            # run the debian utility to update/generate the configuration
            $(which update-exim4.conf) --verbose
        fi
        
        # Check configuration
        if ! /usr/sbin/exim4 -bV > /dev/null ; then
          echo >&2 "Warning! Invalid configuration file for exim4. Exiting."
          exit 1
        fi
        shift
        echo >&2 "starting exim4"
        exec /usr/sbin/exim4 ${@:--bdf -q30m}
        ;;

    add_account)
        # Also can use:
        # /usr/share/doc/exim4-base/examples/exim-adduser
        shift
        if [[ -z "${1}" ]] || [[ -z "${2}" ]]; then
            echo >&2 "add_account requires a username and a password argument"
            exit 1
        fi
        touch ${CONFIG_PATH}/passwd
        chmod 640 ${CONFIG_PATH}/passwd
        chown root:Debian-exim ${CONFIG_PATH}/passwd
        # remove any occurance of username already in the passwd file
        if grep -q "^${1}[:]" ${CONFIG_PATH}/passwd; then
            sed -i "/^${1}[:].*$/d"  ${CONFIG_PATH}/passwd
        fi
        echo "${1}:$(echo "${2}"|mkpasswd -H md5 --stdin):${2}" >> ${CONFIG_PATH}/passwd
        sort ${CONFIG_PATH}/passwd
        ;;

    backup)
        cd ${CONFIG_PATH}
        /bin/tar \
            --create \
            --preserve-permissions \
            --same-owner \
            --directory=${CONFIG_PATH} \
            --to-stdout \
            ./*
        ;;

    restore)
        echo >&2 "Remove previous config"
        rm -rf ${CONFIG_PATH}/*
        echo >&2 "Extract the archive"
        /bin/tar \
            --extract \
            --preserve-permissions \
            --preserve-order \
            --same-owner \
            --directory=${CONFIG_PATH} \
            -f -
        echo >&2 "Set permissions"
        chown -R Debian-exim:Debian-exim ${CONFIG_PATH}
        ;;

    *)
        # run some other command in the docker container
        exec "$@"
        ;;
esac
