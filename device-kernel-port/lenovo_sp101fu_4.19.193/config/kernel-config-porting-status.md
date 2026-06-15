# SP101FU kernel config porting status

## Practical answer

Use the live `/proc/config.gz` as the truth source, but do not treat every line
as something that can be enabled in the public Rockchip tree. Kconfig can only
enable code that exists in the selected source tree.

The *public* Rockchip 4.19 checkout can preserve the generic RK3566, RK817,
BCMDHD, CPUFreq/devfreq, Mali/Bifrost baseline, and Android kernel settings. It
cannot preserve the Lenovo/HT board-specific E Ink, touch, pen, and sensor
symbols on its own. Those vendor drivers have since been recovered and
integrated into the build tree, which now compiles to a complete kernel Image; see
`build-status.md`.

## Files created

- `sp101fu-live-required.config`: tailored machine-required intent for the
  integrated tree, including the current Goodix-enabled, Huion/HDX-disabled
  trim state.
- `sp101fu-public-4.19-supported.config`: subset verified to survive
  `olddefconfig` in the current public Rockchip 4.19 tree.
- `validation-public-supported.txt`: public subset validation.
- `validation-live-required.txt`: integrated-tree required fragment and rebuild
  validation.

## Validation result

The public-supported fragment survives `olddefconfig` with no dropped requested
symbols.

In the public Rockchip-only checkout, the original full live-required fragment
dropped these vendor-board symbols because the source was not present there:

- `CONFIG_MALI_MEMORY_GROUP_MANAGER`
- `CONFIG_MALI_MIDGARD_FOR_ANDROID`
- `CONFIG_MALI_BIFROST_FOR_ANDROID`
- `CONFIG_HTFY_EBC`
- `CONFIG_PMIC_EBC_TPS65185`
- `CONFIG_PMIC_EBC_SY7636A`
- `CONFIG_HTFY_DUMP`
- `CONFIG_HTFY_DEBUG`
- `CONFIG_TOUCHSCREEN_GOODIX_GTX8`
- `CONFIG_I2C_HID_WACOM_9013`
- `CONFIG_I2C_HID_WACOM_10S12MI`
- `CONFIG_LS_STK3x1x`
- `CONFIG_LS_LTR578`
- `CONFIG_AW9610X_SAR`
- `CONFIG_HS_WH2506D`

This matches the public-source research: `rk3566-rk817-eink-w103` is the closest
reference line, but it is not the Lenovo BOE DVT1 board.

The current integrated HTFY/Rockchip build tree is different from that
public-only validation target: the recovered vendor driver set is integrated,
and the tailored SP101FU fragment now intentionally disables the vendor
multi-panel Huion/HDX touchscreen drivers while keeping Goodix GTX8 enabled.
`olddefconfig` preserves that trimmed state, and a clean rebuild without
`KCFLAGS` produces `Image` and `rk3566-lenovo-sp101fu.dtb`; see
`validation-live-required.txt` and `build-status.md`.

The vendor `/proc/config.gz` also enables reference-platform camera and
fingerprint options, but this SP101FU hardware has neither. The tailored build
keeps fingerprint, UVC camera, Rockchip CIF, RKISP, and RK628 CSI disabled.

## Root evidence collected

Root collection produced:

- `../root-evidence/sp101fu-root-evidence.tar`
- `../root-evidence/sp101fu-vendor-blobs.tar`
- `../root-evidence/manifests/rootfs-files.tsv`
- `../root-evidence/manifests/key-blobs.md`

Key runtime facts:

- `getevent -pl` confirms `goodix_ts` touch max `1404x1872`.
- `getevent -pl` confirms `Wacom Pencil` max `20966x15725`, pressure `4095`.
- `dmesg` confirms `htfy_eink_probe`, version `V2.1.2-20230407`.
- `dmesg` confirms `hall_wh2506d_probe success`.
- `dmesg` confirms `papyrus_probe_sy7636a`.
- `dmesg` confirms Goodix GTX8 tries `goodix_cfg_group.bin`.
- `/proc/modules` shows only `bcmdhd` as a loaded external module.
- `/sys/module` exposes built-in or loaded module state for `bifrost_kbase`,
  `htfy_dbg`, `mali`, `wacom`, and `wacom_10s12mi`.

Key blobs preserved:

- `/vendor/lib/modules/bcmdhd.ko`
- `/vendor/lib/modules/mali_kbase.ko`
- `/vendor/etc/firmware/W9021_2241.hex`
- `/vendor/etc/firmware/goodix_cfg_group.bin`
- `/vendor/etc/firmware/goodix_firmware.bin`
- `/vendor/etc/firmware/aw9610x_0.bin`
- Wi-Fi/BT firmware and NVRAM files under `/vendor/etc/firmware`

Module compatibility note:

- `bcmdhd.ko` has `vermagic=4.19.193 SMP preempt mod_unload modversions aarch64`.
- `mali_kbase.ko` has `vermagic=4.19.161 SMP preempt mod_unload modversions aarch64`.
- Since `/proc/modules` only lists `bcmdhd`, do not assume the vendor
  `mali_kbase.ko` file is the active GPU driver on the running system.

## Porting sequence

1. Keep using the live config as the base `.config`.
2. Merge `sp101fu-public-4.19-supported.config` for public Rockchip builds.
3. Derive a Lenovo board DTS from `live-fdt.dts`, not directly from `w103`.
4. DONE: the missing vendor drivers (HTFY EBC, TPS65185/SY7636A EBC PMIC glue,
   Wacom 10S12MI, Goodix GTX8, WH2506D, LTR578/STK3x1x/AW9610X, plus optional
   Huion/HDX source candidates) have been integrated into the build tree, so
   `sp101fu-live-required.config` now
   survives Kconfig and the tree builds a complete kernel Image (see `build-status.md`).
5. The baseline builds with GCC. Android Clang 11/LLD 11 would only be needed
   for byte/ABI parity with the stock kernel, which is not the goal.
6. If preserving `bcmdhd.ko`, keep `UTS_RELEASE`, `PREEMPT`, `MODVERSIONS`, and
   exported symbol CRCs compatible, or rebuild BCMDHD from source.
7. DONE: trim config and DTS to hardware actually present for the first pass:
   camera, fingerprint, Huion touch, and HDX8801 touch are disabled while
   Goodix GT9886 remains enabled. Carry this trimmed baseline forward toward
   newer/mainline kernels. The `ht_ebc.px` binary blob remains the hard blocker
   for that forward port.
