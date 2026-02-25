# Phase 1: Safety Defaults & Contract Guardrails - Research

**Researched:** 2026-02-25
**Domain:** Cobalt Strike Aggressor-to-BOF safety contract hardening
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

Phase 1 is primarily a contract-clarity and guardrail pass over existing code paths in `BOF_spawn.cna` and `Src/Bof.c`. The current runtime already supports safe RW->RX behavior (`use_rwx=false`), but defaults are inconsistent with the locked posture because callback execution is currently the default in CNA while callback requires CFG-disable. This creates an avoidable unsafe/ambiguous startup profile.

The most reliable implementation approach is to make CNA the authoritative preflight gate (operator-facing defaults, messaging, execution preconditions) while also adding a defensive BOF-side precondition check for callback+CFG mismatch. This gives operators actionable feedback before execution and prevents latent invalid combinations from reaching thread-context tampering paths.

**Primary recommendation:** centralize argument mapping and preflight validation in CNA, then enforce the same callback/CFG invariant in BOF for fail-closed behavior.
</research_summary>

<standard_stack>
## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Aggressor Script (Sleep) | Cobalt Strike runtime | Operator dialog, defaults, argument packing, execution dispatch | Native control surface for Beacon operator UX and policy gating |
| Beacon BOF API (`BeaconDataParse`, `BeaconDataExtract`, `BeaconDataInt`) | Cobalt Strike runtime | Parse packed arguments inside BOF | Canonical BOF contract parsing path |
| Windows Native APIs via existing wrappers (`Nt*`) | Repo-embedded | Process creation, memory, thread context operations | Existing implementation foundation in `Src/Bof.c` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Draugr/VxTable repo headers | Repo-embedded | Existing syscall/stack framework | Keep unchanged unless requirement explicitly needs internals change |
| `rg`/static grep checks | Local tooling | Fast contract and message validation in CI/local | Validate mapping strings and parser-order invariants |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| CNA-first guardrails | BOF-only validation | Too late for operator feedback; violates action-first pre-execution warning contract |
| String-to-int mapping with implicit fallback | Explicit table + hard error | Explicit mapping is safer and supports deterministic SAFE-03 behavior |

**Installation:**
```bash
# No new dependency installation required for Phase 1 planning scope.
```
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Recommended Project Structure
```
BOF_spawn.cna              # Operator defaults, dialog controls, preflight gate, argument packing
Src/Bof.c                  # BOF argument parsing and runtime defensive preconditions
.planning/phases/01-.../   # Research/plan artifacts for execution handoff
```

### Pattern 1: Single source of default safety posture
**What:** Keep defaults in one authoritative CNA location and ensure both aliases (`spawn_beacon`, `spawn_shellcode`) consume the same normalized values.
**When to use:** Any change to default execution options, warnings, or profile toggles.

### Pattern 2: Dual-layer invariant enforcement
**What:** Enforce callback+CFG precondition in CNA (operator-facing) and in BOF (runtime fail-closed).
**When to use:** Preconditions that can produce unsafe runtime behavior if bypassed.

### Pattern 3: Contract lockstep between pack and parse
**What:** Treat `bof_pack("ZZZZiiiib", ...)` order as a strict interface mirrored by `go()` extraction and `BeaconDataInt()` sequence.
**When to use:** Any update to argument fields, order, type, or execution-method enums.

### Anti-Patterns to Avoid
- **Silent fallback for unknown execution method:** hides contract drift and breaks deterministic behavior.
- **Duplicated mapping logic with drift risk:** `spawn_beacon` and `spawn_shellcode` should not diverge in string->enum behavior.
- **Verbose default failure dumps:** violates action-first concise output contract.
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Argument parser in BOF | Custom binary parser | Existing `BeaconDataParse` + `BeaconDataExtract` + `BeaconDataInt` sequence | Maintains compatibility with Beacon runtime packing format |
| Precondition diagnostics in multiple places | Divergent ad hoc error strings | Shared helper formatting in CNA + minimal BOF defensive guard | Prevents operator confusion and drift |
| Execution method translation | Partial if/else with implicit default 0 | Explicit mapping helper with error on unknown input | Eliminates hidden fallback and enforces SAFE-03 determinism |

