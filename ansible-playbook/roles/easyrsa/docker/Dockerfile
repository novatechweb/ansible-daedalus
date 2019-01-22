FROM alpine:3.8

RUN apk --no-cache add \
        openssh-server-pam \
        openssh-client \
        libcrypto1.0 \
        libssl1.0 \
        openssl \
&&  rm /etc/motd \
&&  echo "UsePAM yes" >> /etc/ssh/sshd_config \
&&  ssh-keygen -A \
&&  /usr/sbin/sshd -t


ARG EASYRSA_UID=1000
WORKDIR /home/easyrsa
RUN adduser -h "/home/easyrsa" -s "/bin/ash" -D -u ${EASYRSA_UID} easyrsa \
&&  mkdir -p -m 0700 "/home/easyrsa/.ssh" \
&&  chown -v -R easyrsa:easyrsa "/home/easyrsa"

CMD ["/usr/sbin/sshd","-D","-e"]
