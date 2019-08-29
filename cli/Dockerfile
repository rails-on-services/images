FROM debian:stretch

ARG PUID=1000
ARG PGID=1000

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && apt-get install --yes --no-install-recommends \
      locales sudo openssh-client apt-transport-https ca-certificates tar gzip parallel \
      software-properties-common bash-completion unzip zip bzip2 gnupg curl wget \
      less git python-setuptools python-pip \
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

# setup repo's version to checkout, it can be the a branch name, a tag name, or a commit hash
# passing exact sha instead of branch name will make sure docker layer cache doesn't cache unexpectedly
ARG SETUP_VERSION=master
RUN mkdir -p ros \
    && git clone https://github.com/rails-on-services/setup.git ros/setup \
    && (cd ros/setup; git checkout ${SETUP_VERSION}) \
    && (cd ros/setup; bash -l -c "./devops.yml" )

# setup repo's version to checkout, it can be the a branch name, a tag name, or a commit hash
# passing exact sha instead of branch name will make sure docker layer cache doesn't cache unexpectedly
ARG CLI_VERSION=master
RUN cd ros/setup; bash -l -c "./cli.yml --extra-vars ros_cli_version=${CLI_VERSION}"

CMD ["/bin/bash", "-l"]
