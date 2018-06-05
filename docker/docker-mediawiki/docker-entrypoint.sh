#!/bin/bash
set -e

# ************************************************************
# Options passed to the docker container to run scripts
# ************************************************************
# wiki    : Starts apache running. This is the containers default
# lock    : Set the WIKI to read-only
# unlock  : Set the WIKI to read-write
# backup  : backup the wiki static files
# restore : import the wiki static files archive
# update  : Run the update.php script and then unlock the MediaWiki

# ************************************************************
# environment variables
# ************************************************************
# WIKI_HOSTNAME    : Sets the hostname in the apache2 config
# WIKI_DB_DB_NAME  : WIKI_DB_DB_NAME,  WIKI_DB_ENV_MYSQL_DATABASE | WIKI_DB_ENV_POSTGRES_DB,       LocalSettings.php ( $wgDBname )
# WIKI_DB_USER     : WIKI_DB_USER,     WIKI_DB_ENV_MYSQL_USER | WIKI_DB_ENV_POSTGRES_USER,         LocalSettings.php ( $wgDBuser )
# WIKI_DB_PASSWORD : WIKI_DB_PASSWORD, WIKI_DB_ENV_MYSQL_PASSWORD | WIKI_DB_ENV_POSTGRES_PASSWORD, LocalSettings.php ( $wgDBpassword )
# WIKI_MAIL_USER     : WIKI_MAIL_USER,     config_inc.php ( $g_smtp_username )
# WIKI_MAIL_PASSWORD : WIKI_MAIL_PASSWORD, config_inc.php ( $g_smtp_password )

if [[ ! -z "${WIKI_DB_ENV_MYSQL_VERSION}" ]]; then
    WIKI_DB_DB_NAME=${WIKI_DB_DB_NAME:-${WIKI_DB_ENV_MYSQL_DATABASE}}
    WIKI_DB_USER=${WIKI_DB_USER:-${WIKI_DB_ENV_MYSQL_USER}}
    WIKI_DB_PASSWORD=${WIKI_DB_PASSWORD:-${WIKI_DB_ENV_MYSQL_PASSWORD}}
elif [[ ! -z "${WIKI_DB_ENV_PG_VERSION}" ]];then
    WIKI_DB_DB_NAME=${WIKI_DB_DB_NAME:-${WIKI_DB_ENV_POSTGRES_DB}}
    WIKI_DB_USER=${WIKI_DB_USER:-${WIKI_DB_ENV_POSTGRES_USER}}
    WIKI_DB_PASSWORD=${WIKI_DB_PASSWORD:-${WIKI_DB_ENV_POSTGRES_PASSWORD}}
fi


WIKI_BASE_DIR=$(pwd)

lock_mediawiki() {
    # Make certian line exists in settings file
    grep -q 'wgReadOnly' ${WIKI_BASE_DIR}/LocalSettings.php || \
        echo '#wgReadOnly' >> ${WIKI_BASE_DIR}/LocalSettings.php
    # set mediawiki to readonly if not already
    sed -i 's|^#wgReadOnly$|$wgReadOnly = '"'Restoring Database from backup, Access will be restored shortly.'"';|' \
        ${WIKI_BASE_DIR}/LocalSettings.php
    echo >&2 "MediaWiki locked to read-only mode"
    # wait for any transactions to compleate
    sleep 5
}

unlock_mediawiki() {
    # Make certian lock line exists in settings file
    grep -q 'wgReadOnly' ${WIKI_BASE_DIR}/LocalSettings.php || \
        echo '$wgReadOnly = "Setting wgReadOnly did not exist";' >> ${WIKI_BASE_DIR}/LocalSettings.php
    # set MediaWiki to read/write
    sed -i 's|^$wgReadOnly = .*;$|#wgReadOnly|' \
        ${WIKI_BASE_DIR}/LocalSettings.php
    echo >&2 "MediaWiki unlocked to read-write mode"
}

if [[ $(ls -A1 ${WIKI_BASE_DIR} | wc -l) == '0' ]]; then
    # initial setup of mediawiki
    if [[ ! -e ${WIKI_BASE_DIR}/index.php ]] || [[ ! -e ${WIKI_BASE_DIR}/includes/DefaultSettings.php ]]; then
        echo >&2 "Installing MediaWiki into ${WIKI_BASE_DIR} - copying now..."
        tar cf - --one-file-system -C /usr/src/mediawiki . | tar xf -
    fi
fi

# Set the server name
if [[ ! -z "${WIKI_HOSTNAME}" ]]; then
    # change any value of WIKI_HOSTNAME to the value
    sed -i 's|WIKI_HOSTNAME|'${WIKI_HOSTNAME}'|' \
        /etc/apache2/sites-available/000-default-ssl.conf \
        /etc/apache2/sites-available/000-default.conf
    # update the ServerName line
    sed -i 's|ServerName .*$|ServerName '${WIKI_HOSTNAME}'|' \
        /etc/apache2/sites-available/000-default-ssl.conf \
        /etc/apache2/sites-available/000-default.conf
