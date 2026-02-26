# Phase 4: Execution Validation & Troubleshooting - Context

**Gathered:** 2026-02-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Define clear operator-facing validation scenarios for each execution method and provide troubleshooting guidance that maps dominant NTSTATUS failures to likely causes and immediate next actions. Scope is limited to execution validation and troubleshooting guidance for existing BOF Spawn behavior; no new runtime capabilities are introduced.

</domain>

<decisions>
## Implementation Decisions

### Method Validation Matrix Contract
- Phase output must include a method-by-method validation matrix covering all four execution methods:
  - Hijack RIP Direct
  - Hijack RIP Jmp Rax
  - Hijack RIP Jmp Rbx
  - Hijack RIP Callback
- Each method entry must include:
  - Required configuration prerequisites (CFG-disable, Block DLL, RWX/RW->RX considerations)
  - One canonical operator invocation path
  - Expected success signals
  - Expected failure signals
  - Fast triage notes for method-specific regressions
- Validation flow should run in deterministic order: Direct first (baseline), then gadget paths, then callback path.

### NTSTATUS Troubleshooting Contract
- Troubleshooting guidance must map dominant failure classes observed in `Src/Bof.c` to:
  - Likely root cause
  - Immediate next action
  - Relevant precondition or configuration fix
- Guidance must explicitly include handling for:
  - Invalid execution method / callback-CFG precondition failures
  - Parent-process resolution failures
  - Gadget lookup failures (JMP RAX/JMP RBX)
  - Callback function resolution failures
  - Common syscall-stage failures (`NtCreateUserProcess`, memory, context, resume)
- Unknown/unmapped NTSTATUS values must default to a fail-closed troubleshooting path (capture stage + settings + rerun baseline method).

### Operator Feedback Style for Documentation
- Documentation output style must be action-first and concise.
- Each troubleshooting row must use one-line "cause -> next step" phrasing.
- Validation instructions should prioritize copy/paste command blocks and expected output markers over long narrative text.
- Keep low-noise structure: quick matrix/table first, deeper notes second.

### Claude's Discretion
- Exact markdown table and section formatting.
- Exact wording of command examples and success/failure sample strings.
- Exact grouping of NTSTATUS rows as long as dominant failures remain clearly mapped to next actions.

</decisions>

<specifics>
## Specific Ideas

- Include a compact "Method -> Prereq -> Command -> Expected Signal" matrix that operators can run top-to-bottom.
- Include a troubleshooting section that starts with "If you only run one check, run Direct method baseline first."
- Preserve concise fix-oriented language already used in existing build and preflight outputs.

</specifics>

<deferred>
## Deferred Ideas

- Automated execution-method integration harness is deferred to a future phase (out of scope for this documentation-focused phase).

</deferred>

---

*Phase: 04-execution-validation-troubleshooting*
*Context gathered: 2026-02-25*
