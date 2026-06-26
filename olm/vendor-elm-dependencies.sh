#!/usr/bin/env bash
# Refresh the unpacked Elm package cache vendored under ui/app/vendor.
set -euo pipefail
shopt -s dotglob nullglob

log() {
  printf '>> %s\n' "$*"
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd -- "${SCRIPT_DIR}/../ui/app" && pwd)"

ELM="${ELM:-elm}"
ELM_VERSION="${ELM_VERSION:-0.19.1}"
ELM_MAIN="${ELM_MAIN:-src/Main.elm}"
ELM_VENDOR_HOME="${ELM_VENDOR_HOME:-${APP_DIR}/vendor/elm-home}"
ELM_DOWNLOAD_HOME="${ELM_DOWNLOAD_HOME:-}"

VENDOR_VERSION_DIR="${ELM_VENDOR_HOME}/${ELM_VERSION}"
VENDOR_PACKAGES="${VENDOR_VERSION_DIR}/packages"

log "starting Elm dependency vendoring"
log "application directory: ${APP_DIR}"
log "Elm binary: ${ELM}"
log "Elm version: ${ELM_VERSION}"
log "Elm entrypoint: ${ELM_MAIN}"
log "vendor home: ${ELM_VENDOR_HOME}"

cd "${APP_DIR}"

[[ -f elm.json ]] || fail "elm.json not found in ${APP_DIR}"
[[ -f "${ELM_MAIN}" ]] || fail "Elm entrypoint ${ELM_MAIN} not found"
command -v "${ELM}" >/dev/null 2>&1 || fail "Elm binary ${ELM} was not found on PATH"

ACTUAL_ELM_VERSION="$("${ELM}" --version)"
log "detected Elm compiler version: ${ACTUAL_ELM_VERSION}"
[[ "${ACTUAL_ELM_VERSION}" = "${ELM_VERSION}" ]] || fail "expected Elm ${ELM_VERSION}, got ${ACTUAL_ELM_VERSION}"

if [[ -z "${ELM_DOWNLOAD_HOME}" ]]; then
  WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/alertmanager-elm-vendor.XXXXXX")"
  ELM_DOWNLOAD_HOME="${WORK_DIR}/elm-home"
  CLEAN_WORK_DIR="${WORK_DIR}"
  log "created temporary Elm home: ${ELM_DOWNLOAD_HOME}"
else
  CLEAN_WORK_DIR=""
  log "using caller-provided Elm download home: ${ELM_DOWNLOAD_HOME}"
fi

cleanup() {
  if [[ -n "${CLEAN_WORK_DIR}" ]]; then
    log "removing temporary directory: ${CLEAN_WORK_DIR}"
    rm -rf "${CLEAN_WORK_DIR}"
  fi
}
trap cleanup EXIT

OUTPUT_FILE="$(mktemp "${TMPDIR:-/tmp}/alertmanager-elm-output.XXXXXX.js")"
trap 'rm -f "${OUTPUT_FILE}"; cleanup' EXIT

log "running elm make to populate package cache"
ELM_HOME="${ELM_DOWNLOAD_HOME}" "${ELM}" make "${ELM_MAIN}" --output="${OUTPUT_FILE}" --optimize

DOWNLOAD_PACKAGES="${ELM_DOWNLOAD_HOME}/${ELM_VERSION}/packages"
[[ -d "${DOWNLOAD_PACKAGES}" ]] || fail "Elm package cache was not created at ${DOWNLOAD_PACKAGES}"
[[ -f "${DOWNLOAD_PACKAGES}/registry.dat" ]] || fail "Elm package registry was not created at ${DOWNLOAD_PACKAGES}/registry.dat"

PACKAGE_COUNT="$(find "${DOWNLOAD_PACKAGES}" -type f | wc -l | tr -d ' ')"
log "downloaded package cache files: ${PACKAGE_COUNT}"
[[ "${PACKAGE_COUNT}" -gt 0 ]] || fail "Elm package cache is empty"

STAGING_PACKAGES="${VENDOR_VERSION_DIR}/packages.tmp.$$"
log "staging refreshed vendor packages: ${STAGING_PACKAGES}"
rm -rf "${STAGING_PACKAGES}"
mkdir -p "${VENDOR_VERSION_DIR}"
cp -R "${DOWNLOAD_PACKAGES}" "${STAGING_PACKAGES}"

log "replacing vendor packages: ${VENDOR_PACKAGES}"
rm -rf "${VENDOR_PACKAGES}"
mv "${STAGING_PACKAGES}" "${VENDOR_PACKAGES}"

log "vendored Elm package files: $(find "${VENDOR_PACKAGES}" -type f | wc -l | tr -d ' ')"
log "vendored Elm packages refreshed successfully"
