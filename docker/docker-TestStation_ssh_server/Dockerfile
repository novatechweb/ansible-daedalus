FROM ubuntu:14.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                    gcc=4:4* \
                    mysql-client=5.5* \
                    libmysqlclient-dev=5.5* \
                    subversion=1.8* \
                    python-pip=1.5* \
                    python-setuptools=3.3* \
                    libpython-dev=2.7* \
                    python-svn=1.7* \
                    openssh-server=1:6* \
						  rsync=3.1* && \
    rm -rf /var/lib/apt/lists/*
#---------------------------
RUN pip install "django<1.8" \
                "mysqlclient>=1.3" \
                "pyserial>=2.7"
#---------------------------

RUN mkdir /var/run/sshd
RUN echo 'root:root_user_password' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

WORKDIR /opt

EXPOSE 22

RUN mkdir /root/.ssh/; chmod 700 /root/.ssh
COPY ./id_rsa_buildsystem.pub /root/.ssh/authorized_keys

COPY ./entrypoint.sh /
RUN chmod 777 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["sshd"]

