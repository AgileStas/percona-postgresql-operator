FROM goboring/golang:1.16.7b7 AS go_builder
WORKDIR /go/src/github.com/percona/percona-postgresql-operator

COPY . .

RUN GOBIN="$(pwd -P)/hack/tools" ./hack/update-codegen.sh

ARG GIT_COMMIT
ARG GIT_BRANCH
ARG GO_LDFLAGS
ARG GOOS=linux
ARG GOARCH=amd64
ARG CGO_ENABLED=0

RUN ls -la && mkdir -p build/_output/bin \
    && CGO_ENABLED=$CGO_ENABLED GOOS=$GOOS GOARCH=$GOARCH GO_LDFLAGS=$GO_LDFLAGS \
        go build -ldflags "-w -s -X main.GitCommit=$GIT_COMMIT -X main.GitBranch=$GIT_BRANCH" \
            -o build/_output/bin/pgo-rmdata \
            ./cmd/pgo-rmdata \
    && cp -r build/_output/bin/pgo-rmdata /usr/local/bin/pgo-rmdata

RUN ./bin/license_aggregator.sh; \
    cp -r ./licenses /licenses

FROM redhat/ubi8-minimal

LABEL name="Data removal wrapper for Percona Postgres Operator" \
      vendor="Percona" \
      summary="Percona Postgres database remover" \
      description="Container is used to wipe out all possible data for a particular database cluster." \
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

COPY --from=go_builder /usr/local/bin/pgo-rmdata /usr/local/bin
COPY --from=go_builder /licenses /licenses
COPY bin/pgo-rmdata/ /usr/local/bin

USER 2

CMD ["/usr/local/bin/start.sh"]
