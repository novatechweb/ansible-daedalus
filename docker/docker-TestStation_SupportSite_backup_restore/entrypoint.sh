#!/bin/bash

#====================================================
# The following environment variables should be populated by the ansible scripts before the image is built.
#----------------------------------------------------
# DATABASE_PASSWORD
#====================================================


#====================================================
# The following are static set variables.
#----------------------------------------------------
SUPPORTSITE_SERVER=www.novatech-llc.com
SSH_OPTIONS="-i /root/.ssh/id_rsa_buildsystem -oStrictHostKeyChecking=no -oUser=root"
#----------------------------------------------------
BUILDSYSTEM_SQL_RESTORE_FILE="/restore/buildsystem_backup.sql"
BUILDSYSTEM_TFTP_RESTORE_FILE="/restore/tftp_files.tgz"
BUILDSYSTEM_TEST_CLIENT_RESTORE_FILE="/restore/test_client_files.tgz"
#----------------------------------------------------
BUILDSYSTEM_SQL_BACKUP_FILE="/backup/buildsystem_backup.sql"
BUILDSYSTEM_TFTP_BACKUP_FILE="/backup/tftp_files.tgz"
BUILDSYSTEM_TEST_CLIENT_BACKUP_FILE="/backup/test_client_files.tgz"
#----------------------------------------------------
SUPPORTSITE_SQL_RESTORE_FILE="/restore/supportsite_backup.sql"
#----------------------------------------------------
SUPPORTSITE_SQL_BACKUP_FILE="/backup/supportsite_backup.sql"
#====================================================

case ${1} in
    command_line)
        exec /bin/bash
    ;;
#===================================================================================================
    restore_buildsystem)
        if [ -e $BUILDSYSTEM_SQL_RESTORE_FILE ]; then
            echo "Restore BS MySQL"
            mysql --host=test_station_mysql_server --user=root --password=$DATABASE_PASSWORD < $BUILDSYSTEM_SQL_RESTORE_FILE
        fi
        if [ -e $BUILDSYSTEM_TFTP_RESTORE_FILE ]; then
            echo "Restore BS TFTP"
            tar -xz -f $BUILDSYSTEM_TFTP_RESTORE_FILE        --directory=/
        fi
        if [ -e $BUILDSYSTEM_TEST_CLIENT_RESTORE_FILE ]; then
            echo "Restore BS Test Client"
            tar -xz -f $BUILDSYSTEM_TEST_CLIENT_RESTORE_FILE --directory=/
        fi
    ;;

    backup_buildsystem)
        #++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        # MySQL backup
        echo "Backup BS MySQL"
        mysqldump --host=test_station_mysql_server --user=root --password=$DATABASE_PASSWORD --events --triggers --result-file=$BUILDSYSTEM_SQL_BACKUP_FILE protocol
        #++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        # tftp file backup
        echo "Backup BS TFTP"
        tar -cz -f $BUILDSYSTEM_TFTP_BACKUP_FILE        --directory=/ /opt/tftp_files
        #++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        # static test client files stored on the server
        echo "Backup BS Test Client"
        tar -cz -f $BUILDSYSTEM_TEST_CLIENT_BACKUP_FILE --directory=/ /opt/test_client_files
    ;;

    cleanup_buildsystem)
        rm -fr /cleanup/buildsystem
    ;;

    #-----------------------------------------------------------------------------------------------
    restore_supportsite)
        if [ -e $SUPPORTSITE_SQL_RESTORE_FILE ]; then
            echo "Restore SS MySQL"
            scp $SSH_OPTIONS $SUPPORTSITE_SQL_RESTORE_FILE supportsite_docker_container:/tmp/supportsite_restore.sql
            remote_restore_cmd="mysql --host=SupportSite_database_server --user=root --password=$DATABASE_PASSWORD < /tmp/supportsite_restore.sql"
            ssh $SSH_OPTIONS supportsite_docker_container $remote_restore_cmd
        fi
    ;;

    backup_supportsite)
        #++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        # MySQL backup
        echo "Backup SS MySQL"
        remote_dump_cmd="mysqldump --host=SupportSite_database_server --user=root --password=$DATABASE_PASSWORD --events --triggers --result-file=/tmp/supportsite_backup.sql protocol"
        ssh $SSH_OPTIONS supportsite_docker_container $remote_dump_cmd
        scp $SSH_OPTIONS supportsite_docker_container:/tmp/supportsite_backup.sql $SUPPORTSITE_SQL_BACKUP_FILE
        ssh $SSH_OPTIONS supportsite_docker_container "rm -f /tmp/supportsite_backup.sql"
        #++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        # Generating a 2 files to inventory items in the download directory
        echo "Backup SS Download File Info"
        ssh $SSH_OPTIONS supportsite_docker_container "find /opt/downloads/ -type f -exec md5sum {} \;" > /backup/supportsite_downloads_md5sum.txt
        ssh $SSH_OPTIONS supportsite_docker_container "ls -Fla --color=none /opt/downloads/" > /backup/supportsite_downloads_list.txt
    ;;

    cleanup_supportsite)
        rm -fr /cleanup/supportsite
    ;;
#===================================================================================================
    *)
        exec "$@"
    ;;

esac
