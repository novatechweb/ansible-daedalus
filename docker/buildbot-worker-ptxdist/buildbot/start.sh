#!/bin/sh

SSH_BITS=${SSH_BITS-"2048"}
SSH_TYPE=${SSH_TYPE-"rsa"}
SSH_FILE=${SSH_FILE-"$HOME/.ssh/id_rsa"}

BUILDBOT_DATA=${BUILDBOT_DATA-"/buildbot"}

ssh-keygen -q -b ${SSH_BITS} -t ${SSH_TYPE} -N '' -f ${SSH_FILE} 0>&- 1>/dev/null 2>/dev/null

ln -v -s -f ${HOME}/buildbot.tac $BUILDBOT_DATA
exec twistd --nodaemon --logfile=- --pidfile=/tmp/twistd.pid --python=buildbot.tac
