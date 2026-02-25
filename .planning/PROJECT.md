# BOF Spawn

## What This Is

BOF Spawn is a Cobalt Strike Beacon Object File project for spawning Windows x64 processes and executing payloads through configurable injection methods. It combines process creation, memory injection, and execution-path controls with Draugr-based indirect syscalls and synthetic stack spoofing. This project is for operators and maintainers who need a reliable, auditable BOF workflow for controlled post-exploitation experimentation.

## Core Value

Operators can reliably launch and execute payloads in x64 target processes from Beacon with explicit, understandable trade-offs between stealth, compatibility, and safety.

## Requirements

### Validated

- ✓ Spawn x64 target processes via native process creation path in `Src/Bof.c` — existing
- ✓ Inject shellcode and execute via multiple methods (direct RIP, JMP RAX/RBX, callback) — existing
- ✓ Configure runtime behavior through `BOF_spawn.cna` dialog and aliases — existing
- ✓ Build `Bin/bof.o` with MinGW/NASM toolchain via `Makefile` and optional `Dockerfile` — existing
- ✓ Resolve and invoke key NT APIs through Draugr syscall/call-spoof abstractions — existing

### Active

- [ ] Harden failure-path reliability and cleanup across process/memory/thread operations
- [ ] Strengthen operator safety defaults and explicit risk signaling
- [ ] Add repeatable verification coverage for build and execution contract behavior
- [ ] Improve operational docs and troubleshooting depth for maintainers/operators

### Out of Scope

- x86 architecture support — current implementation and assembly path are x64-specific
- Kernel-mode components/drivers — project scope remains userland BOF only
- Migration away from Cobalt Strike BOF execution model — current value depends on Beacon inline execution

## Context

The repository already contains production-oriented BOF source in `Src/`, Aggressor integration in `BOF_spawn.cna`, and build artifacts pathing in `Bin/`. A codebase map was generated in `.planning/codebase/` and identifies high-value hardening work: cleanup consistency, deterministic process matching, and improved validation coverage. The current workflow branch already includes planning docs infrastructure and is ready to begin phased execution planning.

## Constraints

- **Tech Stack**: C + x64 assembly + CNA on Windows-native API surface — required by BOF runtime model
- **Compatibility**: x64-only target processes and Beacon sessions — assembly/register logic assumes 64-bit context
- **Operational Safety**: Must preserve explicit control over risky toggles (RWX, CFG disable, mitigation policy) — avoid implicit unsafe behavior
- **Workflow**: Planning artifacts must be committed in-repo under `.planning/` — maintain continuity and traceability

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Treat this initialization as brownfield continuation | Existing BOF capabilities are already implemented and mapped in `.planning/codebase/` | ✓ Good |
| Prioritize reliability/safety hardening before adding new injection features | Existing functionality is broad; stability and operator clarity are higher leverage now | — Pending |
| Keep Cobalt Strike + BOF architecture as baseline | Current code, docs, and usage are all centered on this integration path | ✓ Good |

---
*Last updated: 2026-02-25 after initialization*
