#!/bin/bash

PWD=$(readlink -f $(dirname $0))
CONTEXT=$(readlink -f "$PWD/..")
cd $PWD

exec docker run \
--env ANSIBLE_ROLES_PATH=/ansible \
--init \
--interactive \
--mount type=bind,src="$CONTEXT",dst="/ansible" \
--mount type=bind,src="$HOME/.ssh",dst="/home/ansible/.ssh" \
--network=host \
--rm \
--tty \
--user ansible \
--workdir "/ansible/ansible-playbook" \
daedalus-provisioner \
"$@"