fi
update_LocalSettings() {
    # update LocalSettings.php with environment var values
    if [[ -w ${WIKI_BASE_DIR}/LocalSettings.php ]]; then
        echo >&2 "Updating LocalSettings.php"
        sed -i 's|$wgDBserver = .*|$wgDBserver = "wiki_db";|' ${WIKI_BASE_DIR}/LocalSettings.php
        if [[ ! -z "${WIKI_DB_ENV_MYSQL_VERSION}" ]]; then
            sed -i 's|$wgDBtype = .*|$wgDBtype = "mysql";|' ${WIKI_BASE_DIR}/LocalSettings.php
        elif [[ ! -z "${WIKI_DB_ENV_PG_VERSION}" ]]; then
            sed -i 's|$wgDBtype = .*|$wgDBtype = "postgres";|' ${WIKI_BASE_DIR}/LocalSettings.php
        fi
        if [[ ! -z "${WIKI_DB_DB_NAME}" ]]; then \
            sed -i 's|$wgDBname = .*|$wgDBname = "'${WIKI_DB_DB_NAME}'";|' ${WIKI_BASE_DIR}/LocalSettings.php
        fi
        if [[ ! -z "${WIKI_DB_USER}" ]]; then \
            sed -i 's|$wgDBuser = .*|$wgDBuser = "'${WIKI_DB_USER}'";|' ${WIKI_BASE_DIR}/LocalSettings.php
        fi
        if [[ ! -z "${WIKI_DB_PASSWORD}" ]]; then \
            sed -i 's|$wgDBpassword = .*|$wgDBpassword = "'${WIKI_DB_PASSWORD}'";|' ${WIKI_BASE_DIR}/LocalSettings.php
        fi
        if [[ ! -z "${WIKI_MAIL_USER}" ]] && grep -q "^ *'username'\( *=> \).*$" ${MANTISBT_BASE_DIR}/config_inc.php ; then \
            sed -i "s| *'username'\( *=> \).*| 'username'\1'${WIKI_MAIL_USER}',|" ${MANTISBT_BASE_DIR}/config_inc.php
        fi
        if [[ ! -z "${WIKI_MAIL_PASSWORD}" ]] && grep -q "^ *'username'\( *=> \).*$" ${MANTISBT_BASE_DIR}/config_inc.php ; then \
            sed -i "s| *'password'\( *=> \).*| 'password'\1'${WIKI_MAIL_PASSWORD}',|" ${MANTISBT_BASE_DIR}/config_inc.php
        fi
    fi
}
update_LocalSettings

case ${1} in
    wiki)
        # verify permissions
        chown -R www-data:www-data ${WIKI_BASE_DIR}
        # Start apache
        exec apache2-foreground
        ;;

    LocalSettings)
        cat > ${WIKI_BASE_DIR}/LocalSettings.php
        chown -R www-data:www-data ${WIKI_BASE_DIR}
        update_LocalSettings
        ;;

    lock)
        if [[ ! -w ${WIKI_BASE_DIR}/LocalSettings.php ]]; then
            echo >&2 "Settings file not found: ${WIKI_BASE_DIR}/LocalSettings.php"
            exit 1
        fi
        lock_mediawiki
        ;;

    unlock)
        if [[ ! -w ${WIKI_BASE_DIR}/LocalSettings.php ]]; then
            echo >&2 "Settings file not found: ${WIKI_BASE_DIR}/LocalSettings.php"
            exit 1
        fi
        unlock_mediawiki
        ;;

    backup)
        # set MediWiki to read only
        if [[ -w ${WIKI_BASE_DIR}/LocalSettings.php ]]; then \
            lock_mediawiki
        fi
        # backup the selected directory
        /bin/tar \
            --create \
            --preserve-permissions \
            --same-owner \
            --directory=${WIKI_BASE_DIR} \
            --to-stdout \
            ./*
        # Now backup the database and then unlock MediaWiki
        ;;

    restore)
        if [[ -w ${WIKI_BASE_DIR}/LocalSettings.php ]]; then \
            lock_mediawiki
        fi
        echo >&2 "Extract the archive"
        /bin/tar \
            --extract \
            --preserve-permissions \
            --preserve-order \
            --same-owner \
            --directory=${WIKI_BASE_DIR} \
            -f -
        echo >&2 "Set permissions"
        chown -R www-data:www-data ${WIKI_BASE_DIR}
        # make certain MediaWiki is still locked
        if [[ -w ${WIKI_BASE_DIR}/LocalSettings.php ]]; then \
            lock_mediawiki
        fi
        update_LocalSettings
        # Now restore the database and then use the update script
        if [[ ! -w ${WIKI_BASE_DIR}/LocalSettings.php ]]; then
            echo >&2 "Settings file not found after restore: ${WIKI_BASE_DIR}/LocalSettings.php"
            exit 1
        fi
        ;;

    update)
        if [[ ! -w ${WIKI_BASE_DIR}/LocalSettings.php ]]; then
            echo >&2 "Settings file not found: ${WIKI_BASE_DIR}/LocalSettings.php"
            exit 1
        fi
        # set MediWiki to read only
        lock_mediawiki
        # run the script
        echo >&2 "Run update.py maintenance script"
        php /var/www/html/maintenance/update.php --quick
        # set MediaWiki to read-write
        unlock_mediawiki
        ;;

    *)
        # run some other command in the docker container
        exec "$@"
        ;;
esac
