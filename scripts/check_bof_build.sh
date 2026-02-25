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
STRICT_MODE=0

print_usage() {
  cat <<'EOF'
Usage: bash scripts/check_bof_build.sh [--local] [--container] [--strict]

Checks:
  --local      Run local build check only.
  --container  Run Dockerized build check only.
  --strict     Enforce artifact freshness checks using file mtime.

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
  printf '[FAIL] %s | next step: %s\n' "$1" "$2" >&2
  exit 1
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "missing required command '$1'" "install '$1' and retry the requested build mode"
  fi
}

cleanup_artifact() {
  rm -f "${ARTIFACT}"
  find "${REPO_ROOT}/Bin/temp" -maxdepth 1 -type f ! -name '.gitkeep' -delete
}

artifact_size() {
  if stat -f "%z" "$1" >/dev/null 2>&1; then
    stat -f "%z" "$1"
  else
    stat -c "%s" "$1"
  fi
}

artifact_mtime() {
  if stat -f "%m" "$1" >/dev/null 2>&1; then
    stat -f "%m" "$1"
  else
    stat -c "%Y" "$1"
  fi
}

check_artifact() {
  if [[ ! -f "${ARTIFACT}" ]]; then
    fail "Bin/bof.o missing after ${1} build" "inspect ${1} build logs and resolve compile/link failures"
  fi

  local size
  size="$(artifact_size "${ARTIFACT}")"
  if [[ "${size}" -le 0 ]]; then
    fail "Bin/bof.o is empty after ${1} build" "inspect ${1} build logs and ensure object generation completed"
  fi

  local mtime
  mtime="$(artifact_mtime "${ARTIFACT}")"
  if [[ "${STRICT_MODE}" -eq 1 ]]; then
    if [[ "${mtime}" -lt "${2}" ]]; then
      fail "Bin/bof.o mtime (${mtime}) predates ${1} build start (${2})" "remove stale artifacts and rerun in strict mode"
    fi

    if [[ "${3}" -gt 0 && "${mtime}" -le "${3}" ]]; then
      fail "Bin/bof.o mtime (${mtime}) did not advance after ${1} build" "force a clean rebuild and confirm timestamps update"
    fi
  fi

  pass "${1} build produced Bin/bof.o (${size} bytes, mtime ${mtime})"
}

run_local() {
  info "running local build verification"
  require_command make
  require_command nasm
  require_command x86_64-w64-mingw32-gcc

  local prior_mtime=0
  if [[ -f "${ARTIFACT}" ]]; then
    prior_mtime="$(artifact_mtime "${ARTIFACT}")"
  fi

  local build_started
  build_started="$(date +%s)"
  cleanup_artifact

  if ! (cd "${REPO_ROOT}" && make spawn_bof >"${LOCAL_LOG}" 2>&1); then
    tail -n 20 "${LOCAL_LOG}" >&2 || true
    fail "local build failed" "run 'make spawn_bof' manually to inspect compiler/linker output"
  fi

  check_artifact "local" "${build_started}" "${prior_mtime}"
}

run_container() {
  info "running container build verification"
  require_command docker

  if ! docker info >/dev/null 2>&1; then
    fail "docker daemon unavailable" "start Docker and verify 'docker info' succeeds"
  fi

  local prior_mtime=0
  if [[ -f "${ARTIFACT}" ]]; then
    prior_mtime="$(artifact_mtime "${ARTIFACT}")"
  fi

  local build_started
  build_started="$(date +%s)"
  cleanup_artifact

  if ! (cd "${REPO_ROOT}" && docker build --platform linux/amd64 -t "${DOCKER_IMAGE_TAG}" -f Dockerfile . >"${CONTAINER_BASE_BUILD_LOG}" 2>&1); then
    tail -n 20 "${CONTAINER_BASE_BUILD_LOG}" >&2 || true
    fail "docker build failed" "fix Dockerfile/toolchain image build issues and retry"
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
    fail "container artifact build failed" "resolve containerized make errors and retry"
  fi

  local cid
  cid="$(docker create --platform linux/amd64 "${DOCKER_ARTIFACT_IMAGE_TAG}")"
  if ! docker cp "${cid}:/work/Bin/bof.o" "${ARTIFACT}" >"${CONTAINER_COPY_LOG}" 2>&1; then
    tail -n 20 "${CONTAINER_COPY_LOG}" >&2 || true
    docker rm "${cid}" >/dev/null 2>&1 || true
    fail "failed to copy Bin/bof.o from container artifact image" "inspect container image output and verify Bin/bof.o exists"
  fi
  docker rm "${cid}" >/dev/null 2>&1 || true

  check_artifact "container" "${build_started}" "${prior_mtime}"
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
    --strict)
      STRICT_MODE=1
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1" "run with --help to see supported options"
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
