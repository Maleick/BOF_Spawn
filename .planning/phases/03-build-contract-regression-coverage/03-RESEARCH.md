# Phase 3: Build & Contract Regression Coverage - Research

**Researched:** 2026-02-25T20:58:18Z
**Domain:** Repeatable BOF build verification and deterministic CNA/BOF contract regression checks
**Confidence:** HIGH

<user_constraints>
## User Constraints

### Locked Decisions (from run-level plan)
- No discuss/context step for Phase 3; plan from roadmap + requirements + repo evidence only.
- Plan output must target scripts + docs.
- Contract drift detection must use a structured checker (not grep-only).

### Context File Status
- No `03-CONTEXT.md` is provided by design for this run.

### Deferred Ideas (OUT OF SCOPE)
- New runtime execution capabilities.
- Architecture expansion beyond build/contract verification.
</user_constraints>

<research_summary>
## Summary

Phase 3 requirements map cleanly to two deliverables:
1. A repeatable build verification entrypoint that checks local toolchain and containerized toolchain paths both produce `Bin/bof.o` (`TEST-01`).
2. A structured contract checker that parses both the CNA pack schema and BOF parser extraction sequence, then returns machine-readable pass/fail output (`TEST-02`).

The repository already exposes the core build path in `Makefile` (`spawn_bof`) and container path in `Dockerfile`, and it already documents the contract table in `README.md`. This allows planning to focus on codifying checks into scripts and wiring documentation around those scripts instead of inventing new workflow primitives.

**Primary recommendation:** use one build verification script plus one structured contract-check script, then document one standard invocation surface in README/.planning so maintainers can run both quickly and triage failures deterministically.
</research_summary>

<standard_stack>
## Standard Stack

### Core
| Runtime / Interface | Purpose | Why Standard |
|---------------------|---------|--------------|
| `make spawn_bof` | Canonical local build path to `Bin/bof.o` | Already defined in repo Makefile |
| `docker build` + `docker run ... make spawn_bof` | Canonical containerized build path | Already documented and aligned with Dockerfile dependencies |
| Structured checker script (`python3`) | Deterministic contract drift detection across CNA + BOF parser | Suitable for parsing and emitting machine-readable pass/fail |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| `rg` | Fast static assertions during script verification | Smoke-checking expected markers in source |
| `README.md` + `.planning` docs | Operator/maintainer instructions and triage guidance | Human-facing repeatability + troubleshooting |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Structured checker script | Grep-only checks | Grep is brittle against formatting/comment changes; low semantic confidence |
| Single-path build check | Local-only or container-only checks | Misses environment-specific drift and undermines TEST-01 |
| Script+docs pairing | Docs-only commands | Less repeatable and weaker regression guardrails |
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Pattern 1: Single entrypoint for build verification
Use a script wrapper that executes local and container checks in a predictable order and enforces existence/non-zero size of `Bin/bof.o` after each path.

### Pattern 2: Structured contract extraction and compare
Extract contract tokens from:
- `BOF_spawn.cna`: `bof_pack($bid, "ZZZZiiiib", ...)` field order
- `Src/Bof.c`: `BeaconDataExtract` + `BeaconDataInt` sequence in `go()`
Then compare normalized arrays and produce explicit mismatch diagnostics.

### Pattern 3: Script output optimized for triage
Emit concise, action-first failures with clear "expected vs actual" differences and a non-zero exit code suitable for CI/manual runs.

### Anti-Patterns to Avoid
- Verifying contract with loose substring checks only.
- Implicit assumptions about parser order without extracting actual sequence.
- Build checks that pass on command status only without artifact validation.
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Build health verification | Ad-hoc manual commands per maintainer | Scripted checks invoking Makefile/Docker commands | Deterministic, repeatable output |
| Contract drift detection | Human eyeballing README table | Structured parser/validator over CNA + BOF source | Detects semantic ordering/type drift reliably |
| Failure interpretation | Verbose multi-page logs | One-line cause + targeted next step | Faster triage under phase goal |

**Key insight:** Phase 3 should formalize existing behavior into repeatable checks, not add new runtime logic.
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: False-positive build success
- **What goes wrong:** command exits 0 but `Bin/bof.o` is stale/missing.
- **How to avoid:** always verify artifact exists and has non-zero size after each build path.

### Pitfall 2: Contract checker tied to formatting
- **What goes wrong:** harmless code formatting breaks checker.
- **How to avoid:** parse semantic tokens/order, not exact line shapes.

### Pitfall 3: Drift between code and docs
- **What goes wrong:** script behavior changes but README instructions lag.
- **How to avoid:** plan includes explicit docs updates linked to script entrypoints and expected outputs.
</common_pitfalls>

<code_examples>
## Code Examples

### Local build command from current Makefile flow
```bash
make spawn_bof
```

### Containerized build command from current docs
```bash
docker build -t ubuntu-gcc-13 .
docker run --rm -v "$PWD":/work -w /work ubuntu-gcc-13:latest make spawn_bof
```

### Contract anchors to validate
```sleep
bof_pack($1, "ZZZZiiiib", ...)
```

```c
lpwProcessName = (LPWSTR)BeaconDataExtract(&parser, &StrLen);
BlockDllPolicy = BeaconDataInt(&parser);
MemExec = BeaconDataInt(&parser);
Shellcode = BeaconDataExtract(&parser, &ShellcodeSize);
```
</code_examples>

<open_questions>
## Open Questions

1. **Script placement convention**
   - Options discovered: repository root scripts vs `.planning` utility scripts.
   - Planning default recommendation: `scripts/` under repo root for maintainability and execute-phase ergonomics.

2. **Checker output format**
   - Minimum needed: stdout summary + exit code.
   - Preferred: machine-readable JSON in addition to concise terminal summary.

3. **Container tool name assumptions**
   - Current docs use `docker`; environments may use rootless/podman equivalents.
   - Plan recommendation: document docker as canonical path and keep script override variable optional.
</open_questions>

<sources>
## Sources

### Primary (HIGH confidence)
- `Makefile`
- `Dockerfile`
- `README.md`
- `BOF_spawn.cna`
- `Src/Bof.c`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
</sources>

<metadata>
## Metadata

**Research scope:** TEST-01 and TEST-02 planning inputs.

**Confidence breakdown:**
- Build verification strategy: HIGH
- Contract checker strategy: HIGH
- Docs integration strategy: HIGH

**Research date:** 2026-02-25
**Valid until:** 2026-03-27
</metadata>

---

*Phase: 03-build-contract-regression-coverage*
*Research refreshed: 2026-02-25T20:58:18Z*
*Ready for planning: yes*
