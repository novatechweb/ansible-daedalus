FROM ubuntu:14.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                    openssh-server=1:6* && \
    rm -rf /var/lib/apt/lists/*


RUN adduser --disabled-password --gecos "" --quiet some_additional_user
RUN echo 'some_additional_user:some_additional_user_password' | chpasswd
RUN echo 'root:root_user_password' | chpasswd

COPY ssh_config /home/some_additional_user/.ssh
COPY shell_scripts/lxm_io_test_ts5_hv.sh     /home/some_additional_user/lxm_io_test_ts5_hv.sh  
COPY shell_scripts/lxm_io_test_ts5.sh        /home/some_additional_user/lxm_io_test_ts5.sh  
COPY shell_scripts/lxm_io_test_ts6_hv.sh     /home/some_additional_user/lxm_io_test_ts6_hv.sh  
COPY shell_scripts/lxm_io_test_ts6.sh        /home/some_additional_user/lxm_io_test_ts6.sh  
COPY shell_scripts/lxm_io_test_ts_soft_hv.sh /home/some_additional_user/lxm_io_test_ts_soft_hv.sh  
COPY shell_scripts/lxm_io_test_ts_soft.sh    /home/some_additional_user/lxm_io_test_ts_soft.sh
RUN chown -R some_additional_user:some_additional_user /home/some_additional_user

RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile


EXPOSE 22

RUN mkdir /var/run/sshd
COPY ./entrypoint.sh /
RUN chmod 777 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["sshd"]
