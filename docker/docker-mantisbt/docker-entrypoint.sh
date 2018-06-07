#!/bin/bash
set -e

# ************************************************************
# Options passed to the docker container to run scripts
# ************************************************************
# mantisbt: Starts apache running. This is the containers default
# lock    : Set MantisBT to read-only
# unlock  : Set MantisBT to read-write
# backup  : backup the mantisbt static files
# restore : import the mantisbt static files archive

# ************************************************************
# environment variables
# ************************************************************
# MANTISBT_HOSTNAME      : Sets the hostname in the apache2 config
# MANTISBT_DB_DB_NAME    : MANTISBT_DB_DB_NAME,  MANTISBT_DB_ENV_MYSQL_DATABASE | MANTISBT_DB_ENV_POSTGRES_DB,       config_inc.php ( $g_database_name )
# MANTISBT_DB_USER       : MANTISBT_DB_USER,     MANTISBT_DB_ENV_MYSQL_USER | MANTISBT_DB_ENV_POSTGRES_USER,         config_inc.php ( $g_db_username )
# MANTISBT_DB_PASSWORD   : MANTISBT_DB_PASSWORD, MANTISBT_DB_ENV_MYSQL_PASSWORD | MANTISBT_DB_ENV_POSTGRES_PASSWORD, config_inc.php ( $g_db_password )
# MANTISBT_MAIL_USER     : MANTISBT_MAIL_USER,     config_inc.php ( $g_smtp_username )
# MANTISBT_MAIL_PASSWORD : MANTISBT_MAIL_PASSWORD, config_inc.php ( $g_smtp_password )
# MANTISBT_LDAP_PASSWORD : MANTISBT_LDAP_PASSWORD, config_inc.php ( $g_ldap_bind_passwd )

if [[ ! -z "${MANTISBT_DB_ENV_MYSQL_VERSION}" ]]; then
    MANTISBT_DB_DB_NAME=${MANTISBT_DB_DB_NAME:-${MANTISBT_DB_ENV_MYSQL_DATABASE}}
    MANTISBT_DB_USER=${MANTISBT_DB_USER:-${MANTISBT_DB_ENV_MYSQL_USER}}
    MANTISBT_DB_PASSWORD=${MANTISBT_DB_PASSWORD:-${MANTISBT_DB_ENV_MYSQL_PASSWORD}}
elif [[ ! -z "${MANTISBT_DB_ENV_PG_VERSION}" ]];then
    MANTISBT_DB_DB_NAME=${MANTISBT_DB_DB_NAME:-${MANTISBT_DB_ENV_POSTGRES_DB}}
    MANTISBT_DB_USER=${MANTISBT_DB_USER:-${MANTISBT_DB_ENV_POSTGRES_USER}}
    MANTISBT_DB_PASSWORD=${MANTISBT_DB_PASSWORD:-${MANTISBT_DB_ENV_POSTGRES_PASSWORD}}
fi


MANTISBT_BASE_DIR=$(pwd)

lock_mantisbt() {
    # set mantisbt to readonly if not already
    cp ${MANTISBT_BASE_DIR}/mantis_offline.php.sample ${MANTISBT_BASE_DIR}/mantis_offline.php
    echo >&2 "MantisBT locked to read-only mode"
    # wait for any transactions to compleate
    sleep 5
}

unlock_mantisbt() {
    # set MantisBT to read/write
    rm -f ${MANTISBT_BASE_DIR}/mantis_offline.php
    echo >&2 "MantisBT unlocked to read-write mode"
}

if [[ $(ls -A1 ${MANTISBT_BASE_DIR} | wc -l) == '0' ]]; then
    # initial setup of mantisbt
    if [[ ! -e ${MANTISBT_BASE_DIR}/index.php ]] || [[ ! -e ${MANTISBT_BASE_DIR}/config_inc.php ]]; then
        echo >&2 "Installing Mantis Bug Tracker into ${MANTISBT_BASE_DIR} - copying now..."
        tar cf - --one-file-system -C /usr/src/mantisbt . | tar xf -
    fi
fi

# Set the server name
if [[ ! -z "${MANTISBT_HOSTNAME}" ]]; then
    # change any value of MANTISBT_HOSTNAME to the value
    sed -i 's|MANTISBT_HOSTNAME|'${MANTISBT_HOSTNAME}'|' \
        /etc/apache2/sites-available/000-default-ssl.conf \
        /etc/apache2/sites-available/000-default.conf
    # update the ServerName line
    sed -i 's|ServerName .*$|ServerName '${MANTISBT_HOSTNAME}'|' \
        /etc/apache2/sites-available/000-default-ssl.conf \
        /etc/apache2/sites-available/000-default.conf
