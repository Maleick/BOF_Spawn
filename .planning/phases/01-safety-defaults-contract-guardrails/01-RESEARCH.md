# Phase 1: Safety Defaults & Contract Guardrails - Research

**Researched:** 2026-02-25 (refresh run via --research)
**Domain:** Cobalt Strike CNA-to-BOF safety defaults and execution contract guardrails
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

A fresh pass over `BOF_spawn.cna` and `Src/Bof.c` confirms the phase remains contract-hardening work with no new capability surface. Current defaults still conflict with the locked posture: RWX is safe-biased (`false`) but callback is still default, and callback precondition (CFG-disable) is presented as guidance instead of a hard preflight gate. This leaves room for invalid combinations to progress too far.

The highest-leverage plan is to establish CNA as authoritative for operator-facing defaults, mapping normalization, and pre-execution guardrails, then add BOF-side fail-closed validation for callback/CFG invariants. This dual-layer approach satisfies explicit operator feedback requirements while preventing latent invalid invocation paths.

**Primary recommendation:** centralize default policy + method mapping + preflight checks in CNA, mirror critical callback precondition check in BOF, and keep pack/parse contract documentation synchronized in code and README.
</research_summary>

<standard_stack>
## Standard Stack

### Core
| Library / Runtime | Version | Purpose | Why Standard |
|-------------------|---------|---------|--------------|
| Aggressor Script (Sleep) | Cobalt Strike runtime | Dialog defaults, preflight validation, argument packing | Primary operator control plane |
| Beacon BOF parser primitives (`BeaconDataParse`, `BeaconDataExtract`, `BeaconDataInt`) | Cobalt Strike runtime | Parse packed input inside BOF | Canonical interface for CNA->BOF argument transfer |
| Existing Native API wrappers (`Nt*`, Draugr/VxTable) | Repo-embedded | Process/memory/thread operations | Already integrated; phase does not replace core internals |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `rg` static checks | Local CLI | Validate mapping paths and contract strings | During review and regression checks |
| README contract table | Repo docs | Keep mapping deterministic and operator-visible | When updating any field order/type/value mapping |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| CNA + BOF dual guardrail | CNA-only gating | Better UX but weaker defense if CNA path is bypassed |
| Explicit method resolver with hard fail | Implicit fallback to method `0` | Fallback hides drift and violates SAFE-03 determinism |
| Single pack helper shared by aliases | Duplicate mapping blocks | Duplication increases drift risk between `spawn_beacon` and `spawn_shellcode` |

**Installation:**
```bash
# No external package additions required.
```
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Pattern 1: Single-source default profile
Keep session defaults in one CNA block and ensure both aliases consume normalized values through shared helpers.

### Pattern 2: Preflight-first operator guardrails
Validate callback/CFG and related risk posture before BOF load/pack/execute. Emit concise action-first remediation when blocked.

### Pattern 3: Contract lockstep between pack and parse
Treat `bof_pack("ZZZZiiiib", ...)` field order/type as a strict interface mirrored by `go()` extraction and integer decode order.

### Anti-Patterns to Avoid
- Duplicate method-string mapping logic in each alias.
- Silent fallback when execution-method string is unknown.
- Warning-only handling for callback+CFG mismatch.
- Verbose default output that buries next action.
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| BOF argument decoding | Custom parser format | Existing Beacon parser functions | Ensures Beacon compatibility |
| Independent alias mapping paths | Per-command if/else branches | Shared resolver + shared pack helper | Prevents mapping drift |
| Late runtime-only precondition checks | No CNA preflight | CNA preflight + BOF defensive check | Meets UX contract and fail-closed safety |

**Key insight:** this phase wins by removing ambiguity in existing interfaces, not by adding new execution mechanics.
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Callback default with implicit CFG dependency
**What goes wrong:** Unsafe/ambiguous defaults at session start.
**How to avoid:** Non-callback default plus hard preflight block for callback when CFG-disable is off.

### Pitfall 2: Alias drift in method mapping
**What goes wrong:** Same UI selection maps differently depending on alias path.
**How to avoid:** One shared resolver and shared pack helper.

### Pitfall 3: Pack/parse contract drift over time
**What goes wrong:** CNA field order diverges from BOF parser interpretation.
**How to avoid:** Explicit mapping table in README and comment-level contract mirror near `go()` parser block.
</common_pitfalls>

<code_examples>
## Code Examples

### Current parser order anchor
```c
// Src/Bof.c
BlockDllPolicy  = BeaconDataInt(&parser);
DisableCfg      = BeaconDataInt(&parser);
UseRWX          = BeaconDataInt(&parser);
MemExec         = BeaconDataInt(&parser);
```

### Current pack format anchor
```sleep
# BOF_spawn.cna
$args = bof_pack($1, "ZZZZiiiib",
    $process_spawn, $parent_process, $working_dir, $cmd_line,
    $temp_block_dll, $temp_cfg_disable, $temp_use_rwx, $temp_exec,
    $shellcode);
```

### Required preflight gate behavior
```sleep
if ($exec iswm "Hijack RIP Callback" && bool_to_int($cfg_disable) == 0) {
    berror($bid, "callback blocked: enable CFG-disable, then retry");
    return;
}
```
</code_examples>

<open_questions>
## Open Questions

1. **Debug toggle naming in CNA**
   - Known: debug must be explicit and on-demand.
   - Unknown: final command/variable naming convention.
   - Recommendation: phase keeps this as a simple session variable to avoid scope creep.

2. **Contract-regression check placement**
   - Known: SAFE-03 requires deterministic mapping + documentation.
   - Unknown: whether automated drift check lands in Phase 1 or Phase 3.
   - Recommendation: document deterministic mapping now; automation lands in Phase 3 (`TEST-02`).
</open_questions>

<sources>
## Sources

### Primary (HIGH confidence)
- `BOF_spawn.cna` (defaults, dialog, mapping, packing)
- `Src/Bof.c` (parser order, execution mode handling)
- `.planning/phases/01-safety-defaults-contract-guardrails/01-CONTEXT.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
</sources>

<metadata>
## Metadata

**Research scope:**
- Safety defaults and operator-facing guardrails
- Callback/CFG precondition behavior
- Deterministic packing/parsing mapping

**Confidence breakdown:**
- Standard stack: HIGH
- Architecture patterns: HIGH
- Pitfalls: HIGH
- Code examples: HIGH

**Research date:** 2026-02-25
**Valid until:** 2026-03-27
</metadata>

---

*Phase: 01-safety-defaults-contract-guardrails*
*Research refreshed: 2026-02-25*
*Ready for planning: yes*
