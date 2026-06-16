FROM container-registry.oracle.com/os/oraclelinux:9 AS builder

ARG GOLANG_VERSION

ENV NPM_CONFIG_USERCONFIG=/run/npm-config/.npmrc

RUN dnf module install -y nodejs:24 && \
    dnf -y install git make golang-${GOLANG_VERSION} hostname npm && \
    dnf clean all && \
    go version && \
    node --version && \
    npm --version

# Copy the contents of the repository
COPY . /workspace/go/src/github.com/oracle-cne/alertmanager

ENV GOPATH=/workspace/go CGO_ENABLED=0 GOTOOLCHAIN=local
ENV GOPATH_SRC=$GOPATH/src/github.com/oracle-cne/alertmanager
WORKDIR /workspace/go/src/github.com/oracle-cne/alertmanager

RUN --mount=type=secret,id=npmrc,target=/run/npm-config/.npmrc \
    git config --global --add safe.directory $(pwd) && \
    bash olm/go-build.sh

FROM container-registry.oracle.com/os/oraclelinux:9-slim

COPY LICENSE THIRD_PARTY_LICENSES.txt olm/SECURITY.md /usr/share/licenses/alertmanager/
COPY examples/ha/alertmanager.yml /etc/alertmanager/
COPY --from=builder /workspace/go/src/github.com/oracle-cne/alertmanager/bin/alertmanager /usr/bin/alertmanager
COPY --from=builder /workspace/go/src/github.com/oracle-cne/alertmanager/bin/amtool /usr/bin/amtool

RUN microdnf update -y &&\
    microdnf clean all &&\
    rm -rf /var/cache/yum/* &&\
    mkdir -p /alertmanager && \
    chown -R nobody:nobody /etc/alertmanager /alertmanager && \
    test -d /LICENSES || ln -s /usr/share/licenses /LICENSES

ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

USER       nobody
EXPOSE     9093
VOLUME     [ "/alertmanager" ]
WORKDIR    /alertmanager
ENTRYPOINT [ "/usr/bin/alertmanager" ]
CMD        [ "--config.file=/etc/alertmanager/alertmanager.yml", "--storage.path=/alertmanager" ]
