# Phase 5: Documentation & Map Alignment - Context

**Gathered:** 2026-02-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Finalize operator-facing documentation and planning/codebase intelligence so they accurately reflect the hardened behavior delivered in Phases 1-4. Scope is limited to documentation and planning artifact alignment for existing behavior; no new runtime capabilities are introduced.

</domain>

<decisions>
## Implementation Decisions

### README Safe Defaults and Trade-off Contract
- README must explicitly document the recommended safe-default posture:
  - RW -> RX is the default memory posture.
  - RWX is manual opt-in only.
  - Callback execution is disabled by default unless CFG-disable is intentionally enabled.
- README must provide per-method operator guidance for:
  - Hijack RIP Direct
  - Hijack RIP Jmp Rax
  - Hijack RIP Jmp Rbx
  - Hijack RIP Callback
- For each method, README guidance must include:
  - primary detection trade-off
  - prerequisites and hard gates
  - recommended usage posture (default/preferred vs exception path)

### Documentation Style and Entrypoint Rules
- Output style remains action-first and concise.
- README remains the canonical first-stop operator entrypoint.
- Deep detail may live in dedicated docs, but README must include sufficient standalone guidance to satisfy `DOCS-01` without requiring source dives.
- Terms for methods, toggles, and failure signals must match actual runtime contract names already used in code and existing docs.

### Codebase Map Alignment Contract
- `.planning/codebase/` documents must be refreshed to reflect current post-hardening truth, including:
  - safety defaults and callback gate behavior
  - cleanup/failure-path hardening state
  - deterministic parent-process matching behavior
  - testing/regression scripts and validation workflows added in Phases 3-4
- Any previously true-but-now-resolved concerns should be rewritten as current-state notes (or historical context), not left as active defects.

### Planning Artifact Consistency Contract
- Planning documents must be coherent after Phase 5 execution:
  - `ROADMAP.md` progress rows and phase summaries align with on-disk plans/summaries.
  - `REQUIREMENTS.md` traceability and status mapping remain consistent with roadmap.
  - `STATE.md` counters and current-focus fields remain consistent with roadmap totals.
- If alignment defects are found during Phase 5, the phase should include explicit correction tasks (documentation/tracking only).

### Claude's Discretion
- Exact section names, table layouts, and callout formatting.
- Whether method guidance appears as compact tables, bullet matrices, or both, provided clarity is preserved.
- Exact distribution of detail between README and supporting docs as long as README still satisfies `DOCS-01`.

</decisions>

<specifics>
## Specific Ideas

- Add a compact "Safe Defaults at a Glance" section near README operator workflow.
- Use one normalized method guidance structure for all four methods to reduce ambiguity.
- Add an explicit "source-of-truth alignment pass" checklist for `.planning/codebase/` docs.

</specifics>

<deferred>
## Deferred Ideas

- Automating doc/map drift detection in CI is deferred to a future phase.
- Broader documentation redesign (branding/layout overhaul) is out of scope for this phase.

</deferred>

---

*Phase: 05-documentation-map-alignment*
*Context gathered: 2026-02-25*
