#!/bin/bash

source config.sh
set -e

# ************************************************************
# check state before performing
case ${1} in
    backup)
        [[ -f ${HOST_MANTISBT_BACKUP_DIR}${STATIC_BACKUP_FILE} ]] && \
            rm -f ${HOST_MANTISBT_BACKUP_DIR}${STATIC_BACKUP_FILE}
        [[ -f ${HOST_MANTISBT_BACKUP_DIR}${DATABASE_FILES_TABLE_BACKUP_FILE} ]] && \
            rm -f ${HOST_MANTISBT_BACKUP_DIR}${DATABASE_FILES_TABLE_BACKUP_FILE}
        [[ -f ${HOST_MANTISBT_BACKUP_DIR}${DATABASE_BACKUP_FILE} ]] && \
            rm -f ${HOST_MANTISBT_BACKUP_DIR}${DATABASE_BACKUP_FILE}
        ;;

    restore)
        if [[ ! -f ${HOST_MANTISBT_RESTORE_DIR}${STATIC_BACKUP_FILE} ]] && \
           [[ ! -f ${HOST_MANTISBT_RESTORE_DIR}${DATABASE_FILES_TABLE_BACKUP_FILE} ]] && \
           [[ ! -f ${HOST_MANTISBT_RESTORE_DIR}${DATABASE_BACKUP_FILE} ]]; then
            printf >&2 'ERROR: The MantisBT files to restore was not found!\n'
            exit 1
        fi
        ;;

    *)
        echo >&2 "Usage:"
        echo >&2 "  mantisbt.sh <backup | restore> [-u <DB username>] [-p <DB password>]"
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
            echo >&2 "  mantisbt.sh <backup | restore> [-u <DB username>] [-p <DB password>]"
            echo >&2 ""
            exit 1
            ;;
    esac
done

# make certian the containers exist
docker inspect ${MANTISBT_CONTAINER_NAME} > /dev/null
docker inspect ${MANTISBT_DB_CONTAINER_NAME} > /dev/null
docker inspect ${MANTISBT_DV_NAME} > /dev/null
docker inspect ${MANTISBT_DB_DV_NAME} > /dev/null