fi
update_config_inc() {
    # update config_inc.php with environment var values
    if [[ -w ${MANTISBT_BASE_DIR}/config_inc.php ]]; then
        echo >&2 "Updating config_inc.php"
        sed -i 's|$g_hostname\( *= \).*|$g_hostname\1'"'mantisbt_db'"';|' ${MANTISBT_BASE_DIR}/config_inc.php
        if [[ ! -z "${MANTISBT_DB_ENV_MYSQL_VERSION}" ]]; then
            sed -i 's|$g_db_type\( *= \).*|$g_db_type\1'"'mysql'"';|' ${MANTISBT_BASE_DIR}/config_inc.php
        elif [[ ! -z "${MANTISBT_DB_ENV_PG_VERSION}" ]]; then
            sed -i 's|$g_db_type\( *= \).*|$g_db_type\1'"'postgres'"';|' ${MANTISBT_BASE_DIR}/config_inc.php
        fi
        if [[ ! -z "${MANTISBT_DB_DB_NAME}" ]]; then \
            sed -i 's|$g_database_name\( *= \).*|$g_database_name\1'"'${MANTISBT_DB_DB_NAME}'"';|' ${MANTISBT_BASE_DIR}/config_inc.php
        fi
        if [[ ! -z "${MANTISBT_DB_USER}" ]]; then \
            sed -i 's|$g_db_username\( *= \).*|$g_db_username\1'"'${MANTISBT_DB_USER}'"';|' ${MANTISBT_BASE_DIR}/config_inc.php
        fi
        if [[ ! -z "${MANTISBT_DB_PASSWORD}" ]]; then \
            sed -i 's|$g_db_password\( *= \).*|$g_db_password\1'"'${MANTISBT_DB_PASSWORD}'"';|' ${MANTISBT_BASE_DIR}/config_inc.php
        fi
        if [[ ! -z "${MANTISBT_MAIL_USER}" ]] && grep -q 'g_smtp_username' ${MANTISBT_BASE_DIR}/config_inc.php ; then \
            sed -i 's|$g_smtp_username\( *= \).*|$g_smtp_username\1'"'${MANTISBT_MAIL_USER}'"';|' ${MANTISBT_BASE_DIR}/config_inc.php
        fi
        if [[ ! -z "${MANTISBT_MAIL_PASSWORD}" ]] && grep -q 'g_smtp_password' ${MANTISBT_BASE_DIR}/config_inc.php ; then \
            sed -i 's|$g_smtp_password\( *= \).*|$g_smtp_password\1'"'${MANTISBT_MAIL_PASSWORD}'"';|' ${MANTISBT_BASE_DIR}/config_inc.php
        fi
        if [[ ! -z "${MANTISBT_LDAP_PASSWORD}" ]] && grep -q 'g_ldap_bind_passwd' ${MANTISBT_BASE_DIR}/config_inc.php ; then \
            sed -i 's|$g_ldap_bind_passwd\( *= \).*|$g_ldap_bind_passwd\1'"'${MANTISBT_LDAP_PASSWORD}'"';|' ${MANTISBT_BASE_DIR}/config_inc.php
        fi
    fi
    # uploads are not configured by default. Make a directory for where uploads are located
    mkdir -p /var/www/html/uploads
    chown -R www-data:www-data /var/www/html/uploads/
}
update_config_inc

case ${1} in
    mantisbt)
        # verify permissions
        chown -R www-data:www-data ${MANTISBT_BASE_DIR}
        # Apache gets grumpy about PID files pre-existing
        rm -f /var/run/apache2/apache2.pid
        # Start apache
        exec apache2 -D FOREGROUND
        ;;

    config_inc)
        cat > ${MANTISBT_BASE_DIR}/config_inc.php
        chown -R www-data:www-data ${MANTISBT_BASE_DIR}
        update_config_inc
        ;;

    lock)
        if [[ ! -w ${MANTISBT_BASE_DIR}/mantis_offline.php.sample ]]; then
            echo >&2 "Sample locking file not found: ${MANTISBT_BASE_DIR}/mantis_offline.php.sample"
            exit 1
        fi
        lock_mantisbt
        ;;

    unlock)
        if [[ ! -w ${MANTISBT_BASE_DIR}/mantis_offline.php.sample ]]; then
            echo >&2 "Sample locking file not found: ${MANTISBT_BASE_DIR}/mantis_offline.php.sample"
            exit 1
        fi
        unlock_mantisbt
        ;;

    backup)
        # set MediWiki to read only
        if [[ -w ${MANTISBT_BASE_DIR}/mantis_offline.php.sample ]]; then \
            lock_mantisbt
        fi
        # remove the admin directory
        rm -rf ${MANTISBT_BASE_DIR}/admin
        # backup the selected directory
        /bin/tar \
            --create \
            --preserve-permissions \
            --same-owner \
            --directory=${MANTISBT_BASE_DIR} \
            --to-stdout \
            ./*
        # Now backup the database and then unlock MantisBT
        ;;

    restore)
        if [[ -w ${MANTISBT_BASE_DIR}/mantis_offline.php.sample ]]; then \
            lock_mantisbt
        fi
        echo >&2 "Extract the archive"
        /bin/tar \
            --extract \
            --preserve-permissions \
            --preserve-order \
            --same-owner \
            --directory=${MANTISBT_BASE_DIR} \
            -f -
        echo >&2 "Set permissions"
        chown -R www-data:www-data ${MANTISBT_BASE_DIR}
        # make certain MantisBT is still locked
        if [[ -w ${MANTISBT_BASE_DIR}/mantis_offline.php.sample ]]; then \
            lock_mantisbt
        fi
        update_config_inc
        # remove the admin directory
        rm -rf ${MANTISBT_BASE_DIR}/admin
        # Now restore the database and then use the update script
        if [[ ! -w ${MANTISBT_BASE_DIR}/config_inc.php ]]; then
            echo >&2 "Settings file not found after restore: ${MANTISBT_BASE_DIR}/config_inc.php"
            exit 1
        fi
        ;;

    remove_admin)
        # remove the admin directory
        rm -rf ${MANTISBT_BASE_DIR}/admin
        ;;

    get_admin)
        echo >&2 "Installing Mantis Bug Tracker Admin pages into ${MANTISBT_BASE_DIR}/admin - copying now..."
        mkdir ${MANTISBT_BASE_DIR}/admin
        tar cf - --one-file-system -C /usr/src/mantisbt/admin . | tar -C ${MANTISBT_BASE_DIR}/admin -xf -
        ;;

    *)
        # run some other command in the docker container
        exec "$@"
        ;;
esac
