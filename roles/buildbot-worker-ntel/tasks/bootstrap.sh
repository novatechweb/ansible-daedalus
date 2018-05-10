#!/bin/sh

DIRS="/cache \
      /cache/ccache \
      /cache/downloads \
      /cache/images \
      /cache/ipkg-repository \
      /cache/mirrors \
      /cache/releases \
      /cache/sstate"

for d in $DIRS
do
  mkdir -p $d
  chown -c -R buildbot:buildbot $d
  chmod -v 777 $d
done
