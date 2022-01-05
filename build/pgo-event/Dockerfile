FROM redhat/ubi8-minimal

LABEL name="Event dispatcher for Percona Postgres Operator" \
      vendor="Percona" \
      summary="Users entrypoint to cluster database events" \
      description="The container provides an interface for User to check lifecycle events of the database cluster" \
      maintainer="Percona Development <info@percona.com>"

# Check https://access.redhat.com/errata/RHBA-2020:4536
# and https://bugzilla.redhat.com/show_bug.cgi?id=1832743
# for sources of enabling FIPS-140-2 support
RUN set -ex; \
    microdnf update; \
    microdnf -y install crypto-policies-scripts; \
    microdnf clean all; \
    fips-mode-setup --enable

COPY redhat/licenses /licenses
COPY redhat/atomic/help.1 /help.1
COPY redhat/atomic/help.md /help.md
COPY licenses /licenses

RUN set -ex; \
    microdnf -y install \
        gzip \
        tar; \
    curl -S https://s3.amazonaws.com/bitly-downloads/nsq/nsq-1.1.0.linux-amd64.go1.10.3.tar.gz | \
        tar xz --strip=2 -C /usr/local/bin/ '*/bin/*'

COPY bin/pgo-event /usr/local/bin

USER 2

ENTRYPOINT ["/usr/local/bin/pgo-event.sh"]
