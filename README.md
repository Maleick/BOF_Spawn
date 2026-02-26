# BOF Spawn - Process Injection 

## Update

### 11/23/25

- Update `Makefile` and add `.gitkeep` in `Bin/` and `Bin/temp`, thanks @0xTriboulet for issues
- Update `BOF_spawn.cna` to fix initialization, thanks @D1sAbl4 for issues

## Overview

**BOF Spawn** is a Beacon Object File for Cobalt Strike that implements process spawning and shellcode injection Draugr stack spoofing with indirect syscalls. This tool combines multiple evasion techniques to bypass userland hooks, call stack analysis, and memory scanners.

**Architecture**: x64 only

### Core Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Cobalt Strike Beacon                      │
│                    (Parent Process)                          │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         │ beacon_inline_execute()
                         │
                         ▼
          ┌──────────────────────────────┐
          │      BOF Spawn (Bof.c)       │
          │  ┌────────────────────────┐  │
          │  │  VxTable Initialization │ │
          │  │  (Syscall Resolution)   │ │
          │  └──────────┬─────────────┘  │
          │             │                │
          │  ┌──────────▼─────────────┐  │
          │  │  Draugr Framework      │  │
          │  │  - Stack Spoofing      │  │
          │  │  - Indirect Syscalls   │  │
          │  └──────────┬─────────────┘  │
          │             │                │
          │  ┌──────────▼─────────────┐  │
          │  │  SpawnAndRun()         │  │
          │  │  - Process Creation    │  │
          │  │  - Memory Allocation   │  │
          │  │  - Shellcode Injection │  │
          │  │  - Execution           │  │
          │  └────────────────────────┘  │
          └──────────────┬───────────────┘
                         │
                         ▼
          ┌──────────────────────────────┐
          │     Target Process           │
          │  (Suspended → Executing)     │
          │                              │
          │  ┌────────────────────────┐  │
          │  │  Injected Shellcode    │  │
          │  └────────────────────────┘  │
          └──────────────────────────────┘
