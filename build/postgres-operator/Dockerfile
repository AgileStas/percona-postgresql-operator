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
            -o build/_output/bin/postgres-operator \
            ./cmd/postgres-operator \
    && cp -r build/_output/bin/postgres-operator /usr/local/bin/postgres-operator

RUN ./bin/license_aggregator.sh; \
    cp -r ./licenses /licenses

FROM redhat/ubi8-minimal

LABEL name="Percona Postgres Operator" \
      vendor="Percona" \
      summary="Percona Postgres Operator performs Postgres database creation, adjustment and maintenance inside Kubernetes cluster" \
      description="Percona Postgres Operator simplifies and automates all essential actions for stable and continious database operation during the whole database lifecycle" \
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

COPY --from=go_builder /usr/local/bin/postgres-operator /usr/local/bin
COPY --from=go_builder /licenses /licenses
COPY installers/ansible/roles/pgo-operator/files/pgo-backrest-repo /default-pgo-backrest-repo
COPY installers/ansible/roles/pgo-operator/files/pgo-configs /default-pgo-config
COPY conf/postgres-operator/pgo.yaml /default-pgo-config/pgo.yaml
COPY percona/templates/cluster-deployment.json /

USER 2

ENTRYPOINT ["postgres-operator"]
