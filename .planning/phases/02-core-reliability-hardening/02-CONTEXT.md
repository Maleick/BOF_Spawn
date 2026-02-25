# Phase 2: Core Reliability Hardening - Context

**Gathered:** 2026-02-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Harden existing injection orchestration reliability so failure paths are deterministic, resources are finalized correctly, PPID spoof matching is exact and fail-closed, and execution-mode preconditions reject invalid combinations early with actionable diagnostics. This phase does not add new execution capabilities.

</domain>

<decisions>
## Implementation Decisions

### Failure-path cleanup model (RELI-01)
- Use centralized finalization in `SpawnAndRun` for all owned resources before return.
- Every failure path must funnel through one cleanup path that releases process/thread/parent handles, attribute list heap memory, and process parameters when allocated.
- Cleanup must be null-safe and idempotent to avoid double-free/double-close behavior.
- Return the original failing `NTSTATUS` after cleanup rather than masking with cleanup-side errors.

### Parent process selection contract (RELI-02)
- PPID target selection uses exact case-insensitive executable-name matching (`explorer.exe` matches only `explorer.exe`).
- Substring and partial-name matches are forbidden.
- If no exact match exists, execution fails closed with an explicit operator-facing error and no fallback parent.
- Input normalization may strip directory components before compare, but final compare remains exact executable-name equality.

### Execution precondition gate contract (RELI-03)
- Invalid execution-method combinations are rejected before any thread-context modification attempt.
- Callback mode requires CFG-disable enabled; mismatch is a hard-block with one-line cause plus next step.
- Unsupported execution-method values fail early and do not continue to runtime branching.
- Diagnostics remain concise/action-first by default and preserve explicit next-step remediation text.

### Claude's Discretion
- Exact helper naming and cleanup-label structure inside `Src/Bof.c`.
- Exact message wording as long as it stays concise and remediation-oriented.
- Whether early validation lives in `go()`, `SpawnAndRun`, or both, as long as fail-early and fail-closed behavior is preserved.

</decisions>

<specifics>
## Specific Ideas

- Prefer one owner/one cleanup pattern for each allocated handle/pointer to reduce leak regressions.
- Keep operator diagnostics short enough for Beacon output scanning during rapid retries.

</specifics>

<deferred>
## Deferred Ideas

None - discussion remained within reliability hardening scope.

</deferred>

---

*Phase: 02-core-reliability-hardening*
*Context gathered: 2026-02-25*
