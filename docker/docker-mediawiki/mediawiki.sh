#!/bin/bash

source config.sh
set -e

# ************************************************************
# check state before performing
case ${1} in
    backup)
        [[ -f ${HOST_WIKI_BACKUP_DIR}${STATIC_BACKUP_FILE} ]] && \
            rm -f ${HOST_WIKI_BACKUP_DIR}${STATIC_BACKUP_FILE}
        [[ -f ${HOST_WIKI_BACKUP_DIR}${DATABASE_BACKUP_FILE} ]] && \
            rm -f ${HOST_WIKI_BACKUP_DIR}${DATABASE_BACKUP_FILE}
        ;;

    restore)
        if [[ ! -f ${HOST_WIKI_RESTORE_DIR}${STATIC_BACKUP_FILE} ]] && \
           [[ ! -f ${HOST_WIKI_RESTORE_DIR}${DATABASE_BACKUP_FILE} ]]; then
            echo >&2 "ERROR: The mediawiki files to restore was not found!"
            exit 1
        fi
        ;;

    *)
        echo >&2 "Usage:"
        echo >&2 "  mediawiki.sh <backup | restore> [-u <DB username>] [-p <DB password>]"
        echo >&2 ""
        exit 0
        ;;
esac

dbuser=''
dbpass=''
while getopts ":u:p:" opt ${@:2}; do
    case ${opt} in
        u)
            dbuser=${OPTARG}
            ;;
        p)
            dbpass=${OPTARG}
            ;;
        \?)
            echo >&2 "Invalid argument: ${opt} ${OPTARG}"
            echo >&2 ""
            echo >&2 "Usage:"
            echo >&2 "  mediawiki.sh <backup | restore> [-u <DB username>] [-p <DB password>]"
            echo >&2 ""
            exit 1
            ;;
    esac
done

# make certian the containers exist
docker inspect ${WIKI_CONTAINER_NAME} > /dev/null
docker inspect ${WIKI_DB_CONTAINER_NAME} > /dev/null
docker volume inspect ${WIKI_DV_NAME} > /dev/null
docker volume inspect ${WIKI_DB_DV_NAME} > /dev/null

get_db_user_and_password() {
    db_user="$(docker 2>&1 exec ${WIKI_CONTAINER_NAME} grep -e '^$wgDBuser' LocalSettings.php|sed 's|^.* = \"\(.*\)\";$|\1|' || true)"
    db_password="$(docker 2>&1 exec ${WIKI_CONTAINER_NAME} grep -e '^$wgDBpassword' LocalSettings.php|sed 's|^.* = \"\(.*\)\";$|\1|' || true)"
    if [[ ! -z "${dbuser}" ]]; then
        db_user="${dbuser}"
    fi
    if [[ ! -z "${dbpass}" ]]; then
        db_password="${dbpass}"
    fi
    if [[ ! -z "${db_user}" ]]; then
        echo "db_user=\"${db_user}\""
    fi
    if [[ ! -z "${db_password}" ]]; then
        echo "db_password=\"${db_password}\""
    fi
}
eval $(get_db_user_and_password)

wait_for_mediawiki_start() {
    count=0
    printf >&2 'Wait for MediaWiki running:  '
    while ! \
        docker exec "${WIKI_CONTAINER_NAME}" \
          ls /var/www/html/index.php &> /dev/null
    do
        sleep 1
        printf >&2 '.'
        (( ${count} > 60 )) && exit 1
        count=$((count+1))
    done
    printf >&2 '\n'
}
wait_for_mediawiki_start

wait_for_database_start() {
    count=0
    printf >&2 'Wait for MySQL running:  '
    while ! \
        echo "SHOW GLOBAL STATUS;" | \
            docker exec -i "${WIKI_DB_CONTAINER_NAME}" \
                mysql \
                  --host=localhost \
                  --user="${db_user}" \
                  --password="${db_password}" \
                  wikidb &> /dev/null
    do
        sleep 1
        printf >&2 '.'
        (( ${count} > 60 )) && exit 1
        count=$((count+1))
    done
    printf >&2 '\n'
}