```

## Configuration Options

The BOF provides extensive customization through the CNA script configuration dialog:

| Option | Description | Format/Notes |
|--------|-------------|--------------|
| **Process Name** | Executable path to spawn | NT path format: `\??\C:\Windows\System32\rundll32.exe` |
| **Working Directory** | Current directory for spawned process | Standard path: `C:\Windows\System32` |
| **PPID Spoof Process** | Parent process name for PPID spoofing | Process name only (e.g., `explorer.exe`) |
| **Command Line** | Arguments for spawned process | Full command line string |
| **Block DLL Policy** | Restrict to Microsoft-signed DLLs only | Boolean |
| **Disable CFG** | Disable Control Flow Guard | Boolean - Required for callback execution method |
| **Use RWX** | Allocate memory as RWX vs RW→RX | Boolean - RW→RX recommended for stealth |
| **Execution Method** | Shellcode execution technique | See section below |

**Note on Process Path Format**: The BOF uses NT path format (`\??\C:\...`) for the process name. This is the native format used by `NtCreateUserProcess` and bypasses some Win32 path parsing mechanisms.

## Safe Defaults (DOCS-01)

Default operator posture is `strict-safe` and action-first:

- **Execution method default:** `Hijack RIP Direct` (callback path is explicit opt-in).
- **Memory posture default:** `RW->RX` transition path is preferred.
- **RWX posture:** `RWX` is manual opt-in only.
- **Callback gate behavior:** callback execution is blocked when `CFG-disable` is off (`callback blocked (cfg-disable is off)`).

Use this default profile first, then only widen risk posture when a specific target constraint requires it.

## CNA to BOF Argument Mapping Contract

The packing/parsing contract is deterministic and order-sensitive.

- CNA pack format: `bof_pack($bid, "ZZZZiiiib", ...)`
- BOF parser entrypoint: `Src/Bof.c::go()`
- Any reorder/type change in CNA must be mirrored in `go()` extraction order.

| Pack Position | Type | CNA Source Field | BOF Parser Target |
|---------------|------|------------------|-------------------|
| 1 | `Z` | `process_spawn` | `lpwProcessName = BeaconDataExtract(...)` |
| 2 | `Z` | `parent_process` | `lpwParentProcessName = BeaconDataExtract(...)` |
| 3 | `Z` | `working_dir` | `lpwWorkingDir = BeaconDataExtract(...)` |
| 4 | `Z` | `cmd_line` | `lpwCmdLine = BeaconDataExtract(...)` |
| 5 | `i` | `block_dll` (int) | `BlockDllPolicy = BeaconDataInt(...)` |
| 6 | `i` | `cfg_disable` (int) | `DisableCfg = BeaconDataInt(...)` |
| 7 | `i` | `use_rwx` (int) | `UseRWX = BeaconDataInt(...)` |
| 8 | `i` | `exec_method` (int) | `MemExec = BeaconDataInt(...)` |
| 9 | `b` | `shellcode` | `Shellcode = BeaconDataExtract(...)` |

Execution method mapping (CNA string -> `MemExec`):
- `Hijack RIP Direct` -> `0`
- `Hijack RIP Jmp Rax` -> `1`
- `Hijack RIP Jmp Rbx` -> `2`
- `Hijack RIP Callback` -> `3`

Unknown execution method values are blocked before execution dispatch.

## Contract-Regression Check (TEST-02)

Run the structured checker to verify CNA packing order/types still match BOF parser extraction:

```bash
bash scripts/check_pack_contract.sh
```

Machine-readable mode for CI/automation:

```bash
bash scripts/check_pack_contract.sh --json
```

Expected success output:
```text
[PASS] CNA packing schema matches BOF parser extraction order/types
[PASS] schema: ZZZZiiiib (9 fields)
```

Mismatch triage flow:
1. Check reported `position` in checker output.
2. Compare `bof_pack(..., "ZZZZiiiib", ...)` in `BOF_spawn.cna` with corresponding `BeaconDataExtract`/`BeaconDataInt` call order in `Src/Bof.c::go()`.
3. Update CNA and BOF parsing in lockstep, then re-run `bash scripts/check_pack_contract.sh`.

## Shellcode Execution Methods

### 1. Direct RIP Hijacking
```
Original State:          Modified State:
┌──────────────┐        ┌──────────────┐
│ RIP: ntdll   │   →    │ RIP: 0x7FFE  │ (shellcode)
│ RAX: ...     │        │ RAX: ...     │
└──────────────┘        └──────────────┘
```
**Advantage**: Simple and reliable.  
**Detection Risk**: High - RIP directly pointing to non-module memory is easily detected by EDR thread scanning.

### 2. JMP RAX Gadget
```
Step 1: Find Gadget               Step 2: Set Context
┌──────────────────┐             ┌──────────────────┐
│ Scan ntdll.dll   │             │ RIP: ntdll!gadget│ (0xFF 0xE0)
│ for 0xFF 0xE0    │    →        │ RAX: shellcode   │
└──────────────────┘             └──────────────────┘
```
**Advantage**: RIP points to legitimate ntdll.dll, more stealthy than direct hijacking.  
**Detection Risk**: Medium - Suspicious RAX value and unusual gadget execution may trigger heuristics.

### 3. JMP RBX Gadget
```
Step 1: Find Gadget               Step 2: Set Context
┌──────────────────┐             ┌──────────────────┐
│ Scan ntdll.dll   │             │ RIP: ntdll!gadget│ (0xFF 0xE3)
│ for 0xFF 0xE3    │    →        │ RBX: shellcode   │
└──────────────────┘             └──────────────────┘
```
**Advantage**: Similar to JMP RAX, RIP remains in legitimate module space.  
**Detection Risk**: Medium - Same as JMP RAX, slightly different register makes detection signatures less common.

### 4. Callback Function Hijacking
```
EnumResourceTypesW(hModule, lpEnumFunc, lParam)
                              ↓
                    RCX = NULL
                    RDX = shellcode address
                    R8  = NULL
