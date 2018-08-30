#
# GitLab Docker container
#
# Version 0.1

ARG  GITLAB_VERSION=7.14.3
FROM sameersbn/gitlab:$GITLAB_VERSION
MAINTAINER Joseph Lutz <Joseph.Lutz@novatechweb.com>

# copy wrapper script
COPY ./wrapper.sh /

VOLUME ["/home/git/data"]

# start the entrypoint script
ENTRYPOINT ["/wrapper.sh"]