get_db_user_and_password() {
    db_user="$(docker 2>&1 exec ${MANTISBT_CONTAINER_NAME} grep -e '^$g_db_username' config_inc.php|sed 's|^.* = \"\(.*\)\";$|\1|' || true)"
    db_password="$(docker 2>&1 exec ${MANTISBT_CONTAINER_NAME} grep -e '^$g_db_password' config_inc.php|sed 's|^.* = \"\(.*\)\";$|\1|' || true)"
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

wait_for_mantisbt_start() {
    count=0
    printf >&2 '==> Wait for MantisBT running:  '
    while ! \
        docker exec "${MANTISBT_CONTAINER_NAME}" \
          ls /var/www/html/index.php &> /dev/null
    do
        sleep 1
        printf >&2 '.'
        (( ${count} > 60 )) && exit 1
        count=$((count+1))
    done
    printf >&2 '\n'
}
wait_for_mantisbt_start

wait_for_database_start() {
    count=0
    printf >&2 '==> Wait for MySQL running:  '
    while ! \
        echo "SHOW GLOBAL STATUS;" | \
            docker exec -i "${MANTISBT_DB_CONTAINER_NAME}" \
                mysql \
                  --host=localhost \
                  --user="${db_user}" \
                  --password="${db_password}" \
                  ${MANTISBT_DB_DB_NAME} &> /dev/null
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
            printf >&2 '==> Could not determine database user and/or password\n'
            exit 1
        fi
        printf >&2 '==> Backing up MantisBT static files\n    '
        docker exec ${MANTISBT_CONTAINER_NAME} /docker-entrypoint.sh backup \
            > ${HOST_MANTISBT_BACKUP_DIR}${STATIC_BACKUP_FILE}
        wait_for_database_start
        printf >&2 '==> Backing up MantisBT database (files table)\n    '
        docker exec "${MANTISBT_DB_CONTAINER_NAME}" \
            mysqldump \
                --host=localhost \
                --user="${db_user}" \
                --password="${db_password}" \
                --add-drop-table \
                --flush-privileges \
                --hex-blob \
                --skip-extended-insert \
                --tz-utc \
                --default-character-set=utf8 \
                ${MANTISBT_DB_DB_NAME} mantis_bug_file_table \
                    > ${HOST_MANTISBT_BACKUP_DIR}${DATABASE_FILES_TABLE_BACKUP_FILE}
        printf >&2 '==> Backing up MantisBT database (remaining tables)\n    '
        docker exec "${MANTISBT_DB_CONTAINER_NAME}" \
            mysqldump \
                --host=localhost \
                --user="${db_user}" \
                --password="${db_password}" \
                --add-drop-table \
                --flush-privileges \
                --hex-blob \
                --skip-extended-insert \
                --ignore-table=${MANTISBT_DB_DB_NAME}.mantis_bug_file_table \
                --tz-utc \
                --default-character-set=utf8 \
                ${MANTISBT_DB_DB_NAME} \
                    > ${HOST_MANTISBT_BACKUP_DIR}${DATABASE_BACKUP_FILE}
        printf >&2 '==> Unlocking MantisBT\n    '
        docker exec ${MANTISBT_CONTAINER_NAME} /docker-entrypoint.sh unlock
        ;;

    restore)
        if [[ ! -f ${HOST_MANTISBT_RESTORE_DIR}${STATIC_BACKUP_FILE} ]]; then
            printf >&2 '==> Lock MantisBT\n    '
            docker exec "${MANTISBT_CONTAINER_NAME}" /docker-entrypoint.sh lock
        else
            auth_options=''
            if [[ ! -z "${db_user}" ]]; then
                auth_options="${auth_options} -u ${db_user}"
            fi
            if [[ ! -z "${db_password}" ]]; then
                auth_options="${auth_options} -p ${db_password}"
            fi
            printf >&2 '==> Restore MantisBT static files\n    '
            docker exec -i "${MANTISBT_CONTAINER_NAME}" /docker-entrypoint.sh restore ${auth_options} < \
                 ${HOST_MANTISBT_RESTORE_DIR}${STATIC_BACKUP_FILE}
            if [[ ! -z "${dbuser}" ]] || [[ ! -z "${dbpass}" ]]; then
                # update the restored config_inc.php with the passed in dbuser and/or dbpassword
                if [[ ! -z "${dbuser}" ]]; then
                    docker exec "${MANTISBT_CONTAINER_NAME}" \
                        sed -i \
                          's|$g_db_username = .*|$g_db_username = "'${dbuser}'";|' \
                          config_inc.php || true

                fi
                if [[ ! -z "${dbpass}" ]]; then
                    docker exec "${MANTISBT_CONTAINER_NAME}" \
                        sed -i \
                          's|$g_db_password = .*|$g_db_password = "'${dbpass}'";|' \
                          config_inc.php || true
                fi
            else
                # get database username and password from MantisBT config
                eval $(get_db_user_and_password)
            fi
        fi
        if [[ -f ${HOST_MANTISBT_RESTORE_DIR}${DATABASE_BACKUP_FILE} ]] && [[ -f ${HOST_MANTISBT_RESTORE_DIR}${DATABASE_FILES_TABLE_BACKUP_FILE} ]]; then
            wait_for_database_start
            if [[ -z "${db_user}" ]] || [[ -z "${db_password}" ]]; then
                printf >&2 '==> Could not determine database user and/or password\n'
                exit 1
            fi
            printf >&2 '==> Restore MantisBT database (files table)\n    '
            docker exec -i "${MANTISBT_DB_CONTAINER_NAME}" \
                mysql \
                    --host=localhost \
                    --user="${db_user}" \
                    --password="${db_password}" \
                    ${MANTISBT_DB_DB_NAME} < \
                        ${HOST_MANTISBT_RESTORE_DIR}${DATABASE_FILES_TABLE_BACKUP_FILE}
            printf >&2 '==> Restore MantisBT database (remaining tables)\n    '
            docker exec -i "${MANTISBT_DB_CONTAINER_NAME}" \
                mysql \
                    --host=localhost \
                    --user="${db_user}" \
                    --password="${db_password}" \
                    ${MANTISBT_DB_DB_NAME} < \
                        ${HOST_MANTISBT_RESTORE_DIR}${DATABASE_BACKUP_FILE}
        fi
        printf >&2 '==> Remove Admin\n    '
        docker exec "${MANTISBT_CONTAINER_NAME}" /docker-entrypoint.sh remove_admin
        printf >&2 '==> Unlock MantisBT\n    '
        docker exec "${MANTISBT_CONTAINER_NAME}" /docker-entrypoint.sh unlock
        printf >&2 '==> Finished running script\n'
        ;;
esac

# ************************************************************
# restart the docker container
docker restart ${MANTISBT_CONTAINER_NAME}
