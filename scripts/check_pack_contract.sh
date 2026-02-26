#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

HAS_CNA=0
HAS_BOF=0

for arg in "$@"; do
  case "$arg" in
    --cna|--cna=*)
      HAS_CNA=1
      ;;
    --bof|--bof=*)
      HAS_BOF=1
      ;;
  esac
done

CMD=(python3 "${SCRIPT_DIR}/check_pack_contract.py")
if [[ "${HAS_CNA}" -eq 0 ]]; then
  CMD+=(--cna "${REPO_ROOT}/BOF_spawn.cna")
fi
if [[ "${HAS_BOF}" -eq 0 ]]; then
  CMD+=(--bof "${REPO_ROOT}/Src/Bof.c")
fi
CMD+=("$@")

"${CMD[@]}"
