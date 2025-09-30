#!/usr/bin/env bash

name="alertmanager"
version={{{ .major }}}.{{{ .minor }}}.{{{ .patch }}}"
registry="container-registry.oracle.com/olcne"
docker_tag=${registry}/${name}:v${version}

docker build --pull \
    --build-arg https_proxy=${https_proxy} \
    -t ${docker_tag} -f ./olm/builds/Dockerfile .
docker save -o ${name}.tar ${docker_tag}
