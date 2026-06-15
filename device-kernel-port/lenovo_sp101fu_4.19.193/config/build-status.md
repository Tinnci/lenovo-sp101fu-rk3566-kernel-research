# SP101FU kernel build status

This note records the state of building an SP101FU kernel from an integrated
vendor source tree. It supersedes the earlier assumption that the public
Rockchip 4.19 tree alone could not produce a working kernel.

## Result: self-compilable baseline achieved

A complete arm64 kernel `Image` now builds from an integrated HTFY/Rockchip 4.19
source tree using a GCC cross toolchain. This is the self-compilable baseline
the project targets, and the starting point for trimming unused hardware and,
later, migrating to newer kernels.

NOT YET VERIFIED ON HARDWARE: the build completes and the image has a valid
arm64 boot header, but it has not been flashed to or booted on the device. "It
builds" is confirmed; "it boots" is not.

Artifacts produced by the last successful build:

- `arch/arm64/boot/Image` — arm64 kernel image with valid `ARMd` boot magic, ~27 MB.
- `vmlinux` — `Linux version 4.19.232`, built with GCC 15.2.0, GNU ld 2.46.
- `arch/arm64/boot/dts/rockchip/rk3566-lenovo-sp101fu.dtb`.
- Loadable modules: `bcmdhd.ko` (Wi-Fi), Mali memory group manager.

The integrated tree includes the previously missing HTFY EBC stack and the
other vendor drivers tracked in `../drivers/source-recovery.md`, so
`ht_ebc.px` does link into `vmlinux` against the SP101FU DTS for this 4.19
baseline. The EBC core object remains a binary blob and is still the hard
blocker for any 5.10/6.1/mainline forward port (see source-recovery note).

## Build environment

- Source tree: integrated `rockchip-kernel-4.19-htfy-src` (4.19.232), based on
  the `Supernote-Ratta/kernel_Nomad_Manta` HT E Ink source set plus the
  recovered vendor drivers, kept in the local build volume (outside Git).
- Cross compiler: `aarch64-linux-gnu-gcc` 15.2.0 (GCC 12.5.0 also available).
- Build host: an OrbStack Linux machine (`rk-kernel`, Ubuntu/amd64); the source
  tree lives on a case-sensitive sparse image mounted into the machine over
  virtiofs. `ARCH=arm64`, out-of-tree `O=` build directory.

## Two failures that had to be solved to build with GCC

1. Warning wall. The tree wraps the compiler with `scripts/gcc-wrapper.py`,
   which turns any non-whitelisted GCC warning into
   `error, forbidden warning:<file:line>` and aborts. GCC 15 against this 4.19
   tree raises warnings the vendor's Clang 11 whitelist never saw, mainly
   `-Warray-compare` (e.g. `extable.c`) and `-Waddress` (e.g. `profile.c`,
   `net/core/dev.c`). The successful build suppressed these by injecting a list
   of `-Wno-*` flags through the `KCFLAGS` environment variable at `make` time.

   IMPORTANT: those `-Wno-*` flags are NOT yet persisted in the source tree's
   Makefiles. A clean build in a fresh environment that forgets the `KCFLAGS`
   string will hit the warning wall again. Hardening this into the tree
   (`arch/arm64/Makefile` or the wrapper) is required for a reproducible
   baseline.

2. Link error in `huiontablet`. `huion_tool.c` referenced the bare
   `i2c_connect_client` symbol exported by the `gt9xx` driver, but the build
   uses `GOODIX_GTX8` (not `GT9XX`), so the symbol was undefined and produced
   AArch64 "dangerous relocation" link errors. Fixed by renaming the reference
   to the driver-local `i2c_connect_client_hn` defined in `huiontablet.c`.

## Toolchain choice

Earlier notes recommended reproducing the vendor build with Android Clang 11 /
LLD 11 to match the running-kernel ABI. That is still the right approach only if
the goal is byte/ABI parity with the stock kernel. For this project's actual
goal — an independently maintainable, self-compilable baseline that migrates
forward — building with GCC is acceptable and is the path in use. The live
kernel's `CONFIG_CC_IS_CLANG`/`CONFIG_CLANG_VERSION` symbols are vendor-build
identity and are not targets to reproduce.

## Known follow-ups

- Persist the `-Wno-*` warning suppression into the source tree so a clean
  checkout builds without the external `KCFLAGS` string.
- Continue trimming config and DTS to hardware actually present on the device
  (see `../compare/dtb-and-config-comparison.md` for the live hardware map).
- The version string is `4.19.232` from the integrated tree, while the live
  device reports `4.19.193`. Both are 4.19-stable; the difference is not a
  blocker for this baseline.
