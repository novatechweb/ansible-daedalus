#!/bin/bash
set -e

if [[ -d '/tmp/conf.d' ]]; then
    cp -r /tmp/conf.d/* /etc/mysql/conf.d/
    printf >&2 'Imported configuration\n'
else
    if [[ -x /entrypoint.sh ]]; then
        [[ "${#}" == 0 ]] \
            && exec /entrypoint.sh mysqld \
            || exec /entrypoint.sh $@
    elif [[ -x /docker-entrypoint.sh ]]; then
        [[ "${#}" == 0 ]] \
            && exec /docker-entrypoint.sh mysqld \
            || exec /docker-entrypoint.sh $@
    else
        printf >&2 'Wrapped entrypoint not found.\n'
        false
    fi
fi
