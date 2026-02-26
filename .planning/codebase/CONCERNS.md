# Codebase Concerns

**Analysis Date:** 2026-02-25

## Tech Debt

**Resource cleanup remains sensitive but now centralized (`Src/Bof.c`):**
- Current state: `SpawnAndRun()` uses centralized `cleanup` handling for owned resources.
- Evidence anchors: `NtClose` for process/thread handles and `RtlDestroyProcessParameters` / `RtlFreeHeap` for process params and attribute list.
- Residual risk: future edits that bypass `cleanup` could reintroduce leaks.
- Maintenance rule: keep all failure exits routed through shared cleanup path.

**Header coupling and monolithic declarations (`Src/Native.h`):**
- Issue: large native API/type surface in a single header (~10k lines) increases cognitive load and compile coupling.
- Why: convenience of single include for native structures/constants.
- Impact: difficult maintenance and higher risk of accidental breakage when editing declarations.
- Fix approach: split into domain headers (process, memory, thread, structures) and keep compatibility shim.

## Known Bugs / High-Risk Behaviors

**PPID matching hardening is implemented (`Src/Bof.c`):**
- Current state: `GetProcessIdWithNameW` enforces exact case-insensitive executable-name matching.
- Evidence anchors: basename normalization plus `lstrcmpiW` equality check.
- Residual risk: operators still need the correct executable basename when configuring PPID spoofing.
- Maintenance rule: preserve exact-match behavior (no substring or fuzzy fallback).

**Gadget lookup is naive linear scan (`Src/Bof.c`, `Src/Draugr.c`):**
- Symptoms: unpredictable behavior across OS/library versions; potential misses or unintended gadgets.
- Trigger: differing module contents/patch levels.
- Workaround: verify behavior against target Windows builds before operational use.
- Root cause: byte-pattern only search without stronger validation constraints.
- Fix approach: add section bounds checks, instruction-context validation, and fallback strategy.

## Security Considerations

**Injection telemetry exposure is intrinsic to approach:**
- Risk: process creation, memory writes, context manipulation, and mitigation policy toggles are visible to modern EDR telemetry.
- Current mitigation: indirect syscalls and stack spoofing to reduce userland-hook visibility.
- Recommendations: treat as defense-in-depth only, add operational guidance for safer defaults in `README.md` and `BOF_spawn.cna`.

**Callback mode requires CFG disable (`Src/Bof.c`, `BOF_spawn.cna`):**
- Risk: disabling CFG can be a strong behavioral detection indicator.
- Current mitigation: operator option rather than mandatory path.
- Recommendations: default to non-CFG-disabling methods and emit explicit warning when callback mode is selected.

## Performance Bottlenecks

**Repeated runtime syscall/gadget discovery (`Src/Draugr.c`):**
- Problem: startup overhead from resolving syscall metadata on each BOF run.
- Measurement: no benchmark instrumentation present.
- Cause: dynamic lookup by design.
- Improvement path: cache invariant lookup results when safe within BOF execution lifecycle.

**Linear module scans for gadget finding (`Src/Bof.c`, `Src/Draugr.c`):**
- Problem: O(n) scans over module sections for byte patterns.
- Measurement: no timing metrics in-repo.
- Cause: straightforward scan implementation.
- Improvement path: constrain scan ranges and add lightweight indexed search heuristics.

## Fragile Areas

**Assembly trampoline and structure contract coupling (`Src/Stub.s`, `Src/Vulcan.h`):**
- Why fragile: hard-coded struct offsets in assembly must match C struct layout exactly.
- Common failures: subtle crashes/corruption after struct changes.
- Safe modification: treat struct layout as ABI; update assembly and C in lockstep.
- Test coverage: no automated regression tests currently.

**Hardcoded offsets in synthetic stack init (`Src/Draugr.c`):**
- Why fragile: fixed offsets (`0x14`, `0x21`) assume stable function layouts.
- Common failures: OS/runtime updates can invalidate assumptions.
- Safe modification: derive offsets dynamically where possible or gate by validated OS build matrix.
- Test coverage: no compatibility matrix tests in-repo.

## Scaling Limits

**Feature extensibility ceiling in single-file orchestration (`Src/Bof.c`):**
- Current capacity: all execution methods and orchestration logic are centralized in one large source file.
- Limit: adding new execution paths increases complexity and review risk.
- Symptoms at limit: harder onboarding, slower safe refactoring.
- Scaling path: split into focused modules (process-create, memory-write, exec-method handlers).

## Dependencies at Risk

**Pinned cross-compiler package in `Dockerfile`:**
- Risk: strict version pin (`gcc-mingw-w64-x86-64=10.3.0-14ubuntu1+24.3`) may become unavailable in apt indexes.
- Impact: Docker builds can fail unexpectedly over time.
- Migration plan: add fallback strategy or move to reproducible image digest with validated package set.

## Missing Critical Features

**No automated compatibility checks across Windows versions:**
- Problem: behavior differences across target OS builds can go unnoticed.
- Current workaround: ad-hoc operator validation.
- Blocks: reliable confidence in broad target compatibility.
- Implementation complexity: medium (requires controlled test matrix and harness).

## Test Coverage Gaps

**No automated tests for BOF argument contract:**
- What's not tested: field ordering/type coupling between `bof_pack` in `BOF_spawn.cna` and `BeaconDataExtract` parsing in `Src/Bof.c`.
- Risk: silent breakage if CNA/BOF drift.
- Priority: High.
- Difficulty to test: Medium (requires harness or integration test rig).

**No regression tests for failure cleanup paths:**
- What's not tested: resource cleanup correctness after intermediate syscall failures.
- Risk: memory/handle leaks and unstable behavior under fault conditions.
- Priority: High.
- Difficulty to test: Medium-High (needs controllable failure injection).

---

*Concerns audit: 2026-02-25*
*Update as issues are fixed or newly discovered*
