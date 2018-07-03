#!/bin/sh

BUILDBOT_DATA=${BUILDBOT_DATA-"/buildbot"}

mkdir -p ${HOME}/.ssh
cp -R /run/secrets/ssh/* ${HOME}/.ssh
chmod -R 600 ${HOME}/.ssh/*

ln -v -s -f ${HOME}/buildbot.tac ${HOME}/master.cfg ${HOME}/*.py $BUILDBOT_DATA

/usr/bin/buildbot --verbose upgrade-master
exec twistd --nodaemon --logfile=- --pidfile=/tmp/twistd.pid --python=buildbot.tac
