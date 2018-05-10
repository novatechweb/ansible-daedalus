#!/bin/bash

inventory_file=${1:-staging}

for host in $(sed -e 's|^[[].*$||' -e 's|\..*$||' -e '/^$/d' ${inventory_file} | sort | uniq)
do
  ssh-keygen -R ${host}.novatech-llc.com 1>/dev/null 2>&1
  ssh-keygen -R ${host} 1>/dev/null 2>&1
  ssh-keygen -R $(getent hosts ${host} | awk '{ print $1 ; exit }') 1>/dev/null 2>&1
  ssh-keyscan ${host}.novatech-llc.com >> ~/.ssh/known_hosts
done

set -e
ansible-playbook bootstrap.yml -i ${inventory_file} --ask-pass
ansible-playbook site.yml -i ${inventory_file}
