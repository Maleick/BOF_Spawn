# External Integrations

**Analysis Date:** 2026-02-25

## APIs & External Services

**Cobalt Strike Integration:**
- Cobalt Strike Aggressor + Beacon APIs - command registration, payload generation, and BOF execution
  - Entry script: `BOF_spawn.cna`
  - Invocation points: `beacon_command_register`, `alias spawn_beacon`, `alias spawn_shellcode`, `beacon_inline_execute`
  - Data contract: `bof_pack("ZZZZiiiib", ...)` consumed by `go()` in `Src/Bof.c`

**Windows Native/Userland APIs:**
- `ntdll` native calls for process/thread/memory operations
  - Used via indirect syscall resolution in `Src/Draugr.c` and `Src/Macros.h`
- `kernel32` APIs for module/procedure lookup and process enumeration helpers
  - Imports defined in `Src/Bofdefs.h`
- `shlwapi` `StrStrW` for process-name matching helper in `Src/Bof.c`

## Data Storage

**Databases:**
- None

**File Storage:**
- Build artifact output only (`Bin/bof.o`)
- No application persistence layer

**Caching:**
- None

## Authentication & Identity

**Auth Provider:**
- None in repository code

**Identity Context:**
- Operational identity and access are delegated to Cobalt Strike/Beacon session context, outside this repo

## Monitoring & Observability

**Error Tracking:**
- None (no Sentry/Datadog/New Relic integrations)

**Telemetry/Analytics:**
- None

**Logs:**
- Runtime status/errors surfaced through `BeaconPrintf` in `Src/Bof.c`
- Operator-side console output in `BOF_spawn.cna` via `println`/`berror`

## CI/CD & Deployment

**Hosting/Deployment Target:**
- No application hosting target; this is an operator artifact repo
- Primary deliverable is relocatable object file `Bin/bof.o`

**CI Pipeline:**
- No GitHub Actions or other CI config present in repository root

## Environment Configuration

**Development:**
- Tooling dependencies in `Dockerfile` or host package manager
- Build configuration in `Makefile`

**Staging/Production:**
- Operational settings are passed at run time through Cobalt Strike dialog (`ProcessConfig` in `BOF_spawn.cna`)
- No environment variable matrix is defined in-repo

## Webhooks & Callbacks

**Incoming Webhooks:**
- None

**Outgoing Webhooks:**
- None

**Callback-style Execution (internal):**
- Optional callback-based shellcode start path uses `EnumResourceTypesW` in `Src/Bof.c`
- This is a local Windows API callback mechanism, not a network/webhook integration

---

*Integration audit: 2026-02-25*
*Update when external dependencies or operator integrations change*
