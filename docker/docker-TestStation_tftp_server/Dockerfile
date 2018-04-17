FROM ubuntu:14.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                    tftpd-hpa=5.* && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 69/udp

#CMD ["/usr/sbin/in.tftpd","--foreground","--user","tftp","--address" "0.0.0.0:69","-s","/opt/tftp_files"]
CMD /usr/sbin/in.tftpd --foreground --user tftp --address 0.0.0.0:69 -s /opt/tftp_files

