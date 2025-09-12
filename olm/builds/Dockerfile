FROM container-registry.oracle.com/os/oraclelinux:9 AS builder

RUN dnf config-manager --enable ol9_codeready_builder && \
    dnf -y install git make golang hostname && \
    go version

# Copy the contents of the repository
COPY . /workspace/go/src/github.com/oracle-cne/alertmanager

ENV GOPATH=/workspace/go CGO_ENABLED=0
ENV GOPATH_SRC=$GOPATH/src/github.com/oracle-cne/alertmanager
WORKDIR /workspace/go/src/github.com/oracle-cne/alertmanager

RUN git config --global --add safe.directory $(pwd) && \
    sh go-build.sh

FROM container-registry.oracle.com/os/oraclelinux:9-slim

COPY LICENSE THIRD_PARTY_LICENSES.txt olm/SECURITY.md /usr/share/licenses/alertmanager/
COPY examples/ha/alertmanager.yml /etc/alertmanager/
COPY bin/alertmanager /usr/bin/alertmanager
COPY bin/amtool /usr/bin/amtool

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
