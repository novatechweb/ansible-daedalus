#!/bin/sh

/usr/bin/buildbot --verbose upgrade-master
exec twistd --nodaemon --logfile=- --pidfile=/tmp/twistd.pid --python=/home/buildbot/buildbot.tac
