# BOF Spawn

## What This Is

BOF Spawn is a Cobalt Strike Beacon Object File project for spawning Windows x64 processes and executing payloads through configurable injection methods. It combines process creation, memory injection, and execution-path controls with Draugr-based indirect syscalls and synthetic stack spoofing. The v1.0 milestone shipped safety hardening, reliability fixes, and repeatable validation tooling while preserving the existing BOF runtime model.

## Core Value

Operators can reliably launch and execute payloads in x64 target processes from Beacon with explicit, understandable trade-offs between stealth, compatibility, and safety.

## Requirements

### Validated (v1.0 shipped 2026-02-26)

- ✓ SAFE-01: Strict-safe default profile uses RW->RX posture with no default RWX behavior.
- ✓ SAFE-02: Callback execution is hard-gated by CFG-disable requirements.
- ✓ SAFE-03: CNA packing and BOF parser mapping are deterministic and documented.
- ✓ RELI-01: Cleanup/finalization paths release owned resources deterministically.
- ✓ RELI-02: Parent-process selection is exact-match and fail-closed.
- ✓ RELI-03: Execution preconditions are validated before context tampering.
- ✓ TEST-01: Build verification is repeatable for both local and container flows.
- ✓ TEST-02: Parser-aware contract-regression checks detect `bof_pack` drift.
- ✓ TEST-03: Method-level execution validation matrix is documented.
- ✓ DOCS-01: README documents safe defaults and execution trade-offs.
- ✓ DOCS-02: NTSTATUS troubleshooting guidance is documented and linked.
- ✓ DOCS-03: `.planning/codebase/` maps and planning docs match implemented behavior.

### Active (next milestone candidates)

- [ ] Add automated Windows integration harness for method-level execution smoke tests.
- [ ] Add CI automation for `scripts/check_bof_build.sh` and `scripts/check_pack_contract.sh`.
- [ ] Expand troubleshooting runbooks with field-validated examples and rollback playbooks.

### Out of Scope

- x86 architecture support — current implementation and assembly path are x64-specific
- Kernel-mode components/drivers — project scope remains userland BOF only
- Migration away from Cobalt Strike BOF execution model — current value depends on Beacon inline execution

## Current State

- Milestone v1.0 is shipped and archived (5 phases, 12 plans, 36 tasks).
- Runtime defaults are strict-safe with explicit risky toggle opt-in and concise operator feedback.
- Reliability hardening established deterministic cleanup, PPID matching, and execution precondition gating.
- Regression tooling and docs now provide script-first build/contract checks plus operator validation and troubleshooting paths.

## Next Milestone Goals

1. Define v1.1 scope and requirements with `$gsd-new-milestone`.
2. Increase automation depth for runtime verification and regression detection.
3. Keep operator docs and planning traceability synchronized as new features land.

## Context

The repository contains production BOF source in `Src/`, Aggressor integration in `BOF_spawn.cna`, build outputs in `Bin/`, and script-based verification in `scripts/`. The `.planning/codebase/` map and phase artifacts now reflect post-hardening runtime behavior and document validation/troubleshooting workflows for operators and maintainers.

## Constraints

- **Tech Stack**: C + x64 assembly + CNA on Windows-native API surface — required by BOF runtime model
- **Compatibility**: x64-only target processes and Beacon sessions — assembly/register logic assumes 64-bit context
- **Operational Safety**: Must preserve explicit control over risky toggles (RWX, CFG disable, mitigation policy) — avoid implicit unsafe behavior
- **Workflow**: Planning artifacts must be committed in-repo under `.planning/` — maintain continuity and traceability

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Treat this initialization as brownfield continuation | Existing BOF capabilities are already implemented and mapped in `.planning/codebase/` | ✓ Good |
| Prioritize reliability/safety hardening before adding new injection features | Existing functionality is broad; stability and operator clarity were higher leverage | ✓ Good |
| Keep Cobalt Strike + BOF architecture as baseline | Current code, docs, and usage are all centered on this integration path | ✓ Good |
| Use script-first validation and parser-aware contract checks | Repeatable pre-runtime detection reduces drift and manual troubleshooting time | ✓ Good |

---
*Last updated: 2026-02-26 after v1.0 milestone completion*
