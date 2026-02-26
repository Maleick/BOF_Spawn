# Phase 2: Core Reliability Hardening - Research

**Researched:** 2026-02-25T20:16:25Z
**Domain:** Injection runtime reliability and deterministic failure handling in BOF spawn orchestration
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Use centralized finalization in `SpawnAndRun` for all owned resources before return.
- Every failure path must funnel through one cleanup path that releases process/thread/parent handles, attribute list heap memory, and process parameters when allocated.
- Cleanup must be null-safe and idempotent to avoid double-free/double-close behavior.
- Return the original failing `NTSTATUS` after cleanup rather than masking with cleanup-side errors.
- PPID target selection uses exact case-insensitive executable-name matching (`explorer.exe` matches only `explorer.exe`).
- Substring and partial-name matches are forbidden.
- If no exact match exists, execution fails closed with an explicit operator-facing error and no fallback parent.
- Input normalization may strip directory components before compare, but final compare remains exact executable-name equality.
- Invalid execution-method combinations are rejected before any thread-context modification attempt.
- Callback mode requires CFG-disable enabled; mismatch is a hard-block with one-line cause plus next step.
- Unsupported execution-method values fail early and do not continue to runtime branching.
- Diagnostics remain concise/action-first by default and preserve explicit next-step remediation text.

### Claude's Discretion
- Exact helper naming and cleanup-label structure inside `Src/Bof.c`.
- Exact message wording as long as it stays concise and remediation-oriented.
- Whether early validation lives in `go()`, `SpawnAndRun`, or both, as long as fail-early and fail-closed behavior is preserved.

### Deferred Ideas (OUT OF SCOPE)
- None - discussion remained within reliability hardening scope.
</user_constraints>

<research_summary>
## Summary

`Src/Bof.c` currently returns early from many failure points in `SpawnAndRun`, which risks leaking handles and heap allocations across repeated failures. The function already has clear ownership candidates (`hParentProcess`, `hProcess`, `hThread`, process parameters, attribute list), so the lowest-risk hardening is centralized cleanup with a single return path that preserves the original failing status.

Parent process resolution currently uses `StrStrW(lpcwProcessName, pe32.szExeFile)`, which allows permissive substring matching and violates RELI-02. Deterministic behavior requires exact case-insensitive executable-name equality after normalizing caller input to basename, then fail-closed if no match.

Execution preconditions are partly guarded today (`MemExec` range in `go()`, callback/CFG gate in `SpawnAndRun`), but checks should be consolidated into explicit precondition guards that run before any thread-context modifications.

**Primary recommendation:** introduce a centralized finalization block in `SpawnAndRun`, replace substring PPID matching with exact normalized compare, and define an explicit precondition gate path that returns concise remediation errors before execution-context mutation.
</research_summary>

<standard_stack>
## Standard Stack

### Core
| Runtime / Interface | Purpose | Why Standard |
|---------------------|---------|--------------|
| C BOF runtime (`Src/Bof.c`) | Process creation, injection, and cleanup ownership | Native location of resources and NTSTATUS control flow |
| Existing NT/Draugr syscall path | Handle lifecycle + memory operations | Already integrated with project execution model |
| Aggressor script (`BOF_spawn.cna`) | Operator-side preflight and diagnostics contract | Existing interface for actionable error reporting |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| `rg` | Trace all return sites and preconditions | During refactor verification |
| `gsd-tools verify plan-structure` | Static plan shape validation | Before finalizing plan artifacts |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Centralized cleanup label | Keep distributed early returns | Faster to write, but leak-prone and harder to audit |
| Exact executable match | Fuzzy/substring process lookup | Convenience for typos, but violates fail-closed requirement |
| Dual-layer precondition checks | Only BOF-side checks | Misses operator-facing early diagnostics consistency |
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Pattern 1: Single-exit resource finalization
Use one cleanup block for owned resources and route all failures through it with `Status` already set.

