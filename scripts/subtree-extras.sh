#!/bin/bash

set -e

extras="\
docker, docker-exim4                                 , AndrewCooper , git@github.com:AndrewCooper/docker-exim4.git                                                   , origin/master, master
docker, docker-mediawiki                             , AndrewCooper , git@github.com:AndrewCooper/docker-mediawiki.git                                               , origin/master, downgrade-extensions
docker, docker-openldap                              , AndrewCooper , git@github.com:AndrewCooper/docker-openldap.git                                                , origin/master, master
docker, docker-openssl                               , AndrewCooper , git@github.com:AndrewCooper/docker-openssl.git                                                 , origin/master, master
docker, docker-svn                                   , AndrewCooper , git@github.com:AndrewCooper/docker-svn                                                         , origin/master, master
docker, docker-SupportSite_http_server               , andrew.cooper, git@git.novatech-llc.com:andrew.cooper/docker-SupportSite_http_server.git                      , origin/master, apache-2.4.7
docker, docker-TestStation_http_server               , andrew.cooper, git@git.novatech-llc.com:andrew.cooper/docker-TestStation_http_server.git                      , origin/master, apache-2.4.7
docker, docker-TestStation_SupportSite_backup_restore, andrew.cooper, git@git.novatech-llc.com:andrew.cooper/docker-TestStation_SupportSite_backup_restore.git       , origin/master, limit-backup-dbs
"

git tag -f pre-extras
git clean -dxff
while IFS=", " read prefix name remote repo frombranch branch; do
    if [ "x$name" == "x" ]; then continue; fi

    fullremote="${name}/${remote}"

    if [ "x$prefix" == "x" ]; then prefix="${name}"; else prefix="${prefix}/${name}"; fi 
    if git remote get-url "${fullremote}" 2>/dev/null; then rmtcmd="set-url"; else cmd="add"; fi

    git remote ${rmtcmd} "${fullremote}" "${repo}"
    git fetch "${fullremote}" "${branch}" > /dev/null

    rev_list="$( 
        git rev-list --reverse ${name}/${frombranch}..${fullremote}/${branch}
    )"

    for r in $rev_list; do
        git show --oneline --numstat $r
        git cherry-pick --strategy recursive -X subtree=${prefix} $r
    done

done <<< $extras
