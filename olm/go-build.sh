#!/usr/bin/env bash

set -euo pipefail

log() {
    echo "go-build.sh: $*"
}

mkdir -p bin
version="0.33.0"
build_host="${HOST:-$(hostname)}"
build_user="${USER:-$(id -un)}@${build_host}"
go_source="${GOPATH_SRC:-$(pwd)}"

log "starting alertmanager build"
log "building JavaScript UI assets"
make ui-elm

GIT_REVISION=$(git rev-parse HEAD)
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
ldflags="
        -X main.version=v${version}
        -X github.com/prometheus/common/version.Version=${version}
        -X github.com/prometheus/common/version.Revision=${GIT_REVISION}
        -X github.com/prometheus/common/version.Branch=HEAD
        -X github.com/prometheus/common/version.BuildUser=${build_user}
        -X github.com/prometheus/common/version.BuildDate=${BUILD_DATE}"

log "git_revision=${GIT_REVISION}"
log "build_date=${BUILD_DATE}"
log "build_user=${build_user}"
log "go_version=$(go version)"
log "compiling Go binaries"
go build -trimpath=false -v -o bin/ \
    -ldflags "${ldflags}" \
    "${go_source}"/cmd/alertmanager \
    "${go_source}"/cmd/amtool

log "verifying alertmanager binary"
./bin/alertmanager --version
log "verifying amtool binary"
./bin/amtool --version
log "completed alertmanager build"