### Pattern 2: Deterministic input normalization + strict compare
Normalize PPID input once (basename extraction), then use exact case-insensitive compare only.

### Pattern 3: Validate before mutate
All execution-mode preconditions must pass before `NtGetContextThread` / `NtSetContextThread` path is entered.

### Anti-Patterns to Avoid
- Returning immediately after allocation/open without mirrored release path.
- Using substring process matching for PPID spoof target selection.
- Performing context mutation setup before execution precondition validation completes.
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Handle lifecycle tracking | Ad-hoc per-branch close/free logic | Single ownership cleanup path | Prevents omission under edge failures |
| Process name matching | Custom fuzzy matching rules | Exact case-insensitive executable compare | Deterministic and auditable behavior |
| Diagnostic structure | Multi-line dumps by default | One-line cause + next step contract | Keeps Beacon output operationally usable |

**Key insight:** reliability hardening is mostly control-flow correctness and ownership discipline, not new execution mechanics.
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Cleanup path misses one owner
- **Failure:** repeated failures leak heap/handles and destabilize subsequent runs.
- **Prevention:** maintain explicit ownership table in code comments and finalization block ordering.

### Pitfall 2: Exact-match logic accidentally reintroduces permissive behavior
- **Failure:** fallback or partial matching silently returns unintended parent process.
- **Prevention:** enforce one compare function + fail closed when no exact hit.

### Pitfall 3: Precondition checks split inconsistently across call sites
- **Failure:** one alias/call path still reaches invalid execution state.
- **Prevention:** centralize shared precondition helper and keep BOF defensive check.
</common_pitfalls>

<code_examples>
## Code Examples

### Current permissive PPID match that must be replaced
```c
if (StrStrW(lpcwProcessName, pe32.szExeFile)) {
    *pdwProcessId = pe32.th32ProcessID;
    return TRUE;
}
```

### Existing callback/CFG runtime guard (keep contract, enforce earlier)
```c
if (Execute == HIJACK_RIP_CALLBACK_FUNCTION && !DisableCfg) {
    BeaconPrintf(CALLBACK_ERROR, "[!] callback blocked (cfg-disable is off) | next step: enable CFG-disable, then retry");
    return STATUS_INVALID_PARAMETER;
}
```

### Existing MemExec early guard (anchor for RELI-03)
```c
if (MemExec < HIJACK_RIP_DIRECT || MemExec > HIJACK_RIP_CALLBACK_FUNCTION) {
    BeaconPrintf(CALLBACK_ERROR, "[!] invalid execution method (%d) | next step: select a supported execution method and retry", MemExec);
    return;
}
```
</code_examples>

<open_questions>
## Open Questions

1. **Failure after process creation but before resume**
   - Known: resource cleanup must occur.
   - Open: whether to terminate partially created target process in failure path as part of reliability policy.
   - Planning default: clean local resources in Phase 2; avoid introducing new termination semantics unless required by requirement interpretation.

2. **Input normalization boundary for PPID selector**
   - Known: exact executable-name compare is required.
   - Open: whether empty string should be treated as null/disabled PPID spoof or invalid input.
   - Planning default: treat empty/whitespace as disabled when caller omits PPID, otherwise fail closed for explicit invalid value.
</open_questions>

<sources>
## Sources

### Primary (HIGH confidence)
- `Src/Bof.c`
- `BOF_spawn.cna`
- `.planning/phases/02-core-reliability-hardening/02-CONTEXT.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
</sources>

<metadata>
## Metadata

**Research scope:** RELI-01 through RELI-03 reliability hardening decisions.

**Confidence breakdown:**
- Cleanup strategy: HIGH
- PPID matching contract: HIGH
- Precondition gating approach: HIGH

**Research date:** 2026-02-25
**Valid until:** 2026-03-27
</metadata>

---

*Phase: 02-core-reliability-hardening*
*Research refreshed: 2026-02-25T20:16:25Z*
*Ready for planning: yes*
