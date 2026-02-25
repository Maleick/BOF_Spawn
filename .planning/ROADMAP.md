# Roadmap: BOF Spawn

## Overview

This roadmap hardens and operationalizes the existing BOF Spawn codebase by prioritizing safe defaults, deterministic behavior, reliability under failure, and repeatable verification. The sequence starts with operator-facing safety guardrails, then stabilizes core orchestration internals, then establishes reproducible validation, and finally locks in documentation and planning continuity.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

- [x] **Phase 1: Safety Defaults & Contract Guardrails** - Make runtime options safer and argument semantics explicit. (completed 2026-02-25)
- [x] **Phase 2: Core Reliability Hardening** - Eliminate fragile failure-path behavior in injection orchestration. (completed 2026-02-25)
- [ ] **Phase 3: Build & Contract Regression Coverage** - Add repeatable checks for artifact generation and CNA/BOF contract drift.
- [ ] **Phase 4: Execution Validation & Troubleshooting** - Standardize method-level validation and failure triage.
- [ ] **Phase 5: Documentation & Map Alignment** - Finalize operator docs and keep planning/codebase docs synchronized.

## Phase Details

### Phase 1: Safety Defaults & Contract Guardrails
**Goal**: Operator-facing defaults and toggles are explicit, safe-biased, and unambiguous.
**Depends on**: Nothing (first phase)
**Requirements**: SAFE-01, SAFE-02, SAFE-03
**Success Criteria** (what must be TRUE):
  1. Default configuration uses RW->RX behavior unless operator explicitly opts into RWX.
  2. Callback mode clearly communicates CFG-disable dependency before execution.
  3. Each dialog option maps deterministically to the BOF parser contract without hidden fallbacks.
**Plans**: 3 plans

Plans:
- [ ] 01-01: Audit and align CNA defaults/messages with safe execution posture.
- [ ] 01-02: Add explicit callback/CFG guardrails and validation messaging.
- [ ] 01-03: Validate and document CNA packing contract to BOF parser fields.

### Phase 2: Core Reliability Hardening
**Goal**: Injection orchestration behaves predictably and cleans up correctly across success and failure paths.
**Depends on**: Phase 1
**Requirements**: RELI-01, RELI-02, RELI-03
**Success Criteria** (what must be TRUE):
  1. Repeated failed runs do not leak process/thread/heap resources.
  2. PPID spoof target selection is exact-match and fails closed on invalid input.
  3. Invalid execution-method preconditions fail early with actionable diagnostics.
**Plans**: 3 plans

Plans:
- [ ] 02-01: Refactor cleanup flow to centralized resource finalization.
- [ ] 02-02: Replace permissive PPID matching with deterministic executable matching.
- [ ] 02-03: Add precondition checks for execution mode prerequisites.

### Phase 3: Build & Contract Regression Coverage
**Goal**: Maintainers can quickly detect build breakage or interface drift before runtime testing.
**Depends on**: Phase 2
**Requirements**: TEST-01, TEST-02
**Success Criteria** (what must be TRUE):
  1. Maintainers can run documented checks that confirm `Bin/bof.o` generation on supported build paths.
  2. Contract drift between `bof_pack` and BOF argument parsing is detectable through a repeatable regression check.
  3. Validation output is straightforward enough for rapid triage.
**Plans**: 2 plans

Plans:
- [ ] 03-01: Define and codify local/container build verification commands.
- [ ] 03-02: Add contract-regression check workflow for packed argument schema.

### Phase 4: Execution Validation & Troubleshooting
**Goal**: Each execution method has clear validation scenarios and failure interpretation guidance.
**Depends on**: Phase 3
**Requirements**: TEST-03, DOCS-02
**Success Criteria** (what must be TRUE):
  1. Operators have method-specific manual validation steps with expected success/failure signals.
  2. Common NTSTATUS failure classes map to likely causes and immediate next actions.
  3. Maintainers can isolate method-specific regressions without guesswork.
**Plans**: 2 plans

Plans:
- [ ] 04-01: Define per-method manual validation matrix and expected outputs.
- [ ] 04-02: Build troubleshooting guidance for dominant failure classes.

### Phase 5: Documentation & Map Alignment
**Goal**: Operator docs and planning/codebase intelligence remain accurate and aligned after hardening work.
**Depends on**: Phase 4
**Requirements**: DOCS-01, DOCS-03
**Success Criteria** (what must be TRUE):
  1. README clearly states safe defaults and trade-offs for each execution mode.
  2. `.planning/codebase/` docs reflect actual post-hardening behavior.
  3. Project planning artifacts are consistent and ready for phase planning/execution workflows.
**Plans**: 2 plans

Plans:
- [ ] 05-01: Update README operational guidance and risk trade-off sections.
- [ ] 05-02: Refresh codebase mapping docs and close planning consistency gaps.

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Safety Defaults & Contract Guardrails | 3/3 | Complete    | 2026-02-25 |
| 2. Core Reliability Hardening | 3/3 | Complete    | 2026-02-25 |
| 3. Build & Contract Regression Coverage | 0/2 | Not started | - |
| 4. Execution Validation & Troubleshooting | 0/2 | Not started | - |
| 5. Documentation & Map Alignment | 0/2 | Not started | - |
