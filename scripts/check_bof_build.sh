#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ARTIFACT="${REPO_ROOT}/Bin/bof.o"
DOCKER_IMAGE_TAG="bof-spawn-build-check:latest"
DOCKER_ARTIFACT_IMAGE_TAG="bof-spawn-build-check-artifact:latest"

LOCAL_LOG="${TMPDIR:-/tmp}/check_bof_build_local.$$"
CONTAINER_BASE_BUILD_LOG="${TMPDIR:-/tmp}/check_bof_build_container_base.$$"
CONTAINER_ARTIFACT_BUILD_LOG="${TMPDIR:-/tmp}/check_bof_build_container_artifact.$$"
CONTAINER_COPY_LOG="${TMPDIR:-/tmp}/check_bof_build_container_copy.$$"

RUN_LOCAL=0
RUN_CONTAINER=0

print_usage() {
  cat <<'EOF'
Usage: bash scripts/check_bof_build.sh [--local] [--container]

Checks:
  --local      Run local build check only.
  --container  Run Dockerized build check only.

If no mode is provided, both local and container checks run.
EOF
}

info() {
  printf '[INFO] %s\n' "$1"
}

pass() {
  printf '[PASS] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  exit 1
}

cleanup_artifact() {
  rm -f "${ARTIFACT}"
  find "${REPO_ROOT}/Bin/temp" -maxdepth 1 -type f ! -name '.gitkeep' -delete
}

check_artifact() {
  if [[ ! -f "${ARTIFACT}" ]]; then
    fail "Bin/bof.o missing after ${1} build"
  fi

  local size
  size="$(wc -c <"${ARTIFACT}")"
  if [[ "${size}" -le 0 ]]; then
    fail "Bin/bof.o is empty after ${1} build"
  fi

  pass "${1} build produced Bin/bof.o (${size} bytes)"
}

run_local() {
  info "running local build verification"
  cleanup_artifact

  if ! (cd "${REPO_ROOT}" && make spawn_bof >"${LOCAL_LOG}" 2>&1); then
    tail -n 20 "${LOCAL_LOG}" >&2 || true
    fail "local build failed"
  fi

  check_artifact "local"
}

run_container() {
  info "running container build verification"
  cleanup_artifact

  if ! (cd "${REPO_ROOT}" && docker build --platform linux/amd64 -t "${DOCKER_IMAGE_TAG}" -f Dockerfile . >"${CONTAINER_BASE_BUILD_LOG}" 2>&1); then
    tail -n 20 "${CONTAINER_BASE_BUILD_LOG}" >&2 || true
    fail "docker build failed"
  fi

  if ! (
    cd "${REPO_ROOT}" && docker build --platform linux/amd64 -t "${DOCKER_ARTIFACT_IMAGE_TAG}" -f - . >"${CONTAINER_ARTIFACT_BUILD_LOG}" 2>&1 <<'EOF'
FROM bof-spawn-build-check:latest
WORKDIR /work
COPY . .
RUN make spawn_bof
EOF
  ); then
    tail -n 20 "${CONTAINER_ARTIFACT_BUILD_LOG}" >&2 || true
    fail "container artifact build failed"
  fi

  local cid
  cid="$(docker create --platform linux/amd64 "${DOCKER_ARTIFACT_IMAGE_TAG}")"
  if ! docker cp "${cid}:/work/Bin/bof.o" "${ARTIFACT}" >"${CONTAINER_COPY_LOG}" 2>&1; then
    tail -n 20 "${CONTAINER_COPY_LOG}" >&2 || true
    docker rm "${cid}" >/dev/null 2>&1 || true
    fail "failed to copy Bin/bof.o from container artifact image"
  fi
  docker rm "${cid}" >/dev/null 2>&1 || true

  check_artifact "container"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --local)
      RUN_LOCAL=1
      shift
      ;;
    --container)
      RUN_CONTAINER=1
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

if [[ "${RUN_LOCAL}" -eq 0 && "${RUN_CONTAINER}" -eq 0 ]]; then
  RUN_LOCAL=1
  RUN_CONTAINER=1
fi

if [[ "${RUN_LOCAL}" -eq 1 ]]; then
  run_local
fi

if [[ "${RUN_CONTAINER}" -eq 1 ]]; then
  run_container
fi

pass "build verification completed"
