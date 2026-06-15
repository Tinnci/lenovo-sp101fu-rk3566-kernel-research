# Lenovo SP101FU RK3566 Kernel Research

Public research notes for rebuilding and porting a Linux/Android kernel for the
Lenovo SP101FU / Lenovo Smart Paper / Louvre RK3566 E Ink tablet.

This repository intentionally does not publish Lenovo, Rockchip, or vendor
firmware blobs. It contains only small text artifacts needed to track the kernel
porting work: analysis notes, config fragments, validation reports, a collection
script, and a path/hash inventory of blobs kept outside the public repo.

## Goal

Establish a **self-compilable 4.19 baseline** for the SP101FU that we control,
then trim hardware the device does not have and migrate forward toward newer
and eventually mainline kernels. The aim is a maintainable, independently
buildable kernel, not byte-for-byte parity with the Lenovo/HTFY vendor kernel.

## Current Finding

A complete arm64 kernel now builds from an integrated HTFY/Rockchip 4.19 source
tree (`4.19.232`, based on the `Supernote-Ratta/kernel_Nomad_Manta` HT E Ink
source set plus the recovered vendor drivers) using a GCC 15 cross toolchain.
See `device-kernel-port/lenovo_sp101fu_4.19.193/config/build-status.md` for the
build environment and the two GCC-specific issues that had to be solved. The
public Rockchip 4.19 tree alone is still not sufficient — it lacks the
Lenovo/HT board drivers (HTFY EBC stack, TPS65185/SY7636A EBC PMIC glue, Goodix
GTX8/GT9886 touch, Wacom 10S12MI pen, WH2506D Hall, Huion/HDX input, sensors) —
which is why the integrated vendor tree is used. The HTFY EBC core ships as a
prebuilt object (`ht_ebc.px`) and remains the hard blocker for forward porting.

The live tablet is not a byte-for-byte match for any public board. It reports:

- board model: `Rockchip RK3566 EINK Boe 10.3 DVT1 Board II`
- kernel: `4.19.193`
- vendor compiler: Android Clang 11 / LLD 11 (our baseline builds with GCC)
- shared baseline: `compatible = "rockchip,rk3566-rk817-eink", "rockchip,rk3566"`

Hardware confirmed absent on the live device (rooted ADB evidence) and disabled
in our config/DTS: camera (RKISP/CIF/CSI) and fingerprint reader. The Huion and
HDX8801 touch panels are vendor multi-panel residue whose probes fail on this
device (it uses Goodix GT9886); they are slated for trimming next.

## Published Materials

- `device-kernel-port/lenovo_sp101fu_4.19.193/compare/dtb-and-config-comparison.md`
  summarizes the live DTB and kernel config against public Rockchip E Ink
  candidates.
- `device-kernel-port/lenovo_sp101fu_4.19.193/config/README.md` documents the
  config workflow from the rooted device to public Rockchip 4.19 builds.
- `device-kernel-port/lenovo_sp101fu_4.19.193/config/build-status.md` records the
  self-compilable baseline: build environment, produced artifacts, and the
  GCC-specific issues (warning wall, huiontablet link fix) that were solved.
- `device-kernel-port/lenovo_sp101fu_4.19.193/config/sp101fu-live-required.config`
  tracks the live machine-required config intent, including missing vendor
  symbols.
- `device-kernel-port/lenovo_sp101fu_4.19.193/config/sp101fu-public-4.19-supported.config`
  is the subset verified to survive `olddefconfig` in the current public
  Rockchip 4.19 checkout.
- `device-kernel-port/lenovo_sp101fu_4.19.193/dts/rk3566-lenovo-sp101fu.dts`
  is a sanitized source DTS candidate derived from the live FDT and the public
  `rk3566-rk817-eink-w103` baseline.
- `device-kernel-port/lenovo_sp101fu_4.19.193/drivers/source-recovery.md`
  records public source and prebuilt-object matches for the missing Lenovo/HT
  driver stack.
- `device-kernel-port/lenovo_sp101fu_4.19.193/root-evidence/manifests/key-blobs.md`
  records original vendor blob paths, sizes, and hashes without publishing the
  blobs themselves.

## Excluded From Git

The `.gitignore` is an allowlist. These are deliberately excluded:

- full firmware packages and extracted firmware images
- boot, super, update, logo, loader, and partition images
- vendor firmware blobs and kernel modules
- rootfs captures and tar archives
- raw live FDT/DTB, raw bootargs, `getprop`, `dmesg`, and other runtime logs that
  may contain device identifiers
- external source checkouts and build volumes

Keep any future public additions small, text-only, and reviewed for serial
numbers, MAC addresses, bootargs, tokens, or proprietary binary content.
