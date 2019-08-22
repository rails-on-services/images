FROM ruby:2.6.3-stretch

ARG PUID=1000
ARG PGID=1000

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && apt-get install --yes --no-install-recommends \
      locales sudo openssh-client ca-certificates tar gzip parallel \
      net-tools netcat unzip zip bzip2 gnupg curl wget less git python-setuptools python-pip \
    && pip install ansible docker-compose \
    && apt-get clean

# install docker
RUN set -ex \
  && export DOCKER_VERSION=$(curl --silent --fail --retry 3 https://download.docker.com/linux/static/stable/x86_64/ | grep -o -e 'docker-[.0-9]*\.tgz' | sort -r | head -n 1) \
  && DOCKER_URL="https://download.docker.com/linux/static/stable/x86_64/${DOCKER_VERSION}" \
  && echo Docker URL: $DOCKER_URL \
  && curl --silent --show-error --location --fail --retry 3 --output /tmp/docker.tgz "${DOCKER_URL}" \
  && ls -lha /tmp/docker.tgz \
  && tar -xz -C /tmp -f /tmp/docker.tgz \
  && mv /tmp/docker/* /usr/bin \
  && rm -rf /tmp/docker /tmp/docker.tgz \
  && which docker \
  && (docker version || true)

RUN addgroup --gid ${PGID} cli \
    && useradd --shell /bin/bash --uid ${PUID} --gid ${PGID} --create-home cli \
    && echo 'cli ALL=NOPASSWD: ALL' >> /etc/sudoers.d/50-cli

USER cli
WORKDIR /home/cli
ENV SHELL=/bin/bash

# Docker layer cache will never be updated with a basic git clone statement
# So we use the add statement to get the current version of master; if no change then cached, otherwise rebuild
ARG SHA=LATEST
# RUN SHA=$(curl -s 'https://api.github.com/repos/rails-on-services/setup/commits' | grep sha | head -1)
RUN SHA=$(curl -s 'https://api.github.com/repos/rails-on-services/cli/commits' | grep sha | head -1)
RUN mkdir -p ros \
    && git clone https://github.com/rails-on-services/setup.git ros/setup \
    && (cd ros/setup; bash -l -c "./cli.yml") \
    && (cd ros/setup; bash -l -c "./devops.yml" )

CMD ["/bin/bash", "-l"]
