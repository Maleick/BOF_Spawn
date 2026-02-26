# Architecture

**Analysis Date:** 2026-02-25

## Pattern Overview

**Overall:** Operator-driven BOF injection module with Aggressor-script control plane and native syscall/call-spoof execution core.

**Key Characteristics:**
- Single BOF payload artifact (`Bin/bof.o`) executed in Beacon context
- Control/config layer separated into Aggressor script (`BOF_spawn.cna`)
- Execution core composed of C logic plus assembly trampoline (`Src/Stub.s`)
- Evasion-focused runtime abstractions (indirect syscalls + synthetic stack)
- Strict-safe operator posture is enforced through script defaults plus runtime precondition gates

## Layers

**Operator Interface Layer:**
- Purpose: collect operator config, validate command usage, pack arguments
- Contains: command aliases, dialog/UI setup, payload loading, and preflight execution validation
- Files: `BOF_spawn.cna`
- Depends on: Beacon/Aggressor runtime
- Used by: operator in Cobalt Strike client

**BOF Entrypoint Layer:**
- Purpose: parse packed args and orchestrate execution path
- Contains: `go()` and execution-method enum mapping
- Files: `Src/Bof.c`
- Depends on: `Beacon.h`, `Draugr.h`, `VxTable.h`
- Used by: `beacon_inline_execute(..., "go", ...)`

**Injection Orchestration Layer:**
- Purpose: process creation, memory allocation/write/protect, thread context manipulation, resume
- Contains: `SpawnAndRun()` flow and gadget selection logic
- Files: `Src/Bof.c`
- Depends on: syscall wrappers/macros and Windows structures from `Native.h`

**Syscall + Call-Spoof Abstraction Layer:**
- Purpose: resolve syscall numbers/gadgets and invoke calls through spoofed call stacks
- Contains: `InitVxTable`, `DraugrResolveSyscall`, `DraugrCall`
- Files: `Src/Draugr.c`, `Src/Macros.h`, `Src/VxTable.h`, `Src/Vulcan.h`

**Assembly Trampoline Layer:**
- Purpose: preserve/restore registers and construct synthetic stack frame for call spoofing
- Contains: `SpoofStub`
- Files: `Src/Stub.s`

## Data Flow

**Spawn Beacon Flow:**
1. Operator runs `spawn_beacon <listener>` in Beacon.
2. `BOF_spawn.cna` validates architecture/listener, builds shellcode payload.
3. CNA packs config + shellcode (`ZZZZiiiib`) and calls `beacon_inline_execute`.
4. `go()` in `Src/Bof.c` parses args, initializes VxTable and Draugr frame.
5. `SpawnAndRun()` creates suspended process and injects payload.
6. Selected execution method updates thread context and process resumes.

**Spawn Custom Shellcode Flow:**
1. Operator runs `spawn_shellcode <file>`.
2. CNA loads shellcode bytes from disk.
3. Remaining flow mirrors `spawn_beacon` from BOF invocation onward.

**State Management:**
- Stateless within BOF execution lifecycle
- Mutable operator defaults live in script-global variables in `BOF_spawn.cna`
- No durable datastore

## Key Abstractions

**EXECUTION enum:**
- Purpose: choose start method for injected code
- Location: `Src/Bof.c`
- Variants: direct RIP, JMP RAX gadget, JMP RBX gadget, callback function

**VX_TABLE / VX_TABLE_ENTRY:**
- Purpose: hold syscall number and gadget address per NT API
- Location: `Src/VxTable.h`

**SYNTHETIC_STACK_FRAME + PRM:**
- Purpose: model call-stack spoof context and trampoline metadata
- Location: `Src/Vulcan.h`

**DRAUGR_SYSCALL / DRAUGR_API macros:**
- Purpose: normalize variadic invocation into spoofed call entrypoint
- Location: `Src/Macros.h`

## Entry Points

**Aggressor Commands:**
- Location: `BOF_spawn.cna`
- Triggers: operator command execution in Beacon
- Responsibilities: input collection, payload packing, BOF dispatch

**BOF Function Entry:**
- Location: `Src/Bof.c` (`void go(char* Args, int Len)`)
- Triggers: Cobalt Strike inline execute call
- Responsibilities: argument parsing, initialization, orchestration, output

## Error Handling

**Strategy:**
- Return-on-failure with NTSTATUS propagation in C path
- Human-readable status via `BeaconPrintf(CALLBACK_ERROR, ...)`
- Early validation errors in CNA via `berror`

**Patterns:**
- Fail fast when imports/symbols cannot be resolved
- Fail fast on syscall failure (`NT_ERROR(Status)`)
- Minimal recovery/retry behavior
- Fail-closed execution checks surface callback gate diagnostics (`callback blocked (cfg-disable is off)`)

## Cross-Cutting Concerns

**Operational Stealth/Evasion:**
- Indirect syscalls and stack spoofing are integrated into core call path
- Mitigation policy toggles (BlockDLL/CFG) handled during process creation
- Default documentation and runtime behavior align on strict-safe posture for method selection and memory permissions

**Architecture Constraints:**
- x64-only assumptions present in assembly and context register logic
- Windows-specific API surface throughout headers and implementation

---

*Architecture analysis: 2026-02-25*
*Update when control flow, layers, or execution model changes*
