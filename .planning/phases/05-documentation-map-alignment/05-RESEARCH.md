# Phase 5: Documentation & Map Alignment - Research

**Researched:** 2026-02-25T22:45:00Z
**Domain:** Operator documentation alignment and planning/codebase truth synchronization
**Confidence:** HIGH

<user_constraints>
## User Constraints

### Locked Decisions (from 05-CONTEXT.md)
- Phase remains documentation/planning alignment only; no runtime capability expansion.
- README must clearly document strict-safe defaults and per-method detection trade-offs.
- Guidance must cover all execution methods with prerequisites, hard gates, and recommended usage posture.
- `.planning/codebase/` docs must align with implemented post-hardening behavior from Phases 1-4.
- Planning artifacts (`ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`) must remain internally consistent.

### Deferred / Out of Scope
- CI automation for documentation drift detection.
- Broad documentation redesign unrelated to Phase 5 requirements.
</user_constraints>

<research_summary>
## Summary

Phase 5 should be delivered as a docs-and-planning consistency pass with two tightly scoped outputs:

1. README operator guidance refresh for `DOCS-01`:
   - convert existing scattered method/risk text into explicit "recommended default vs opt-in exception" guidance for each execution method.
   - anchor guidance to strict-safe defaults already enforced in `BOF_spawn.cna` and runtime guardrails in `Src/Bof.c`.

2. Codebase-map and planning-consistency refresh for `DOCS-03`:
   - update `.planning/codebase/*.md` where statements are stale after Phases 1-4 hardening.
   - close any planning metadata drift in roadmap/requirements/state so docs are execution-ready and trustworthy.

Current repo evidence shows partial compliance already exists, but key alignment gaps remain:
- README contains method descriptions and detection-risk notes, but not a normalized per-method recommended posture contract.
- `.planning/codebase/` still reports resolved defects as active concerns (for example cleanup and PPID matching issues that were addressed in Phase 2).
- testing/mapping docs still understate existing regression/validation scripts added in Phases 3-4.
</research_summary>

<evidence_inventory>
## Evidence Inventory

### Safe defaults and runtime guardrails are already implemented
- `BOF_spawn.cna` default profile:
  - `use_rwx = false` (manual RWX opt-in)
  - default exec method is `Hijack RIP Direct`
  - callback precondition gate in CNA preflight (`callback blocked (cfg-disable is off)`).
- `Src/Bof.c` runtime fail-closed precondition checks:
  - invalid execution method blocked (`STATUS_INVALID_PARAMETER`)
  - callback with CFG-disable off blocked (`STATUS_INVALID_PARAMETER`)

### README has foundational content but lacks explicit per-method recommended posture
- README includes method-by-method "Advantage" and "Detection Risk" and mitigation policy sections.
- README currently does not provide one normalized section that maps each method to:
  - recommended/default usage posture
  - prerequisites/hard gates
  - concise detection trade-off summary

### `.planning/codebase/` contains stale post-hardening claims
- `CONCERNS.md` still lists unresolved cleanup and PPID substring-matching issues as active risks.
- `INTEGRATIONS.md` still references `StrStrW` behavior that no longer reflects current exact-match implementation.
- `CONVENTIONS.md` still describes early-return cleanup leaks as current behavior.
- `TESTING.md` and `STACK.md` understate existing script-based regression checks added in Phase 3 (`check_bof_build.sh`, `check_pack_contract.sh/.py`) and validation docs from Phase 4.

### Phase 5 requirement anchors
- `DOCS-01`: README must document recommended safe defaults and detection trade-offs for each execution method.
- `DOCS-03`: planning docs in `.planning/codebase/` must remain aligned with implemented behavior after roadmap phases.
</evidence_inventory>

<recommended_artifacts>
## Recommended Artifacts for Planning

### 1) README guidance refresh (`DOCS-01`)
- Update `README.md` with a dedicated operator guidance section that normalizes method recommendations:
  - method
  - default/opt-in posture
  - prerequisite gates
  - detection trade-off
  - when to choose it
- Ensure wording remains action-first and matches existing runtime contract names.

### 2) Codebase map synchronization (`DOCS-03`)
- Update `.planning/codebase/` docs to remove stale resolved-risk language and reflect current hardening state:
  - `ARCHITECTURE.md`
  - `CONCERNS.md`
  - `CONVENTIONS.md`
  - `INTEGRATIONS.md`
  - `STACK.md`
  - `TESTING.md`
- Keep updates factual and traceable to current files/behaviors.

### 3) Planning artifact consistency pass (`DOCS-03`)
- Validate and correct cross-file planning metadata coherence:
  - roadmap progress rows vs on-disk plan/summary counts
  - requirements traceability statuses
  - state counters/current-focus consistency
</recommended_artifacts>

<planning_guidance>
## Planning Guidance

### Plan shape (locked)
- `05-01-PLAN.md` (Wave 1, `DOCS-01`):
  - README safe-default and per-method trade-off alignment.
- `05-02-PLAN.md` (Wave 2, `DOCS-03`, depends on `05-01`):
  - `.planning/codebase/` refresh and planning-artifact consistency corrections.

### Must-have verification signals
- `DOCS-01`: README explicitly communicates recommended safe defaults and method-by-method trade-offs with clear operator posture.
- `DOCS-03`: `.planning/codebase/` statements match current implemented behavior; no known resolved issues remain documented as active defects.
- Planning metadata remains coherent across roadmap, requirements, and state after Phase 5 work.

### Task quality constraints
- Every task should include concrete target files and automated `rg`/validation commands.
- Requirement mapping must be explicit in plan frontmatter.
- `must_haves` should include artifact/key-link checks that prove README guidance aligns with supporting docs and planning metadata.
</planning_guidance>

<pitfalls>
## Common Pitfalls

1. **Superficial README edits**
- Risk: adding prose without a clear per-method recommendation contract.
- Avoid: require normalized guidance elements per method.

2. **Partial codebase-map refresh**
- Risk: one or two docs updated while stale claims remain elsewhere.
- Avoid: perform an explicit file-by-file alignment pass across `.planning/codebase/*.md`.

3. **Metadata drift after doc updates**
- Risk: roadmap/requirements/state counters or status text diverge.
- Avoid: include explicit consistency checks and corrective tasks in `05-02`.
</pitfalls>

<sources>
## Sources

### Primary
- `BOF_spawn.cna`
- `Src/Bof.c`
- `README.md`
- `.planning/codebase/ARCHITECTURE.md`
- `.planning/codebase/CONCERNS.md`
- `.planning/codebase/CONVENTIONS.md`
- `.planning/codebase/INTEGRATIONS.md`
- `.planning/codebase/STACK.md`
- `.planning/codebase/TESTING.md`
- `.planning/phases/05-documentation-map-alignment/05-CONTEXT.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`

### Confidence rationale
- Evidence directly confirms implemented defaults/guardrails and documents where planning/codebase text is stale relative to current code and prior phase outcomes.
</sources>

---

*Phase: 05-documentation-map-alignment*
*Research completed: 2026-02-25T22:45:00Z*
*Ready for planning: yes*
