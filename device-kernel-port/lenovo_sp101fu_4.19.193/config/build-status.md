# SP101FU kernel build status

This note records the state of building an SP101FU kernel from an integrated
vendor source tree. It supersedes the earlier assumption that the public
Rockchip 4.19 tree alone could not produce a working kernel.

## Result: self-compilable baseline achieved

A complete arm64 kernel `Image` now builds from an integrated HTFY/Rockchip 4.19
source tree using a GCC cross toolchain. This is the self-compilable baseline
the project targets, and the starting point for trimming unused hardware and,
later, migrating to newer kernels.

HARDWARE TEST RESULT: the build completes and the image has a valid arm64 boot
header. A non-destructive `fastboot boot` test image was accepted by the
bootloader, but the device returned to the stock `4.19.193` kernel rather than
running the integrated `4.19.232` test kernel. "It builds" is confirmed; "it
boots as the running kernel" is not yet confirmed. See `boot-test-result.md`.

Artifacts produced by the last successful build:

- `arch/arm64/boot/Image` — arm64 kernel image with valid `ARMd` boot magic,
  31,367,176 bytes after the Huion/HDX trim rebuild.
- `vmlinux` — `Linux version 4.19.232`, built with GCC 15.2.0, GNU ld 2.46.
- `arch/arm64/boot/dts/rockchip/rk3566-lenovo-sp101fu.dtb` — 122,427 bytes.
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

## GCC build fixes

1. Warning wall. The tree wraps the compiler with `scripts/gcc-wrapper.py`,
   which turns any non-whitelisted GCC warning into
   `error, forbidden warning:<file:line>` and aborts. GCC 15 against this 4.19
   tree raises warnings the vendor's Clang 11 whitelist never saw, mainly
   `-Warray-compare` (e.g. `extable.c`) and `-Waddress` (e.g. `profile.c`,
   `net/core/dev.c`). This is now hardened in the integrated build trees'
   `arch/arm64/Makefile` via `cc-disable-warning`, so supported GCC versions add
   the needed `-Wno-*` flags without relying on external `KCFLAGS`.

2. Link error in `huiontablet`. `huion_tool.c` referenced the bare
   `i2c_connect_client` symbol exported by the `gt9xx` driver, but the build
   uses `GOODIX_GTX8` (not `GT9XX`), so the symbol was undefined and produced
   AArch64 "dangerous relocation" link errors. Fixed by renaming the reference
   to the driver-local `i2c_connect_client_hn` defined in `huiontablet.c`.

## Current trim state

- Goodix GTX8/GT9886 touch remains enabled.
- Huion (`huion@8`) and HDX8801 (`hdx8801@11`) are disabled in the SP101FU DTS.
- `CONFIG_TOUCHSCREEN_HUION_PANELS` and `CONFIG_TOUCHSCREEN_HDX8801` are disabled
  in `sp101fu-live-required.config` and in the active build output `.config`.
- `olddefconfig` preserves that trim state in
  `/private/tmp/rk3566_kernel_build/out-sp101fu-4.19-htfy/.config`.
- A clean `make Image dtbs` rebuild without `KCFLAGS` completed after the trim;
  the active output contains Goodix GTX8 objects and no Huion/HDX touchscreen
  objects.
- The keep/trim rationale is tracked in
  `../compare/hardware-trim-audit.md`; it is based on the already captured live
  DTB, `/proc/config.gz`, root `dmesg`, `getevent -pl`, and module evidence.

## Rebuild notes

The trim rebuild log is
`logs/trim-rebuild-no-kcflags.log`. It contains host-tool/OpenSSL warnings,
pre-existing DTS warnings for unrelated RK3566 EVB DTBs, repeated ImgTec Rogue
`-Wsizeof-pointer-div` warnings, and GNU ld RWX segment warnings for
`vmlinux`. No `gcc-wrapper.py` `forbidden warning`, undefined reference,
dangerous relocation, or make failure was present in the checked log.

## Toolchain choice

Earlier notes recommended reproducing the vendor build with Android Clang 11 /
LLD 11 to match the running-kernel ABI. That is still the right approach only if
the goal is byte/ABI parity with the stock kernel. For this project's actual
goal — an independently maintainable, self-compilable baseline that migrates
forward — building with GCC is acceptable and is the path in use. The live
kernel's `CONFIG_CC_IS_CLANG`/`CONFIG_CLANG_VERSION` symbols are vendor-build
identity and are not targets to reproduce.

## Known follow-ups

- Investigate why the temporary `fastboot boot` image falls back to the stock
  kernel before considering any inactive-slot flash.
- Continue trimming config and DTS only where the existing live evidence or a
  new rooted ADB capture proves hardware is absent or an alternate probe is
  unused. Use `../compare/hardware-trim-audit.md` as the decision log.
- The version string is `4.19.232` from the integrated tree, while the live
  device reports `4.19.193`. Both are 4.19-stable; the difference is not a
  blocker for this baseline.
