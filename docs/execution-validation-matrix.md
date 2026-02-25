# Execution Validation Matrix

This matrix defines manual validation scenarios for each BOF Spawn execution method.
Use this as the canonical operator runbook for method-level validation before troubleshooting deeper runtime failures.

## Method Matrix

| Method | Prereq | Command Path | Success Signal | Failure Signal | Triage Hint |
|---|---|---|---|---|---|
| Hijack RIP Direct | x64 beacon; valid BOF path; listener or shellcode input | Configure `Hijack RIP Direct` in dialog, then run `spawn_beacon <listener>` or `spawn_shellcode <file>` | Beacon output includes successful BOF completion and payload execution path | `NtGetContextThread` / `NtSetContextThread` / `NtResumeProcess` error output | Treat as baseline control method; if this fails, fix baseline before testing gadget/callback paths |
| Hijack RIP Jmp Rax | Direct-method prereqs plus gadget availability in `ntdll.dll` | Configure `Hijack RIP Jmp Rax`, run same command path | Successful completion with no gadget lookup errors | `Failed to find JMP RAX gadget` or context-set failures | If Direct passes and Jmp Rax fails, isolate gadget/path-specific regression |
| Hijack RIP Jmp Rbx | Direct-method prereqs plus gadget availability in `ntdll.dll` | Configure `Hijack RIP Jmp Rbx`, run same command path | Successful completion with no gadget lookup errors | `Failed to find JMP RBX gadget` or context-set failures | Compare against Jmp Rax result to isolate gadget-specific breakage |
| Hijack RIP Callback | CFG-disable must be on; callback target (`EnumResourceTypesW`) must resolve | Configure `Hijack RIP Callback` and enable CFG-disable, then run same command path | Successful BOF completion with callback path executing shellcode | `callback blocked (cfg-disable is off)` or `Failed to find EnumResourceTypesW` | First verify precondition gate; then isolate callback symbol/dispatch path |

## Validation Notes

- Keep the same process profile across methods when comparing outcomes.
- Record exact error text and stage when a failure signal appears.
- Use the troubleshooting guide after method-level validation:
  - `docs/ntstatus-troubleshooting.md`
