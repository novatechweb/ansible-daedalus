#!/bin/sh

set -x

groupadd -g 993 registry
useradd -m -u 993 -g registry -m -s /bin/sh -d /var/opt/gitlab/registry registry

install -m 0755 /opt/gitlab/etc/gitlab.rb.template /etc/gitlab/gitlab.rb
install -m 0755 -d /etc/gitlab/ssl
install -m 0660 -t /etc/gitlab/ssl /run/secrets/ssl/nginx.crt
install -m 0660 -t /etc/gitlab/ssl /run/secrets/ssl/nginx.key
install -m 0660 -t /etc/gitlab/ssl /run/secrets/ssl/dhparam.pem
chmod -R 2770 /var/opt/gitlab/git-data/repositories

exec "$@"
