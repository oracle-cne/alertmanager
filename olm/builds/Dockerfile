FROM container-registry.oracle.com/os/oraclelinux:8
COPY rpms /tmp/
RUN dnf install -y /tmp/*.rpm &&\
    dnf clean all &&\
    rm -rf /var/cache/yum/* /tmp/*.rpm

FROM container-registry.oracle.com/os/oraclelinux:8-slim

COPY --from=0 /usr/share/licenses/alertmanager /usr/share/licenses/alertmanager
COPY --from=0 /etc/alertmanager /etc/alertmanager
COPY --from=0 /usr/bin/alertmanager /usr/bin/alertmanager
COPY --from=0 /usr/bin/amtool /usr/bin/amtool
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
