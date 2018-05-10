FROM        buildbot/buildbot-master:v0.9.13
MAINTAINER  Andrew Cooper <andrew.cooper@novatechweb.com>

WORKDIR /buildbot

ARG BUILDBOT_UID=1000
ARG BUILDBOT_TIMEZONE="Etc/UTC"

RUN apk --no-cache add \
        openssh \
        tini \
&&  rm /etc/localtime \
&&  ln -sf /usr/share/zoneinfo/${BUILDBOT_TIMEZONE} /etc/localtime \
&&  echo "${BUILDBOT_TIMEZONE}" > /etc/timezone

# install pip dependencies
RUN pip --no-cache-dir install \
    'attrs'

# Create buildbot user
ARG BUILDBOT_UID=1000
COPY buildbot/ /home/buildbot/
RUN adduser -h "/home/buildbot" -s "/bin/sh" -D -u ${BUILDBOT_UID} buildbot \
&&  chown -v -R buildbot:buildbot "/buildbot" \
&&  chown -v -R buildbot:buildbot "/home/buildbot"

USER buildbot
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/home/buildbot/start.sh"]