case ${1} in
    backup)
        if [[ -z "${db_user}" ]] || [[ -z "${db_password}" ]]; then
            echo >&2 "Could not determine database user and/or password"
            exit 1
        fi
        echo >&2 "Backing up MediaWiki static files"
        docker exec ${WIKI_CONTAINER_NAME} /docker-entrypoint.sh backup \
            > ${HOST_WIKI_BACKUP_DIR}${STATIC_BACKUP_FILE}
        wait_for_database_start
        echo >&2 "Backing up MediaWiki database"
        docker exec "${WIKI_DB_CONTAINER_NAME}" \
            mysqldump \
                --host=localhost \
                --user="${db_user}" \
                --password="${db_password}" \
                --add-drop-table \
                --flush-privileges \
                --hex-blob \
                --tz-utc \
                ${WIKI_DB_DB_NAME} \
            > ${HOST_WIKI_BACKUP_DIR}${DATABASE_BACKUP_FILE}
        echo >&2 "Unlocking MediaWiki"
        docker exec ${WIKI_CONTAINER_NAME} /docker-entrypoint.sh unlock
        ;;

    restore)
        if [[ ! -f ${HOST_WIKI_RESTORE_DIR}${STATIC_BACKUP_FILE} ]]; then
            echo >&2 "Lock MediaWiki"
            docker exec "${WIKI_CONTAINER_NAME}" /docker-entrypoint.sh lock
        else
            auth_options=''
            if [[ ! -z "${db_user}" ]]; then
                auth_options="${auth_options} -u ${db_user}"
            fi
            if [[ ! -z "${db_password}" ]]; then
                auth_options="${auth_options} -p ${db_password}"
            fi
            echo >&2 "Restore MediaWiki static files"
            docker exec -i "${WIKI_CONTAINER_NAME}" /docker-entrypoint.sh restore ${auth_options} < \
                 ${HOST_WIKI_RESTORE_DIR}${STATIC_BACKUP_FILE}
            if [[ ! -z "${dbuser}" ]] || [[ ! -z "${dbpass}" ]]; then
                # update the restored LocalSettings.php with the passed in dbuser and/or dbpassword
                if [[ ! -z "${dbuser}" ]]; then
                    docker exec "${WIKI_CONTAINER_NAME}" \
                        sed -i \
                          's|$wgDBuser = .*|$wgDBuser = "'${dbuser}'";|' \
                          LocalSettings.php || true

                fi
                if [[ ! -z "${dbpass}" ]]; then
                    docker exec "${WIKI_CONTAINER_NAME}" \
                        sed -i \
                          's|$wgDBpassword = .*|$wgDBpassword = "'${dbpass}'";|' \
                          LocalSettings.php || true
                fi
            else
                # get database username and password from MediaWiki config
                eval $(get_db_user_and_password)
            fi
        fi
        if [[ -f ${HOST_WIKI_RESTORE_DIR}${DATABASE_BACKUP_FILE} ]]; then
            wait_for_database_start
            if [[ -z "${db_user}" ]] || [[ -z "${db_password}" ]]; then
                echo >&2 "Could not determine database user and/or password"
                exit 1
            fi
            echo >&2 "Restore MediaWiki database"
            docker exec -i "${WIKI_DB_CONTAINER_NAME}" \
                mysql \
                  --host=localhost \
                  --user="${db_user}" \
                  --password="${db_password}" \
                  ${WIKI_DB_DB_NAME} < \
                ${HOST_WIKI_RESTORE_DIR}${DATABASE_BACKUP_FILE}
        fi
        echo >&2 "Run update.php maintenance script"
        docker exec "${WIKI_CONTAINER_NAME}" /docker-entrypoint.sh update
        echo >&2 "Finished running script"
        ;;
esac

# ************************************************************
# restart the docker container
docker restart ${WIKI_CONTAINER_NAME}
