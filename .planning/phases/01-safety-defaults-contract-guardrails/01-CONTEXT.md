# Phase 1: Safety Defaults & Contract Guardrails - Context

**Gathered:** 2026-02-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Clarify implementation of existing operator safety defaults and execution guardrails for current BOF Spawn capabilities. This phase defines how defaults, warnings, and precondition checks behave; it does not introduce new capabilities.

</domain>

<decisions>
## Implementation Decisions

### Default Safety Posture
- Use a strict-safe default profile.
- RWX is never the default; it is manual opt-in only.
- Callback execution is disabled by default.
- Defaults are session-persistent within the current Cobalt Strike script/session.

### Operator Feedback Style
- Default output is action-first and concise.
- Risk warnings are shown before execution only.
- Failure output is one-line cause plus next step.
- Deeper diagnostics are exposed through explicit on-demand debug mode.

### Callback Gate Policy
- If callback execution is selected while CFG disable is off, execution is hard-blocked.
- Block message includes clear remediation: enable CFG-disable explicitly, then retry.

### Claude's Discretion
- Exact wording of warning/error messages.
- Exact debug toggle naming and activation mechanism.
- Cosmetic output formatting (symbols/layout) as long as concise, action-first behavior is preserved.

</decisions>

<specifics>
## Specific Ideas

- Keep operator output low-noise by default.
- Prefer fix-oriented guidance over technical dumps in default mode.

</specifics>

<deferred>
## Deferred Ideas

None - discussion stayed within phase scope.

</deferred>

---

*Phase: 01-safety-defaults-contract-guardrails*
*Context gathered: 2026-02-25*
