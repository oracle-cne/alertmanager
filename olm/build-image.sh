#!/usr/bin/env bash

set -euo pipefail

name="alertmanager"
version="0.33.0"
registry="container-registry.oracle.com/olcne"
docker_tag=${registry}/${name}:v${version}
golang_version="${GOLANG_VERSION:-${1:-}}"
npm_config="${NPM_CONFIG_USERCONFIG:-}"
tmp_npm_config=""

cleanup() {
    if [[ -n "${tmp_npm_config}" ]]; then
        rm -f "${tmp_npm_config}"
    fi
}
trap cleanup EXIT

set -x

if [[ -z "${golang_version}" ]]; then
    echo "build-image.sh: unable to determine Go version; set GOLANG_VERSION or pass it as the first argument" >&2
    exit 1
fi

if [[ -z "${npm_config}" && -n "${HOME:-}" && -s "${HOME}/.npmrc" ]]; then
    npm_config="${HOME}/.npmrc"
    echo "build-image.sh: using npm config file from HOME: ${npm_config}"
fi

if [[ -n "${npm_config}" && "${npm_config}" != /* ]]; then
    npm_config="$(pwd)/${npm_config}"
fi

build_args=(
    --pull
    --build-arg "GOLANG_VERSION=${golang_version}"
    -t "${docker_tag}"
    -f ./olm/builds/Dockerfile
    .
)

if [[ -n "${npm_config}" ]]; then
    if [[ ! -s "${npm_config}" ]]; then
        echo "build-image.sh: npm config file ${npm_config} is missing or empty; set NPM_CONFIG_USERCONFIG to a valid file or leave it unset" >&2
        exit 1
    fi

    echo "build-image.sh: mounting npm config file ${npm_config}"
else
    tmp_npm_config="$(mktemp)"
    npm_config="${tmp_npm_config}"
    echo "build-image.sh: no npm config file defined or found; mounting an empty npm config secret"
fi

build_args=(
    --secret "id=npmrc,src=${npm_config}"
    "${build_args[@]}"
)

mount_yum_config() {
    local yum_repo_config_file="${YUM_REPO_CONFIG_FILE:-}"

    if [[ -z "${yum_repo_config_file}" ]]; then
        echo "build-image.sh: YUM_REPO_CONFIG_FILE is not set; using base image repository configuration"
        return
    elif [[ "${yum_repo_config_file}" != /* ]]; then
        yum_repo_config_file="$(pwd)/${yum_repo_config_file}"
    fi

    echo "build-image.sh: checking yum repo config file ${yum_repo_config_file}"
    if [[ ! -s "${yum_repo_config_file}" ]]; then
        echo "build-image.sh: yum repo config file ${yum_repo_config_file} is missing or empty" >&2
        exit 1
    fi

    echo "build-image.sh: mounting yum repo config file ${yum_repo_config_file}"
    build_args=(
        --volume "${yum_repo_config_file}:/etc/yum.repos.d/extra.repo:ro"
        "${build_args[@]}"
    )
}

mount_yum_config

podman build "${build_args[@]}"

podman save "${docker_tag}" > "${name}.tar"
