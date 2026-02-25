# Technology Stack

**Analysis Date:** 2026-02-25

## Languages

**Primary:**
- C (x64 Windows-focused) - Core BOF implementation in `Src/Bof.c` and `Src/Draugr.c`

**Secondary:**
- x86-64 Assembly (NASM syntax) - Stack spoof trampoline in `Src/Stub.s`
- Aggressor Script (Cobalt Strike CNA) - Operator interface in `BOF_spawn.cna`
- Markdown - Operator/developer docs in `README.md`

## Runtime

**Target Runtime Environment:**
- Cobalt Strike Beacon (x64) loads and executes `Bin/bof.o`
- Windows userland and native NT APIs resolved at runtime through `ntdll`/`kernel32`/`shlwapi`

**Build Runtime Environment:**
- MinGW-w64 cross-compile toolchain (`x86_64-w64-mingw32-gcc`, `x86_64-w64-mingw32-ld`)
- NASM for assembling `Src/Stub.s`
- Optional Dockerized build environment from `Dockerfile`

**Package Manager:**
- None for project source
- System package managers only (APT inside Docker, host package manager outside Docker)

## Frameworks

**Core:**
- Cobalt Strike BOF + Beacon API surface via `Src/Beacon.h`
- Internal Draugr call-spoofing + indirect syscall layer in `Src/Draugr.c` and `Src/Macros.h`

**Testing:**
- No automated test framework present in repository

**Build/Dev:**
- `make` target `spawn_bof` defined in `Makefile`
- Docker image definition in `Dockerfile` for repeatable toolchain provisioning

## Key Dependencies

**Critical:**
- Windows Native API declarations in `Src/Native.h` - required for `NtCreateUserProcess` and memory/thread syscalls
- BOF import definitions in `Src/Bofdefs.h` - dynamic imports and function aliasing for BOF compatibility
- Syscall lookup table contracts in `Src/VxTable.h` - central syscall metadata used by `DRAUGR_SYSCALL`

**Infrastructure:**
- `gcc-mingw-w64-x86-64` - compiles C objects for BOF payload
- `nasm` - builds assembly trampoline object
- `ld -r` - links object files into relocatable `Bin/bof.o`

## Configuration

**Runtime/Operator Configuration:**
- Default process spawn and execution settings declared in `BOF_spawn.cna`
- Runtime options packed from CNA to BOF entry `go()` as `ZZZZiiiib` in `BOF_spawn.cna`

**Build Configuration:**
- Compiler and linker flags in `Makefile` (`-Os`, `-m64`, `-masm=intel`, warning suppressions)
- Dockerized dependency pins in `Dockerfile`

## Platform Requirements

**Development:**
- Linux/macOS/WSL host with MinGW-w64 + NASM + Make, or Docker
- Git repository with writable `Bin/` and `Bin/temp/`

**Production/Operational:**
- x64 Beacon context in Cobalt Strike
- Target systems are Windows x64 processes for injection path
- No x86 support in current implementation

---

*Stack analysis: 2026-02-25*
*Update after compiler/toolchain/runtime changes*