**Key insight:** phase success depends on explicit contracts, not new injection mechanics.
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Unsafe default mismatch between mode and preconditions
**What goes wrong:** Callback is default while CFG dependency is implicit.
**Why it happens:** Defaults and preconditions evolved separately.
**How to avoid:** Set non-callback default and enforce callback gate before packing/execution.
**Warning signs:** Fresh session prints callback execution without explicit user opt-in.

### Pitfall 2: Mapping drift between aliases
**What goes wrong:** `spawn_beacon` and `spawn_shellcode` convert method strings differently over time.
**Why it happens:** Duplicate conversion code blocks.
**How to avoid:** Shared helper for mapping and argument normalization.
**Warning signs:** Same config yields different `Execution` numeric output by alias.

### Pitfall 3: Parser contract drift hidden until runtime
**What goes wrong:** `bof_pack` format/order diverges from `go()` parse order.
**Why it happens:** Packing changes without mirrored parser/document updates.
**How to avoid:** Keep a documented field-order table and static verification checks.
**Warning signs:** Nonsensical BOF configuration output or incorrect mitigation flags at runtime.
</common_pitfalls>

<code_examples>
## Code Examples

### Current pack/parse contract anchor
```c
// Src/Bof.c::go()
BlockDllPolicy  = BeaconDataInt(&parser);
DisableCfg      = BeaconDataInt(&parser);
UseRWX          = BeaconDataInt(&parser);
MemExec         = BeaconDataInt(&parser);
```

### Current CNA packing format anchor
```sleep
# BOF_spawn.cna
$args = bof_pack($1, "ZZZZiiiib",
    $process_spawn, $parent_process, $working_dir, $cmd_line,
    $temp_block_dll, $temp_cfg_disable, $temp_use_rwx, $temp_exec,
    $shellcode);
```

### Recommended preflight gate shape
```sleep
if ($exec iswm "Hijack RIP Callback" && bool_to_int($cfg_disable) == 0) {
    berror($bid, "callback blocked: enable CFG-disable, then retry");
    return;
}
```
</code_examples>

<open_questions>
## Open Questions

1. **Debug toggle surface**
   - What we know: context requires explicit on-demand debug mode.
   - What is unclear: best operator-facing command naming/location.
   - Recommendation: implement a simple session variable toggle in CNA first; avoid new command surface beyond phase scope.

2. **Contract documentation location**
   - What we know: SAFE-03 requires deterministic and documented mapping.
   - What is unclear: whether final source of truth should live in README, code comment block, or both.
   - Recommendation: maintain canonical table in README and mirror concise invariant comments beside pack/parse code.
</open_questions>

<sources>
## Sources

### Primary (HIGH confidence)
- `BOF_spawn.cna` - defaults, dialog fields, mapping logic, `bof_pack` contract
- `Src/Bof.c` - parser order, execution switch behavior, current diagnostics
- `.planning/ROADMAP.md` - phase goal, success criteria, plan count
- `.planning/REQUIREMENTS.md` - SAFE-01, SAFE-02, SAFE-03 requirement definitions
- `.planning/phases/01-safety-defaults-contract-guardrails/01-CONTEXT.md` - locked user decisions
</sources>

<metadata>
## Metadata

**Research scope:**
- Core technology: Aggressor script + BOF argument contract
- Patterns: defaults, preflight gating, deterministic mapping
- Pitfalls: unsafe defaults, implicit fallbacks, pack/parse drift

**Confidence breakdown:**
- Standard stack: HIGH - repo already defines the stack and interfaces
- Architecture: HIGH - driven by existing code paths and locked decisions
- Pitfalls: HIGH - directly visible in current defaults and duplicate mapping blocks
- Code examples: HIGH - extracted from local source files

**Research date:** 2026-02-25
**Valid until:** 2026-03-27 (stable codebase-local research)
</metadata>

---

*Phase: 01-safety-defaults-contract-guardrails*
*Research completed: 2026-02-25*
*Ready for planning: yes*
