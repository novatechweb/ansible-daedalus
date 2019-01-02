FROM  buildbot/buildbot-master:v1.6.0
LABEL maintainer="Andrew Cooper <andrew.cooper@novatechweb.com>"

ARG BUILDBOT_TIMEZONE="Etc/UTC"

RUN apk --no-cache add \
        openssh \
&&  rm /etc/localtime \
&&  ln -sf /usr/share/zoneinfo/${BUILDBOT_TIMEZONE} /etc/localtime \
&&  echo "${BUILDBOT_TIMEZONE}" > /etc/timezone

# install pip dependencies
RUN pip --no-cache-dir install \
    'attrs' \
    'buildbot-console-view' \
    'buildbot-grid-view' \
    'buildbot-waterfall-view' \
    'buildbot-www'

# Create buildbot user
ARG BUILDBOT_UID=1000
WORKDIR /buildbot
COPY buildbot/ /home/buildbot/
RUN adduser -h "/home/buildbot" -s "/bin/sh" -D -u ${BUILDBOT_UID} buildbot \
&&  mkdir -p -m 0600 "/home/buildbot/.ssh" \
&&  chown -v -R buildbot:buildbot "/buildbot" \
&&  chown -v -R buildbot:buildbot "/home/buildbot"

USER buildbot
CMD ["/home/buildbot/start.sh"]
