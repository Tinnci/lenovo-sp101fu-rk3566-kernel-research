# Lenovo SP101FU RK3566 Kernel Research

Public research notes for rebuilding and porting a Linux/Android kernel for the
Lenovo SP101FU / Lenovo Smart Paper / Louvre RK3566 E Ink tablet.

This repository intentionally does not publish Lenovo, Rockchip, or vendor
firmware blobs. It contains only small text artifacts needed to track the kernel
porting work: analysis notes, config fragments, validation reports, a collection
script, and a path/hash inventory of blobs kept outside the public repo.

## Current Finding

The closest public board baseline found so far is `rk3566-rk817-eink-w103`, but
the live tablet is not a byte-for-byte match. The device reports:

- board model: `Rockchip RK3566 EINK Boe 10.3 DVT1 Board II`
- kernel: `4.19.193`
- compiler: Android Clang 11 / LLD 11
- shared baseline: `compatible = "rockchip,rk3566-rk817-eink", "rockchip,rk3566"`

The public Rockchip 4.19 tree does not contain several Lenovo/HT board-specific
drivers needed by the live DTB and kernel config, including the HTFY EBC stack,
TPS65185/SY7636A EBC PMIC glue, Goodix GTX8/GT9886 touch, Wacom 10S12MI pen,
WH2506D Hall, Huion/HDX input pieces, sensors, and Goodix fingerprint support.

## Published Materials

- `device-kernel-port/lenovo_sp101fu_4.19.193/compare/dtb-and-config-comparison.md`
  summarizes the live DTB and kernel config against public Rockchip E Ink
  candidates.
- `device-kernel-port/lenovo_sp101fu_4.19.193/config/README.md` documents the
  config workflow from the rooted device to public Rockchip 4.19 builds.
- `device-kernel-port/lenovo_sp101fu_4.19.193/config/sp101fu-live-required.config`
  tracks the live machine-required config intent, including missing vendor
  symbols.
- `device-kernel-port/lenovo_sp101fu_4.19.193/config/sp101fu-public-4.19-supported.config`
  is the subset verified to survive `olddefconfig` in the current public
  Rockchip 4.19 checkout.
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
