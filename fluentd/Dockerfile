FROM fluent/fluentd:edge-debian
MAINTAINER Duan Shiqiang <duan@perxtech.com>

USER root

RUN buildDeps="make gcc g++ libc-dev wget bzip2 gnupg dirmngr" \
  && apt-get update \
  && apt-get install -y --no-install-recommends $buildDeps \
  && gem install --no-document \
        #Do we ever use below plugin somewhere? 
        #One of its dependencies isn't compatible with Ruby 2.6
        #Comment it for now and see if it can be built
        #fluent-plugin-google-cloud \
        fluent-plugin-detect-exceptions \
        fluent-plugin-to_js \
        fluent-plugin-systemd \
        fluent-plugin-prometheus \
        fluent-plugin-record-modifier \
        fluent-plugin-record-reformer \
        fluent-plugin-kubernetes_metadata_filter \
        fluent-plugin-s3 \
        fluent-plugin-kafka \
        fluent-plugin-filter-base64-decode \
  && gem sources --clear-all \
  && SUDO_FORCE_REMOVE=yes \
    apt-get purge -y --auto-remove \
                  -o APT::AutoRemove::RecommendsImportant=false \
                  $buildDeps \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem \
  && mkdir -p /fluentd/etc/config.d

COPY fluent.conf /fluentd/etc/

ENV FLUENTD_OPT=""
ENV FLUENTD_CONF="fluent.conf"

USER fluent

CMD fluentd -c /fluentd/etc/${FLUENTD_CONF} $FLUENTD_OPT
