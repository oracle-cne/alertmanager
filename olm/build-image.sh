#!/usr/bin/env bash

mkdir -p bin
name="alertmanager"
version="0.28.1"
registry="container-registry.oracle.com/olcne"
docker_tag=${registry}/${name}:v${version}

GIT_REVISION=$(git rev-parse --long HEAD)
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
ldflags="
        -X main.version=v%{version}
        -X github.com/prometheus/common/version.Version=%{version}
        -X github.com/prometheus/common/version.Revision=${GIT_REVISION}
        -X github.com/prometheus/common/version.Branch=HEAD
        -X github.com/prometheus/common/version.BuildUser=${USER}@${HOST}
        -X github.com/prometheus/common/version.BuildDate=${BUILD_DATE}"
go build -trimpath=false -v -o bin/ \
    -ldflags "${ldflags}" \
    ${GOPATH_SRC}/cmd/alertmanager \
    ${GOPATH_SRC}/cmd/amtool

docker build --pull \
    --build-arg https_proxy=${https_proxy} \
    -t ${docker_tag} -f ./olm/builds/Dockerfile .
docker save -o ${name}.tar ${docker_tag}
