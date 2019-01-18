#!/bin/sh

ln -v -s -f ${HOME}/buildbot.tac /buildbot
exec twistd --nodaemon --logfile=- --pidfile= --python=buildbot.tac
