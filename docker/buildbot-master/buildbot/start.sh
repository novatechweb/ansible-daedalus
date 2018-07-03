#!/bin/sh

SSH_BITS=${SSH_BITS-"2048"}
SSH_TYPE=${SSH_TYPE-"rsa"}
SSH_FILE=${SSH_FILE-"$HOME/.ssh/id_rsa"}

BUILDBOT_DATA=${BUILDBOT_DATA-"/buildbot"}

ssh-keygen -q -b ${SSH_BITS} -t ${SSH_TYPE} -N '' -f ${SSH_FILE} 0>&- 1>/dev/null 2>/dev/null

ln -v -s -f ${HOME}/buildbot.tac ${HOME}/master.cfg ${HOME}/*.py $BUILDBOT_DATA

# Run original buildbot entrypoint
exec "/usr/src/buildbot/docker/start_buildbot.sh"
