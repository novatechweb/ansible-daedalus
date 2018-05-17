#!/bin/sh

BUILDBOT_DATA=${BUILDBOT_DATA-"/buildbot"}

mkdir -p ${HOME}/.ssh
cp -R /run/secrets/ssh/* ${HOME}/.ssh
chmod -R 600 ${HOME}/.ssh/*

ln -v -s -f ${HOME}/buildbot.tac ${HOME}/master.cfg ${HOME}/*.py $BUILDBOT_DATA

# Run original buildbot entrypoint
exec "/usr/src/buildbot/docker/start_buildbot.sh"
