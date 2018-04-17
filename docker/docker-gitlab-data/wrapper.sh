#!/bin/bash
set -e

# Set sshd config
if ! grep -q '^MaxSessions .*$' /etc/ssh/sshd_config; then
    printf 'MaxSessions 50\n' >> /etc/ssh/sshd_config
    printf >&2 'Set MaxSessions in /etc/ssh/sshd_config\n'
fi
if ! grep -q '^MaxStartups .*:.*:.*$' /etc/ssh/sshd_config; then
    printf 'MaxStartups 50:30:500\n' >> /etc/ssh/sshd_config
    printf >&2 'Set MaxStartups in /etc/ssh/sshd_config\n'
fi

# Continue on to the main gitlab entrypoint with the expected arguments
if [[ -x /sbin/entrypoint.sh ]]; then
    [[ "${#}" == 0 ]] \
        && exec /sbin/entrypoint.sh "app:start" \
        || exec /sbin/entrypoint.sh $@
else
    printf >&2 'Wrapped entrypoint not found.\n'
    false
fi
