FROM debian:stretch

ARG os_base_packages='llinux-image-amd64 kmod s3fs'
ARG os_packages='tree less vim'

# Steps done in one RUN layer:
# - Install packages
# - OpenSSH needs /var/run/sshd to run
# - Remove generic host keys, entrypoint generates unique keys
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && apt-get upgrade --yes \
    && apt-get install --yes --no-install-recommends ${os_base_packages} ${os_packages} \
    && apt-get install --yes openssh-server python3 python3-pip \
    && apt-get clean \
    && pip3 install --no-cache-dir supervisor awscli \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/run/sshd \
    && rm -f /etc/ssh/ssh_host_*key* \
    && echo 'set editing-mode vi' > /root/.inputrc

RUN mkdir -p /etc/supervisor/conf.d
COPY files/supervisord.conf /etc/supervisor/supervisord.conf
COPY files/entrypoint /
COPY files/sshd_config /etc/ssh/sshd_config
COPY files/update-sftp-user /usr/local/bin/update-sftp-user

RUN chmod +x /usr/local/bin/update-sftp-user

EXPOSE 22
ENV MOUNT_OPTIONS=""
ENV BUCKET_PREFIX=""

ENTRYPOINT ["/entrypoint"]
