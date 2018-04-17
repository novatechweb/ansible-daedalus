FROM ubuntu:14.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                    mysql-client=5.5* \
                    openssh-client=1:6* && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /root/.ssh/; chmod 700 /root/.ssh
COPY ./ssh_files/config /root/.ssh/config
COPY ./ssh_files/id_rsa_new_supportsite_deploy /root/.ssh/id_rsa_new_supportsite_deploy
COPY ./ssh_files/id_rsa_buildsystem /root/.ssh/id_rsa_buildsystem
RUN chmod 700 /root/.ssh/*

ENV DATABASE_PASSWORD root_password

COPY ./entrypoint.sh /
RUN chmod 777 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["command_line"]
