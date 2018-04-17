#!/bin/bash
set -e

inventory_file=${1:staging}

for host in $(sed -e 's|^[[].*$||' -e 's|\..*$||' -e '/^$/d' ${inventory_file} | sort | uniq)
do
  ssh-keygen -R ${host}.novatech-llc.com
  ssh-keygen -R ${host}
  ssh-keygen -R $(getent hosts ${host} | awk '{ print $1 ; exit }')
  ssh-keyscan ${host}.novatech-llc.com >> ~/.ssh/known_hosts
done
ansible-playbook bootstrap.yml -i ${inventory_file} --ask-pass
ansible-playbook site.yml -i ${inventory_file}
