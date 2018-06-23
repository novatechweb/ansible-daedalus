#
# GitLab Docker container
#
# Version 0.1

FROM sameersbn/gitlab:8.0.5
MAINTAINER Joseph Lutz <Joseph.Lutz@novatechweb.com>

# copy wrapper script
COPY ./wrapper.sh /

VOLUME ["/home/git/data"]

# start the entrypoint script
ENTRYPOINT ["/wrapper.sh"]
