#!/bin/bash
set -e
set -x
echo "Install ptxdist version '$PTXDIST_COMMIT'"

chmod -R 700 "/tmp/ptxdist"

echo "172.16.0.102	git.novatech-llc.com" >> /etc/hosts

mkdir -p $HOME/.ssh/
wget -O $HOME/.ssh/id_rsa http://$SECRET_HOST_IP/ssh/id_rsa
wget -O $HOME/.ssh/known_hosts http://$SECRET_HOST_IP/ssh/known_hosts
chmod -R 600 $HOME/.ssh

git clone --branch "${PTXDIST_COMMIT}" --single-branch "${PTXDIST_REPO}" "/tmp/ptxdist/src"

pushd "/tmp/ptxdist/src"

./autogen.sh
./configure
make
make install

popd

rm -rf "$HOME/.ssh"
rm -rf "/tmp/ptxdist"
