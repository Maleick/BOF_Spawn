# NTSTATUS Troubleshooting Guide

Use this guide to map dominant BOF Spawn failure surfaces to likely causes and immediate operator actions.

## Dominant Failure Classes

| Failure Surface / Code | Likely Cause | Immediate next step |
|---|---|---|
| `STATUS_INVALID_PARAMETER` with `invalid execution method` | Unsupported execution-method value reached runtime precondition gate | Select a supported execution method and retry |
| `STATUS_INVALID_PARAMETER` with `callback blocked (cfg-disable is off)` | Callback mode selected without CFG-disable | Enable CFG-disable, keep other settings constant, rerun callback method |
| `STATUS_INVALID_PARAMETER_2` during parent lookup/open | PPID process name not exact-match resolvable | Use exact executable name (for example `explorer.exe`) and retry |
| `STATUS_DATA_ERROR` with gadget lookup failure | `JMP RAX` / `JMP RBX` gadget not found in target environment | Validate Direct method baseline, then re-test gadget path |
| `STATUS_PROCEDURE_NOT_FOUND` for `EnumResourceTypesW` | Callback dispatch symbol resolution failed | Verify callback path prerequisites and fallback to Direct baseline for isolation |
| `STATUS_INSUFFICIENT_RESOURCES` | Attribute/process parameter allocation failure | Reduce pressure in current beacon/session and retry |
| `NtCreateUserProcess` failure | Process creation policy/target path/environment mismatch | Confirm process path and mitigation settings, then retry with known-good baseline profile |
| `NtGetContextThread` failure | Thread context not accessible under current target state | Re-run with Direct baseline and validate suspended target state |
| `NtSetContextThread` failure | Context update blocked or invalid for current method/path | Re-test with Direct method and compare against same process profile |
| `NtResumeProcess` failure | Target process resume path failed after setup | Confirm prior setup stages succeeded and retry using baseline method |

## Stage-Correlated Signals

- Precondition stage: invalid method or callback gate failures.
- Parent/process setup stage: parent lookup and `NtCreateUserProcess` class failures.
- Context stage: `NtGetContextThread` / `NtSetContextThread` failures.
- Final dispatch stage: `NtResumeProcess` failures.

## Notes

- Preserve exact error text when escalating an issue.
- Keep method, process profile, and command path unchanged when reproducing a failure for isolation.
