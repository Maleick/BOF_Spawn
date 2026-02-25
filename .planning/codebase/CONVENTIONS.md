# Coding Conventions

**Analysis Date:** 2026-02-25

## Naming Patterns

**Files:**
- Mixed PascalCase naming in `Src/` (`Bof.c`, `Draugr.c`, `Native.h`, `Vulcan.h`)
- Script file naming reflects function (`BOF_spawn.cna`)
- Artifact output name is lowercase (`Bin/bof.o`)

**Functions:**
- Public/helper functions tend toward PascalCase or descriptive C-style names (`SpawnAndRun`, `FindGadget`, `DraugrResolveSyscall`)
- Wrapper/helper names include subsystem prefix (`Draugr*`, `GetProcessIdWithNameW`)
- Entrypoint is fixed BOF convention: `go`

**Variables:**
- Windows-style prefixes are common (`lpw*`, `dw*`, `h*`, `p*`)
- Globals use PascalCase identifiers (`VxTable`, `SyntheticStackframe`)
- Constants/macros are uppercase (`DRAUGR_SYSCALL`, `MODULE_SIZE`)

**Types:**
- Struct/typedef names are uppercase snake or Pascal-like (`VX_TABLE`, `SYNTHETIC_STACK_FRAME`, `PRM`)
- Enum values are uppercase underscore (`HIJACK_RIP_DIRECT`)

## Code Style

**Formatting:**
- Tabs are widely used in C source/header alignment
- Brace style is mixed but predominantly K&R/C hybrid in `Src/Bof.c` and `Src/Draugr.c`
- Extensive Doxygen-style function headers (`@brief`, `@param`, `@return`)
- No repository formatter config found (`.clang-format`, `.editorconfig`, etc.)

**Linting:**
- No linter configuration present for C/CNA code
- Warning suppression flags in `Makefile` imply permissive compile posture (`-w`, `-Wno-*`)

## Import Organization

**C Includes:**
1. System headers first (`<windows.h>`, `<tlhelp32.h>`)
2. Local project headers next (`"Native.h"`, `"Macros.h"`, etc.)
3. API aliasing/import macros centralized in `Src/Bofdefs.h`

**Script Organization:**
- `BOF_spawn.cna` groups code by functional blocks with large section comments
- Helper functions (`bool_to_int`, `get_bof_path`) are defined before aliases

## Error Handling

**Patterns:**
- NTSTATUS error checks using `NT_ERROR(Status)` after each critical syscall/API step
- Immediate return on failure (fail-fast style)
- Error visibility through `BeaconPrintf(CALLBACK_ERROR, ...)` and `berror(...)`

**Observations:**
- Happy path focuses on completion over cleanup normalization
- Multiple early returns in `SpawnAndRun()` can skip cleanup for allocated resources/handles

## Logging

**Framework:**
- Beacon output APIs only (`BeaconPrintf`) from C side
- Console output APIs in CNA (`println`, `berror`)

**Patterns:**
- Status and failure-oriented logging
- Optional debug prints are often present but commented out in `Src/Bof.c`

## Comments

**When Commented:**
- High-level flow blocks in `Src/Bof.c` and `Src/Stub.s`
- Detailed purpose/contract comments around most exported functions
- Section boundaries in CNA and assembly files for readability

**Style:**
- "Why + what" style in longer header comments
- In-line comments for sensitive register/stack operations in `Src/Stub.s`

## Function Design

**Shape:**
- Large orchestration functions with explicit step-by-step phases (`SpawnAndRun`)
- Smaller focused helpers for byte matching, gadget search, section parsing
- Heavy use of Windows-native types and explicit pointer casts

**Parameters/Returns:**
- Windows calling conventions and pointer-heavy signatures
- Boolean success for helpers, NTSTATUS for orchestration path

## Module Design

**Separation:**
- `Src/Bof.c`: operator payload execution pipeline
- `Src/Draugr.c`: syscall resolution and spoof-call infrastructure
- `Src/Stub.s`: assembly-only trampoline implementation
- `Src/*.h`: type definitions/import declarations/macro utilities

**Exports:**
- No barrel/export aggregation pattern; direct header includes
- API shape is flat and tightly coupled to Windows/BOF environment

---

*Convention analysis: 2026-02-25*
*Update when style patterns or module boundaries change*
