# Testing Patterns

**Analysis Date:** 2026-02-25

## Test Framework

**Runner:**
- No automated unit/integration/E2E test runner configured in repository
- No `tests/` directory and no `*.test.*` files found

**Assertion Library:**
- None in-repo

**Run Commands (current practical verification):**
```bash
bash scripts/check_bof_build.sh --local --container --strict  # TEST-01
bash scripts/check_pack_contract.sh                            # TEST-02
bash scripts/check_pack_contract.sh --json                     # TEST-02 machine-readable
```

**Manual validation references:**
- `docs/execution-validation-matrix.md` (`TEST-03`)
- `docs/ntstatus-troubleshooting.md` (`DOCS-02`)

## Test File Organization

**Location:**
- Automated test location not yet established
- Current validation relies on build success and operator runtime checks

**Naming:**
- No existing conventions for test filenames

**Structure:**
- Manual execution and verification through Beacon command outputs in `BOF_spawn.cna`

## Test Structure (Observed Manual Pattern)

**Compile Validation:**
1. Run `bash scripts/check_bof_build.sh --local --container --strict`.
2. Confirm both local and container checks pass with `Bin/bof.o` artifact freshness.

**Contract Validation:**
1. Run `bash scripts/check_pack_contract.sh`.
2. Confirm parser-aware schema check reports pack/parse alignment for `ZZZZiiiib`.

**Runtime Validation:**
1. Load `BOF_spawn.cna` in Cobalt Strike Script Manager.
2. Run `spawn_beacon <listener>` and/or `spawn_shellcode <path>`.
3. Follow method order and signal checks from `docs/execution-validation-matrix.md` (`TEST-03`).
4. Use `docs/ntstatus-troubleshooting.md` (`DOCS-02`) for deterministic failure triage.

## Mocking

**Framework:**
- None

**Current approach:**
- No mock layer; execution depends on real Beacon runtime and Windows API behavior

## Fixtures and Factories

**Test Data:**
- Shellcode payload bytes are runtime inputs (generated listener payloads or local raw shellcode files)
- No fixture directory or canonical sample corpus in-repo

## Coverage

**Requirements:**
- No coverage threshold or measurement tooling configured

**Current state:**
- Coverage is unknown; regressions are likely to surface only during manual runtime use

## Test Types

**Unit Tests:**
- Not present

**Integration Tests:**
- Implicit manual integration through Beacon + BOF execution

**E2E/Operational Tests:**
- Operator-driven manual verification against target process creation/injection scenarios

## Common Gaps To Address

- Missing deterministic tests for `DraugrResolveSyscall` and gadget resolution behavior in `Src/Draugr.c`
- Add CI automation around existing contract checker (`scripts/check_pack_contract.py`) to reduce manual invocation risk
- Missing regression tests for each execution mode (`direct`, `jmp rax`, `jmp rbx`, `callback`)
- Missing negative-path tests for cleanup behavior after partial failures

---

*Testing analysis: 2026-02-25*
*Update when automated tests or repeatable harnesses are introduced*
