#!/bin/bash

PWD=$(readlink -f $(dirname $0))
CONTEXT=$(readlink -f "$PWD/..")
cd $PWD

docker build \
--build-arg UID="$(id -u)" \
--build-arg GID="$(id -g)" \
--pull \
--tag "daedalus-provisioner:latest" \
"$PWD"
