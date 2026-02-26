# Phase 1: Safety Defaults & Contract Guardrails - Research

**Researched:** 2026-02-25T19:34:49Z
**Domain:** Operator-safe defaults and CNA-to-BOF contract guardrails
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Use a strict-safe default profile.
- RWX is never the default; it is manual opt-in only.
- Callback execution is disabled by default.
- Defaults are session-persistent within the current Cobalt Strike script/session.
- Default output is action-first and concise.
- Risk warnings are shown before execution only.
- Failure output is one-line cause plus next step.
- Deeper diagnostics are exposed through explicit on-demand debug mode.
- If callback execution is selected while CFG disable is off, execution is hard-blocked.
- Block message includes clear remediation: enable CFG-disable explicitly, then retry.

### Claude's Discretion
- Exact wording of warning/error messages.
- Exact debug toggle naming and activation mechanism.
- Cosmetic output formatting (symbols/layout) as long as concise, action-first behavior is preserved.

### Deferred Ideas (OUT OF SCOPE)
- None - discussion stayed within phase scope.
</user_constraints>

<research_summary>
## Summary

Phase 1 remains a contract-hardening phase over existing BOF Spawn behavior. Current code paths in `BOF_spawn.cna` and `Src/Bof.c` already support most primitives but still leave unsafe ambiguity at the operator layer: callback remains default while callback preconditions are only documented, and execution-method mapping logic remains duplicated across aliases.

The safest and most maintainable implementation path is to make CNA preflight logic authoritative for defaults, warnings, and mapping normalization, then enforce callback/CFG invariant again in BOF as a defensive fail-closed runtime check. This directly satisfies SAFE-01 and SAFE-02 while reducing hidden state drift risk for SAFE-03.

**Primary recommendation:** centralize default profile + method mapping + preflight gating in CNA, mirror critical callback precondition in BOF, and keep pack/parse mapping documented in both source comments and README.
</research_summary>

<standard_stack>
## Standard Stack

### Core
| Runtime / Interface | Purpose | Why Standard |
|---------------------|---------|--------------|
| Aggressor Script (Sleep) | Operator defaults, dialog UX, preflight gates, packing | Native operator control plane for Beacon workflows |
| Beacon BOF parser functions (`BeaconDataParse`, `BeaconDataExtract`, `BeaconDataInt`) | Decode packed args in BOF | Canonical contract surface with Cobalt Strike |
| Existing BOF internals (`Nt*`, Draugr/VxTable) | Process creation and execution internals | Existing subsystem; no phase scope to replace this stack |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| `rg` | Static contract and message checks | Plan verification / regression spotting |
| README contract table | Human-visible mapping documentation | Any mapping/type/order change |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| CNA + BOF dual guardrail | BOF-only validation | Misses pre-execution operator feedback contract |
| Explicit resolver + hard failure | Implicit default-to-0 fallback | Fallback hides mapping drift and violates SAFE-03 |
| Shared helper for both aliases | Duplicate branch logic | Drift risk between `spawn_beacon` and `spawn_shellcode` |
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Pattern 1: Single-source default profile
Default toggles are defined once and consumed uniformly by both alias command paths.

### Pattern 2: Preflight-first operator guardrails
Invalid callback/CFG combinations are blocked before BOF dispatch with concise remediation text.

### Pattern 3: Contract lockstep
`bof_pack("ZZZZiiiib", ...)` order/type is treated as strict ABI with mirrored parser ordering in `go()`.

### Anti-Patterns to Avoid
- Duplicated string-to-exec mapping per alias.
- Silent fallback for unknown execution method.
- Callback precondition only as docs text (not enforced).
- Verbose default-mode output that hides next action.
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| BOF argument parser | Custom parser protocol | Existing Beacon parser functions | Keeps runtime compatibility |
| Alias-specific method mapping | Separate if/else mapping blocks | Shared mapping helper | Prevents drift and hidden divergence |
| Runtime-only precondition checking | No CNA preflight | CNA preflight + BOF defensive guard | Meets UX contract and fail-closed policy |

**Key insight:** this phase is interface determinism work, not execution-capability expansion.
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Callback remains default
- **Failure:** unsafe-by-default operator start state.
- **Prevention:** make direct RIP default, keep callback explicit opt-in.

### Pitfall 2: Mapping drift between aliases
- **Failure:** same selected option yields different packed integer values.
- **Prevention:** unify resolver + packing path.

### Pitfall 3: Pack/parse drift over time
- **Failure:** CNA order/type changes without parser alignment.
- **Prevention:** comment-level + README mapping table in lockstep.
</common_pitfalls>

<code_examples>
## Code Examples

### Parser-order anchor (`Src/Bof.c`)
```c
BlockDllPolicy  = BeaconDataInt(&parser);
DisableCfg      = BeaconDataInt(&parser);
UseRWX          = BeaconDataInt(&parser);
MemExec         = BeaconDataInt(&parser);
```

### Packing-order anchor (`BOF_spawn.cna`)
```sleep
$args = bof_pack($1, "ZZZZiiiib",
    $process_spawn, $parent_process, $working_dir, $cmd_line,
    $temp_block_dll, $temp_cfg_disable, $temp_use_rwx, $temp_exec,
    $shellcode);
```

### Required gate behavior
```sleep
if ($exec iswm "Hijack RIP Callback" && bool_to_int($cfg_disable) == 0) {
    berror($bid, "callback blocked: enable CFG-disable, then retry");
    return;
}
```
</code_examples>

<open_questions>
## Open Questions

1. **Debug toggle surface in CNA**
   - Known: must be explicit/on-demand.
   - Unknown: final operator command/variable name.
   - Plan handling: keep as local session toggle in this phase.

2. **Automated mapping regression placement**
   - Known: SAFE-03 requires deterministic documented mapping.
   - Unknown: whether automated drift checks land now or in test phase.
   - Plan handling: manual/documented contract in Phase 1; automated drift checks in later testing phase.
</open_questions>

<sources>
## Sources

### Primary (HIGH confidence)
- `BOF_spawn.cna`
- `Src/Bof.c`
- `.planning/phases/01-safety-defaults-contract-guardrails/01-CONTEXT.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
</sources>

<metadata>
## Metadata

**Research scope:** strict-safe defaults, callback/CFG gating, deterministic mapping, operator feedback style.

**Confidence breakdown:**
- Stack: HIGH
- Patterns: HIGH
- Pitfalls: HIGH
- Code examples: HIGH

**Research date:** 2026-02-25
**Valid until:** 2026-03-27
</metadata>

---

*Phase: 01-safety-defaults-contract-guardrails*
*Research refreshed: 2026-02-25T19:34:49Z*
*Ready for planning: yes*
