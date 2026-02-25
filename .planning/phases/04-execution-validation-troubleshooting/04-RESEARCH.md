# Phase 4: Execution Validation & Troubleshooting - Research

**Researched:** 2026-02-25T22:05:00Z
**Domain:** Method-level operator validation and NTSTATUS troubleshooting guidance
**Confidence:** HIGH

<user_constraints>
## User Constraints

### Locked Decisions (from 04-CONTEXT.md)
- Use discuss-first decisions as authoritative input.
- Produce a method-by-method validation matrix for all four execution methods.
- Map dominant NTSTATUS failure classes to likely causes and immediate next actions.
- Keep documentation output action-first and concise.
- Scope remains fixed to validation and troubleshooting guidance (no new runtime capability).

### Deferred / Out of Scope
- Automated runtime harness or expanded integration testing framework.
- New injection methods or runtime behavior changes.
</user_constraints>

<research_summary>
## Summary

Phase 4 can be delivered cleanly with documentation-focused artifacts grounded in existing runtime behavior:

1. A deterministic validation matrix for the four execution modes (`Direct`, `JMP RAX`, `JMP RBX`, `Callback`) sourced from current config and execution flow.
2. A troubleshooting map for dominant failure classes already surfaced in `Src/Bof.c` and `BOF_spawn.cna`, including one-line "cause -> next step" operator guidance.

The codebase already exposes stable anchors needed for this phase:
- Execution methods and precondition gate: `ValidateExecutionPreconditions(...)` in `Src/Bof.c`
- Method dispatch and stage-level failures: `SpawnAndRun(...)` switch + syscall error prints
- Operator-side preflight constraints: `preflight_validate_execution` in `BOF_spawn.cna`

No runtime changes are required to satisfy phase intent; this phase should formalize and operationalize existing behavior in maintainable docs.
</research_summary>

<evidence_inventory>
## Evidence Inventory

### Execution methods and constraints
- `Src/Bof.c` EXECUTION enum defines:
  - `HIJACK_RIP_DIRECT`
  - `HIJACK_RIP_JMP_RAX`
  - `HIJACK_RIP_JMP_RBX`
  - `HIJACK_RIP_CALLBACK_FUNCTION`
- `ValidateExecutionPreconditions` hard-blocks:
  - invalid method values (`STATUS_INVALID_PARAMETER`)
  - callback mode when CFG-disable is off (`STATUS_INVALID_PARAMETER`)

### Dominant failure classes observable now
- Parent process resolution failure: `STATUS_INVALID_PARAMETER_2`
- Gadget lookup failures (`JMP RAX` / `JMP RBX`): `STATUS_DATA_ERROR`
- Callback function lookup failure (`EnumResourceTypesW`): `STATUS_PROCEDURE_NOT_FOUND`
- Allocation/list construction resource failure: `STATUS_INSUFFICIENT_RESOURCES`
- Pass-through syscall failures at stage boundaries:
  - process creation (`NtCreateUserProcess`)
  - memory allocation/write/protect
  - thread context get/set
  - process resume

### Operator-facing error style already established
- BOF and CNA preflight messages are already concise and fix-oriented:
  - "invalid execution method ... | next step: ..."
  - "callback blocked ... | next step: ..."
- This style matches phase requirement for fast triage and should be preserved in docs.
</evidence_inventory>

<recommended_artifacts>
## Recommended Artifacts for Planning

### 1) Validation Matrix Document (TEST-03)
- Add a dedicated doc for method-level manual validation matrix (recommended path: `docs/execution-validation-matrix.md`).
- Include per-method rows:
  - prerequisites
  - operator command path
  - expected success signal
  - expected failure signal
  - quick triage hint
- Keep a concise entry section in README linking to the full matrix.

### 2) Troubleshooting Guide (DOCS-02)
- Add a dedicated troubleshooting doc (recommended path: `docs/ntstatus-troubleshooting.md`) with:
  - NTSTATUS/failure class
  - likely cause
  - immediate next action
  - stage/location hint
- Add a compact troubleshooting section in README for rapid lookup, with link to full guidance.

### 3) Cross-link contract
- README should remain the top-level operator entrypoint.
- Detailed docs should hold matrix depth and failure taxonomy depth.
- All commands and terms must match current source behavior exactly.
</recommended_artifacts>

<planning_guidance>
## Planning Guidance

### Plan shape (locked)
- `04-01-PLAN.md` (Wave 1, `TEST-03`):
  - build method validation matrix + README entrypoint
- `04-02-PLAN.md` (Wave 2, `DOCS-02`, depends on `04-01`):
  - build NTSTATUS troubleshooting guide + README quick triage mapping

### Must-have verification signals
- `TEST-03`: every execution method has documented manual validation scenario and expected success/failure indicators.
- `DOCS-02`: README contains troubleshooting guidance for dominant failure classes, not only external doc links.

### Quality constraints for tasks
- Each task should have automated verification commands (`rg`-based assertions acceptable for docs phase).
- Requirements mapping must be explicit in each plan frontmatter.
- `must_haves` should include artifacts + key links from README to detailed docs.
</planning_guidance>

<pitfalls>
## Common Pitfalls

1. **Over-generic troubleshooting**
- Risk: generic "check logs" advice that does not map to actual BOF stages or codes.
- Avoid: tie each row to concrete failure surfaces seen in source.

2. **Drift between README and deep docs**
- Risk: README commands/terms diverge from detailed docs.
- Avoid: enforce explicit cross-links and identical method naming.

3. **Scope creep into runtime changes**
- Risk: phase expands into code changes for new diagnostics/features.
- Avoid: keep this phase documentation-and-validation-guidance only.
</pitfalls>

<sources>
## Sources

### Primary
- `Src/Bof.c`
- `BOF_spawn.cna`
- `README.md`
- `.planning/phases/04-execution-validation-troubleshooting/04-CONTEXT.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`

### Confidence rationale
- Direct code-level evidence exists for execution methods, gates, and dominant failure classes.
- Existing operator-message style is already aligned with the desired troubleshooting format.
</sources>

---

*Phase: 04-execution-validation-troubleshooting*
*Research completed: 2026-02-25T22:05:00Z*
*Ready for planning: yes*
