# Requirements: BOF Spawn

**Defined:** 2026-02-25
**Core Value:** Operators can reliably launch and execute payloads in x64 target processes from Beacon with explicit, understandable trade-offs between stealth, compatibility, and safety.

## v1 Requirements

### Reliability

- [x] **RELI-01**: BOF cleans up opened handles and allocated resources before returning from any failure path.
- [x] **RELI-02**: Parent process selection uses exact case-insensitive executable-name matching and fails closed when no exact match exists.
- [x] **RELI-03**: Execution-method preconditions are validated before thread-context modification and return actionable errors on invalid combinations.

### Safety Controls

- [x] **SAFE-01**: Default operator profile uses RW->RX memory transition rather than RWX allocation.
- [x] **SAFE-02**: Callback execution mode is explicitly gated by CFG-disable requirement with visible operator warning.
- [x] **SAFE-03**: CNA-to-BOF argument mapping remains deterministic and documented for all toggles and execution methods.

### Testing & Verification

- [x] **TEST-01**: Build verification commands reliably produce `Bin/bof.o` for local and containerized workflows.
- [ ] **TEST-02**: Packing/parsing contract between `BOF_spawn.cna` and `Src/Bof.c::go()` is covered by repeatable regression checks.
- [ ] **TEST-03**: Every execution method has a documented manual validation scenario with expected success and failure signals.

### Documentation & Operability

- [ ] **DOCS-01**: README documents recommended safe defaults and detection trade-offs for each execution method.
- [ ] **DOCS-02**: README includes troubleshooting guidance for common NTSTATUS failure classes.
- [ ] **DOCS-03**: Planning docs in `.planning/codebase/` remain aligned with implemented behavior after roadmap phases.

## v2 Requirements

### Future Enhancements

- **ARCH-01**: Add x86 support strategy (or explicit formal deprecation policy) with compatibility matrix.
- **AUTO-01**: Add automated Windows integration harness for execution-method smoke tests.
- **EXEC-01**: Explore additional execution pathways that reduce context-tampering signatures.
- **OPS-01**: Add operator presets/profiles in CNA for common trade-off bundles.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Kernel-mode stealth modules | Outside userland BOF repository scope |
| Non-Cobalt Strike integration adapters | Current product value is Beacon-native execution |
| Full autonomous exploit chain orchestration | Not required for BOF injection hardening milestone |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SAFE-01 | Phase 1 | Complete |
| SAFE-02 | Phase 1 | Complete |
| SAFE-03 | Phase 1 | Complete |
| RELI-01 | Phase 2 | Complete |
| RELI-02 | Phase 2 | Complete |
| RELI-03 | Phase 2 | Complete |
| TEST-01 | Phase 3 | Complete |
| TEST-02 | Phase 3 | Pending |
| TEST-03 | Phase 4 | Pending |
| DOCS-02 | Phase 4 | Pending |
| DOCS-01 | Phase 5 | Pending |
| DOCS-03 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0 ✓

---
*Requirements defined: 2026-02-25*
*Last updated: 2026-02-25 after roadmap creation*