```
**Advantage**: Leverages legitimate callback mechanism, appears as normal Windows API usage.  
**Detection Risk**: Low-Medium - Requires CFG disabled. NULL module handle and callback validation may trigger alerts.

## Recommended Execution Method Matrix (DOCS-01)

Use the same operator policy language for each method: `prereq`, `detection risk trade-off`, and `recommended` posture.

| Method | prereq / gate | detection risk trade-off | recommended posture |
|---|---|---|---|
| Hijack RIP Direct | No gadget lookup; standard spawn/injection prereq set | Highest thread-context visibility because RIP points to non-module memory | **Recommended default baseline** for first-run validation and reproducible triage |
| Hijack RIP Jmp Rax | Gadget `JMP RAX` must resolve in `ntdll.dll` | Lower direct-RIP signal, but gadget/register behavior can trigger heuristics | Use when Direct baseline is known-good and you need a module-backed RIP path |
| Hijack RIP Jmp Rbx | Gadget `JMP RBX` must resolve in `ntdll.dll` | Similar to Jmp Rax with alternate register/gadget signature trade-off | Use as alternate gadget path after Direct baseline and Jmp Rax comparison |
| Hijack RIP Callback | Callback mode selected and CFG-disable enabled, otherwise blocked by precondition gate | Callback dispatch can appear legitimate but CFG policy manipulation is high-signal | Use only when callback-specific constraints require it; treat as controlled opt-in path |

## Mitigation Policies: Benefits and Risks

### Disable CFG (Control Flow Guard)
**Purpose**: Required for callback function execution method. CFG validates indirect call targets and would block shellcode execution.  
**Risk**: Disabling CFG is a strong indicator of malicious intent. Very few legitimate applications disable CFG during process creation.  
**Recommendation**: Only enable when using callback execution method.

### Block DLL Policy
**Purpose**: Prevents loading of non-Microsoft-signed DLLs, blocking security product hooks and monitoring DLLs from being injected.  
**Risk**: Unusual mitigation policy for typical processes. May trigger EDR alerts on process creation with this attribute.  
**Recommendation**: Use selectively - effective against DLL-based EDR hooks but creates detection artifact.

### RWX Memory Allocation
**Purpose**: Simplifies injection by allocating memory with Read-Write-Execute permissions directly.  
**Risk**: RWX memory is a critical indicator for memory scanners. 
**Recommendation**: Use RW→RX transition instead (default). Allocate as RW, write shellcode, then change to RX.

## Detection Vectors

### ETW-TI (Threat Intelligence) Callbacks

**NtGetContextThread / NtSetContextThread**:
- ETW-TI provides callbacks for thread context manipulation via `EtwTiLogReadWriteVm`
- Modifying RIP register on suspended threads is a strong injection indicator
- Detection: Context modifications are logged with thread ID, process ID, and modified registers

### Kernel Callbacks

**Process Creation (PsSetCreateProcessNotifyRoutine)**:
- `NtCreateUserProcess` triggers kernel callbacks visible to EDR drivers
- Suspended process creation followed by cross-process operations is suspicious
- Detection: Process creation with unusual parent (PPID spoofing), mitigation policies (BlockDLL, CFG disabled)

**Memory Allocation**:
- RWX memory allocations are monitored at kernel level via process callbacks
- Even without ETW-TI, kernel drivers can detect RWX via `MmProtectMdlSystemAddress` events
- Detection: Unbacked executable memory (not mapped from disk file)

## Evasion Techniques

| Technique | Bypasses |
|-----------|----------|
| **Indirect Syscalls** | Userland API hooks (EDR/AV) |
| **Draugr Stack Spoofing** | Call stack inspection tools |
| **PPID Spoofing** | Process tree analysis |
| **Gadget-based Execution** | Direct RIP detection |

## Usage

### Load Script
```
Cobalt Strike → Script Manager → Load → BOF_spawn.cna
```

### Configure
```
Menu: Additionals postex → Spawn Process Config
```

### Execute
```
beacon> spawn_beacon <listener_name>
beacon> spawn_shellcode /path/to/payload.bin
```

## Compilation

With Dockerfile:

```bash
sudo docker build -t ubuntu-gcc-13 .
sudo docker run --rm -it -v "$PWD":/work -w /work ubuntu-gcc-13:latest make
 ```

Or, if you have nasm, make, and mingw-w64 (compatible with gcc-14) on your system
```
make
```

Output: `Bin/bof.o`

## Build Verification (TEST-01)

Run the canonical build check script before runtime testing:

```bash
bash scripts/check_bof_build.sh --local --container --strict
```

Mode-specific checks:

```bash
# Local toolchain only
bash scripts/check_bof_build.sh --local --strict

