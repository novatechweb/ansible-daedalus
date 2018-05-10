#!/bin/bash

sources="\
      , ansible-playbook                             , origin       , git@github.com:novatechweb/ansible-virtd-docker-mariadb-bacula-nginx.git                       , master
roles , bacula-catalog                               , origin       , git@github.com:novatechweb/ansible-bacula-catalog.git                                          , master
roles , bacula-client                                , origin       , git@github.com:novatechweb/ansible-bacula-client.git                                           , master
roles , bacula-console                               , origin       , git@github.com:novatechweb/ansible-bacula-console.git                                          , master
roles , bacula-director                              , origin       , git@github.com:novatechweb/ansible-bacula-director.git                                         , master
roles , bacula-script                                , origin       , git@github.com:novatechweb/ansible-bacula-script.git                                           , master
roles , bacula-storage                               , origin       , git@github.com:novatechweb/ansible-bacula-storage.git                                          , master
roles , buildsystem                                  , origin       , git@github.com:novatechweb/ansible-buildsystem.git                                             , master
roles , docker-build-base-image                      , origin       , git@github.com:novatechweb/ansible-docker-build-base-image.git                                 , master
roles , docker-buildsystem                           , origin       , git@github.com:novatechweb/ansible-docker-buildsystem.git                                      , master
roles , docker-common                                , origin       , git@github.com:novatechweb/ansible-docker-common.git                                           , master
roles , docker-exim4                                 , origin       , git@github.com:novatechweb/ansible-docker-exim4.git                                            , master
roles , docker-gitlab                                , origin       , git@github.com:novatechweb/ansible-docker-gitlab.git                                           , master
roles , docker-mantisbt                              , origin       , git@github.com:novatechweb/ansible-docker-mantisbt.git                                         , master
roles , docker-mediawiki                             , origin       , git@github.com:novatechweb/ansible-docker-mediawiki.git                                        , master
roles , docker-openldap                              , origin       , git@github.com:novatechweb/ansible-docker-openldap.git                                         , master
roles , docker-openssl                               , origin       , git@github.com:novatechweb/ansible-docker-openssl.git                                          , master
roles , docker-pull-images                           , origin       , git@github.com:novatechweb/ansible-docker-pull-images.git                                      , master
roles , docker-svn                                   , origin       , git@github.com:novatechweb/ansible-docker-svn.git                                              , master
roles , mariadb                                      , origin       , git@github.com:novatechweb/ansible-mariadb.git                                                 , master
roles , setup-remote-user                            , origin       , git@github.com:novatechweb/ansible-setup-remote-user.git                                       , master
docker, docker-exim4                                 , origin       , git@github.com:novatechweb/docker-exim4                                                        , master
docker, docker-gitlab-data                           , origin       , git@github.com:novatechweb/docker-gitlab                                                       , master
docker, docker-mantisbt                              , origin       , git@github.com:novatechweb/docker-mantisbt                                                     , master
docker, docker-mediawiki                             , origin       , git@github.com:novatechweb/docker-mediawiki                                                    , master
docker, docker-mysql-data                            , origin       , git@github.com:novatechweb/docker-mysql-data                                                   , master
docker, docker-openldap                              , origin       , git@github.com:novatechweb/docker-openldap                                                     , master
docker, docker-openssl                               , origin       , git@github.com:novatechweb/docker-openssl                                                      , master
docker, docker-SupportSite_http_server               , origin       , git@git.novatech-llc.com:NovaTech-Testing/docker-SupportSite_http_server.git                   , master
docker, docker-svn                                   , origin       , git@github.com:novatechweb/docker-svn                                                          , master
docker, docker-TestStation_cron_service              , origin       , git@git.novatech-llc.com:NovaTech-Testing/docker-TestStation_cron_service.git                  , master
docker, docker-TestStation_database_data             , origin       , git@git.novatech-llc.com:NovaTech-Testing/docker-TestStation_database_data.git                 , master
docker, docker-TestStation_database_server           , origin       , git@git.novatech-llc.com:NovaTech-Testing/docker-TestStation_database_server.git               , master
docker, docker-TestStation_http_data_buildsystem     , origin       , git@git.novatech-llc.com:NovaTech-Testing/docker-TestStation_http_data_buildsystem.git         , master
docker, docker-TestStation_http_data_ipkg            , origin       , git@git.novatech-llc.com:NovaTech-Testing/docker-TestStation_http_data_ipkg.git                , master
docker, docker-TestStation_http_data_ncdiso          , origin       , git@git.novatech-llc.com:NovaTech-Testing/docker-TestStation_http_data_ncdiso.git              , master
docker, docker-TestStation_http_data_ncdrelease      , origin       , git@git.novatech-llc.com:NovaTech-Testing/docker-TestStation_http_data_ncdrelease.git          , master
docker, docker-TestStation_http_data_testclient      , origin       , git@git.novatech-llc.com:NovaTech-Testing/docker-TestStation_http_data_testclient.git          , master
docker, docker-TestStation_http_server               , origin       , git@git.novatech-llc.com:NovaTech-Testing/docker-TestStation_http_server.git                   , master
docker, docker-TestStation_ssh_server                , origin       , git@git.novatech-llc.com:NovaTech-Testing/docker-TestStation_ssh_server.git                    , master
docker, docker-TestStation_ssh_server_manualtest     , origin       , git@git.novatech-llc.com:NovaTech-Testing/docker-TestStation_ssh_server_manualtest.git         , master
docker, docker-TestStation_SupportSite_backup_restore, origin       , git@git.novatech-llc.com:NovaTech-Testing/docker-TestStation_SupportSite_backup_restore.git    , master
docker, docker-TestStation_tftp_data                 , origin       , git@git.novatech-llc.com:NovaTech-Testing/docker-TestStation_tftp_data.git                     , master
docker, docker-TestStation_tftp_server               , origin       , git@git.novatech-llc.com:NovaTech-Testing/docker-TestStation_tftp_server.git                   , master
"
git tag -f 'pre-import'
git clean -dxff
while IFS=", " read prefix name remote repo branch; do
    if [ "x$name" == "x" ]; then continue; fi

    fullremote="${name}/${remote}"

    message="${name}: Merge '${fullremote}' at ${branch}"
    rmtcmd="none"
    cmd="none"

    if [ "x$prefix" == "x" ]; then prefix="${name}"; else prefix="${prefix}/${name}"; fi 
    if git remote get-url "${fullremote}" 2>/dev/null; then rmtcmd="set-url"; else cmd="add"; fi
    if [ -d "${prefix}" ]; then cmd="pull"; else cmd="add"; fi

    echo ${message}
    set -x
    git config --add subtree."$prefix".remote "${fullremote}"
    git remote ${rmtcmd} "${fullremote}" "${repo}"
    git fetch "${fullremote}" "${branch}" > /dev/null
    git subtree ${cmd} --prefix="${prefix}" --message="${message}" "${fullremote}" "${branch}" > /dev/null
    { set +x; } 2> /dev/null
    echo
    echo

done <<< $sources
