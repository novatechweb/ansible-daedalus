ARG  GITLAB_VERSION=latest
FROM gitlab/gitlab-ce:${GITLAB_VERSION}

COPY gitlab.rb /opt/gitlab/etc/gitlab.rb.template
COPY entrypoint.sh /entrypoint.sh
RUN  chmod +x /entrypoint.sh
CMD [ "/entrypoint.sh", "/assets/wrapper" ]