# Containerized toolchain only
bash scripts/check_bof_build.sh --container --strict
```

What this validates:
- Required command/tooling preflight for the selected mode(s).
- `Bin/bof.o` is generated and non-empty after each build path.
- Strict mode freshness checks ensure artifact timestamps advance per build.

Expected success output:
```text
[PASS] local build produced Bin/bof.o (... bytes, mtime ...)
[PASS] container build produced Bin/bof.o (... bytes, mtime ...)
```

Expected failure style:
```text
[FAIL] <one-line cause> | next step: <fix action>
```

## Recommended Operator Flow

Use this sequence to keep method selection, validation, and troubleshooting coherent:

1. Start with **Safe Defaults (DOCS-01)** and choose method posture from **Recommended Execution Method Matrix (DOCS-01)**.
2. Run deterministic checks in **Execution Validation (TEST-03)**:
   - [`docs/execution-validation-matrix.md`](docs/execution-validation-matrix.md)
3. If any failure signal appears, go directly to **Troubleshooting (DOCS-02)**:
   - [`docs/ntstatus-troubleshooting.md`](docs/ntstatus-troubleshooting.md)

This keeps operator flow as: `method choice -> validation -> triage`.

## Execution Validation (TEST-03)

Run method validation in deterministic order (Direct baseline first, then gadget paths, callback last):

1. Set `Execution Method` to `Hijack RIP Direct`
2. Run `spawn_beacon <listener>` (or `spawn_shellcode <file>`)
3. Repeat for `Hijack RIP Jmp Rax`, `Hijack RIP Jmp Rbx`, and `Hijack RIP Callback`

Full matrix (prereqs, expected signals, and triage flow):
- [`docs/execution-validation-matrix.md`](docs/execution-validation-matrix.md)

Validation signal contract:
- **success signal:** BOF run completes and method-specific path executes without stage errors
- **failure signal:** one or more precondition/stage errors (for example callback gate, gadget lookup, context set, resume stage)

## Troubleshooting (DOCS-02)

Quick first-line NTSTATUS and stage triage:

- `invalid execution method` -> select a supported execution method, then retry
- `callback blocked (cfg-disable is off)` -> enable CFG-disable, then retry callback mode
- `NtCreateUserProcess` / `NtGetContextThread` / `NtSetContextThread` / `NtResumeProcess` failures -> capture exact stage and rerun Direct baseline method first

Full troubleshooting table and fail-closed unknown-code flow:
- [`docs/ntstatus-troubleshooting.md`](docs/ntstatus-troubleshooting.md)

Output style reminder:
- Treat each failure as `cause | next step` and keep triage notes concise.

## Limitations

- **CET (Control-flow Enforcement Technology)**: Synthetic stack frames may trigger violations in CET-enabled processes
- **Architecture**: x64 only - no x86 support
- **Kernel Visibility**: Process creation still visible to kernel callbacks despite userland evasion

## Credit

- **RastaMouse** : https://offensivedefence.co.uk/authors/rastamouse/
- **Capt. Meelo**: https://captmeelo.com/redteam/maldev/2022/05/10/ntcreateuserprocess.html
- **Sektor7**: https://institute.sektor7.net/view/courses/rto-win-evasion
