FROM debian:buster

ARG os_base_packages='linux-image-amd64 kmod s3fs'

# Install base packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && apt-get upgrade --yes \
    && apt-get install --yes --no-install-recommends ${os_base_packages} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG os_packages='openssh-server python3 python3-pip tree less vim ruby'

# Install additional base packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && apt-get install --yes --no-install-recommends ${os_packages} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install python and ruby packages
RUN pip3 install --no-cache-dir setuptools \
    && pip3 install --no-cache-dir supervisor awscli

RUN gem install config aws-sdk-s3 pry

# - OpenSSH needs /var/run/sshd to run
# - Remove generic host keys, entrypoint generates unique keys
RUN mkdir -p /var/run/sshd \
    && rm -f /etc/ssh/ssh_host_*key* \
    && echo 'set editing-mode vi' > /root/.inputrc \
    && mkdir -p /etc/supervisor/conf.d

ENV AWS_REGION=localstack

ENV PLATFORM__SSH__ROOT='/opt/sftp' PLATFORM__SSH__CACHE_ROOT='/var/run/sftp'

ENV PLATFORM__BUCKET__NAME=name
ENV PLATFORM__BUCKET__MOUNT_OPTIONS=""

ENV PLATFORM__MOUNTS__CONFIG__LOCAL_PATH='/opt/sftp' PLATFORM__MOUNTS__CONFIG__BUCKET_PATH='services/sftp/config'
ENV PLATFORM__MOUNTS__HOME__LOCAL_PATH='/home' PLATFORM__MOUNTS__HOME__BUCKET_PATH='services/storage/tenants'

COPY files/sshd_config /etc/ssh/sshd_config
COPY files/update-sftp-user /usr/local/bin/update-sftp-user
RUN chmod +x /usr/local/bin/update-sftp-user
COPY files/supervisord.conf.erb /
COPY files/entrypoint.rb /
COPY files/entrylib.rb /

EXPOSE 22
ENTRYPOINT ["/entrypoint.rb"]
