FROM goboring/golang:1.16.7b7 AS go_builder
WORKDIR /go/src/github.com/percona/percona-postgresql-operator

COPY . .

ARG GIT_COMMIT
ARG GIT_BRANCH
ARG GO_LDFLAGS
ARG GOOS=linux
ARG GOARCH=amd64
ARG CGO_ENABLED=0

RUN ls -la && mkdir -p build/_output/bin \
    && CGO_ENABLED=$CGO_ENABLED GOOS=$GOOS GOARCH=$GOARCH GO_LDFLAGS=$GO_LDFLAGS \
        go build -ldflags "-w -s -X main.GitCommit=$GIT_COMMIT -X main.GitBranch=$GIT_BRANCH" \
            -o build/_output/bin/apiserver \
            ./cmd/apiserver \
    && cp -r build/_output/bin/apiserver /usr/local/bin/apiserver

RUN ./bin/license_aggregator.sh; \
    cp -r ./licenses /licenses

FROM redhat/ubi8-minimal

LABEL name="Percona Postgres Operator API server" \
      vendor="Percona" \
      summary="API server for Percona Postgres database management" \
      description="Percona Postgres Operator API server allows user clients to interact with Percona Postgres Operator software bundle and run databases in kubectl manner" \
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

RUN set -ex; \
    microdnf -y install \
        hostname; \
    microdnf clean all

COPY --from=go_builder /usr/local/bin/apiserver /usr/local/bin
COPY --from=go_builder /licenses /licenses
COPY installers/ansible/roles/pgo-operator/files/pgo-configs /default-pgo-config
COPY conf/postgres-operator/pgo.yaml /default-pgo-config/pgo.yaml

USER 2

ENTRYPOINT ["/usr/local/bin/apiserver"]
