#! /bin/bash

#PYTHONUNBUFFERED=1 \
     
ANSIBLE_ENABLE_TASK_DEBUGGER=True \
ANSIBLE_FORCE_COLOR=true \
ANSIBLE_HOST_KEY_CHECKING=false \
ANSIBLE_SSH_ARGS='-o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -o ControlMaster=auto -o ControlPersist=60s' \
exec ansible-playbook \
        --connection=ssh \
        --timeout=30 \
        --inventory-file=/home/coopera/Developer/testdaedalus/vmdaedalus/vagrant_ansible_inventory \
        -vv \
        ansible-playbook/buildbot.yml "$@"
