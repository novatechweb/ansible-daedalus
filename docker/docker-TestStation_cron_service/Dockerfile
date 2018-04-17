FROM ubuntu:14.04

#---------------------------
RUN apt-get update  && \
    apt-get install -y --no-install-recommends \
                    python=2.7* && \
    rm -rf /var/lib/apt/lists/*
#---------------------------

COPY remove_files.py /usr/bin/remove_files.py
RUN chmod 0755 /usr/bin/remove_files.py

# Add removefile-cron file in the cron directory
ADD removefile-cron /etc/cron.d/removefile-cron
 
# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/removefile-cron && \
    crontab /etc/cron.d/removefile-cron


# Run the command on container startup
CMD ["/usr/sbin/cron", "-f"]
