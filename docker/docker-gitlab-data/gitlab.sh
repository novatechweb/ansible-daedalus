#!/bin/bash

[[ -f ./config.sh ]] || {
    echo >&2 "file dose not exist: ./config.sh"
    echo >&2 "  Are you running the script from the correct directory?"
    exit 1
}

source config.sh

[[ -f ./gitlab.env.list ]] || {
    echo >&2 "file dose not exist: ./gitlab.env.list"
    echo >&2 "  Are you running the script from the correct directory?"
    exit 1
}

# verify containers
docker inspect ${GITLAB_CONTAINER_NAME}_UTILITY &> /dev/null
if [[ "${?}" == "0" ]]; then
    echo >&2 "ERROR: ${GITLAB_CONTAINER_NAME}_UTILITY container exists."
    echo >&2 "The utility container should be removed"
    exit 1
fi
docker inspect ${GITLAB_CONTAINER_NAME} &> /dev/null
if [[ "${?}" != "0" ]]; then
    echo >&2 "ERROR: ${GITLAB_CONTAINER_NAME} container does not exists."
    echo >&2 "The gitlab container needs to exist in order to backup, restore, or import."
    exit 1
fi
docker inspect ${GITLAB_DV_NAME} &> /dev/null
if [[ "${?}" != "0" ]]; then
    echo >&2 "ERROR: ${GITLAB_DV_NAME} container does not exists."
    echo >&2 "The gitlab Data-Volume container needs to exist in order to backup, restore, or import."
    exit 1
fi

set -e

case ${1} in
    backup)
        # remove previous backups from backup dir
        rm -f ${HOST_GITLAB_BACKUP_DIR}/??????????_gitlab_backup.tar
        # Stop gitlab container
        if [[ $(docker inspect -f '{{ .State.Running }}' ${GITLAB_CONTAINER_NAME}) == 'true' ]]; then
            docker stop "${GITLAB_CONTAINER_NAME}"
        fi
        # Start utility container to perform a backup
        docker run --name=${GITLAB_CONTAINER_NAME}_UTILITY --rm -t \
            --volumes-from "${GITLAB_DV_NAME}" \
            --link ${GITLAB_DB_CONTAINER_NAME}:gitlab-db \
            --link ${GITLAB_REDIS_CONTAINER_NAME}:gitlab-redis \
            --env-file=./gitlab.env.list \
            --env="DB_USER=${GITLAB_DB_USER}" \
            --env="DB_PASS=${GITLAB_DB_PASSWORD}" \
            -v ${HOST_GITLAB_BACKUP_DIR}/:/home/git/backups \
            ${GITLAB_IMAGE_NAME}:${DOCKER_IMAGE_TAG} \
                app:rake gitlab:backup:create
        # Start gitlab container running
        docker start "${GITLAB_CONTAINER_NAME}"
        ;;

    restore)
        # verify there is only one gitlab archive to restore
        if [[ $(ls -1 ${HOST_GITLAB_RESTORE_DIR}/??????????_gitlab_backup.tar | wc -l) != '1' ]]; then
            echo >&2 "ERROR: more than one gitlab archive exists to be restored."
            echo >&2 "There should be only one:" 
            ls >&2 -1 ${HOST_GITLAB_RESTORE_DIR}/??????????_gitlab_backup.tar
            exit 1
        fi
        # get the timestamp from the backup file
        timestamp="$(ls -1 ${HOST_GITLAB_RESTORE_DIR}/??????????_gitlab_backup.tar | sed 's|^'${HOST_GITLAB_RESTORE_DIR}/'\(..........\)_gitlab_backup.tar$|\1|')"
        # Stop gitlab container
        if [[ $(docker inspect -f '{{ .State.Running }}' ${GITLAB_CONTAINER_NAME}) == 'true' ]]; then
            docker stop "${GITLAB_CONTAINER_NAME}"
        fi
        # Start utility container to perform a restore
        GITLAB_USER=git
        docker run --name=${GITLAB_CONTAINER_NAME}_UTILITY --rm \
            -v ${HOST_GITLAB_RESTORE_DIR}:/home/git/backups \
            --env="BACKUP_TIMESTAMP=${timestamp}" \
            --volumes-from "${GITLAB_DV_NAME}" \
            --link ${GITLAB_DB_CONTAINER_NAME}:gitlab-db \
            --link ${GITLAB_REDIS_CONTAINER_NAME}:gitlab-redis \
            --env-file=./gitlab.env.list \
            --env="DB_USER=${GITLAB_DB_USER}" \
            --env="DB_PASS=${GITLAB_DB_PASSWORD}" \
            ${GITLAB_IMAGE_NAME}:${DOCKER_IMAGE_TAG} \
                app:rake gitlab:backup:restore force=yes BACKUP=${timestamp}
#                sudo -HEu ${GITLAB_USER} bundle exec rake gitlab:backup:restore force=yes BACKUP=${timestamp} RAILS_ENV=production
        # Start gitlab container running
        docker start "${GITLAB_CONTAINER_NAME}"
        ;;

#    import)
#        #     https://github.com/gitlabhq/gitlabhq/wiki/Import-existing-repositories-into-GitLab
#        namespace="root"
#        [[ ! -z "${2}" ]] && namespace=${2}
#        [[ ! -d "${HOST_GITLAB_RESTORE_DIR}/repositories" ]] && {
#            echo "Repository archives do not exist."
#            exit 1
#        }
#        docker inspect "${datavolume_name}" &> /dev/null || \
#            docker stop "${GITLAB_CONTAINER_NAME}"
#        cp ${GITLAB_IMPORT_SCRIPT_DIR}/import_script.sh ${HOST_GITLAB_RESTORE_DIR}/repositories/
#        docker run --name=${GITLAB_CONTAINER_NAME}_UTILITY -it --rm \
#            -v ${HOST_GITLAB_RESTORE_DIR}/repositories:/tmp/import_export \
#            --env="NAMESPACE=${namespace}" \
#            --volumes-from "${GITLAB_DV_NAME}" \
#            --link ${GITLAB_DB_CONTAINER_NAME}:gitlab-db \
#            --link ${GITLAB_REDIS_CONTAINER_NAME}:gitlab-redis \
#            --env-file=./gitlab.env.list \
#            --env="DB_USER=${GITLAB_DB_USER}" \
#            --env="DB_PASS=${GITLAB_DB_PASSWORD}" \
#            ${GITLAB_IMAGE_NAME}:${DOCKER_IMAGE_TAG} \
#                /tmp/import_export/import_script.sh
#        rm ${HOST_GITLAB_RESTORE_DIR}/repositories/import_script.sh
#        docker start "${GITLAB_CONTAINER_NAME}"
#        ;;

    *)
        echo "Usage:"
        echo "  gitlab.sh <OPERATION>  [OPTIONS]"
        echo ""
        echo "  OPERATION:"
        echo "    backup        Backup data from the container"
        echo "    restore       Restore data to the container (Interactive)"
#        echo "    import        Import git repositories into the container"
#        echo ""
#        echo "  OPTIONS:"
#        echo "    namespace     The subdirectory the repositories will be placed durring importing."
        echo ""
        exit 0
        ;;
esac
