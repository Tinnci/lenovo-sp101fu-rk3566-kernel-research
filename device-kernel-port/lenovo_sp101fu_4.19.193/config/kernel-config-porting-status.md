# SP101FU kernel config porting status

## Practical answer

Use the live `/proc/config.gz` as the truth source, but do not treat every line
as something that can be enabled in the public Rockchip tree. Kconfig can only
enable code that exists in the selected source tree.

The current public Rockchip 4.19 checkout can preserve the generic RK3566,
RK817, BCMDHD, CPUFreq/devfreq, Mali/Bifrost baseline, and Android kernel
settings. It cannot preserve the Lenovo/HT board-specific E Ink, touch, pen,
and sensor symbols without importing the missing vendor driver sources and
Kconfig entries.

## Files created

- `sp101fu-live-required.config`: full machine-required intent, including
  missing vendor symbols.
- `sp101fu-public-4.19-supported.config`: subset verified to survive
  `olddefconfig` in the current public Rockchip 4.19 tree.
- `validation-public-supported.txt`: public subset validation.
- `validation-live-required.txt`: full required fragment validation.

## Validation result

The public-supported fragment survives `olddefconfig` with no dropped requested
symbols.

The full live-required fragment drops these requested symbols:

- `CONFIG_MALI_MEMORY_GROUP_MANAGER`
- `CONFIG_MALI_MIDGARD_FOR_ANDROID`
- `CONFIG_MALI_BIFROST_FOR_ANDROID`
- `CONFIG_HTFY_EBC`
- `CONFIG_PMIC_EBC_TPS65185`
- `CONFIG_PMIC_EBC_SY7636A`
- `CONFIG_HTFY_DUMP`
- `CONFIG_HTFY_DEBUG`
- `CONFIG_TOUCHSCREEN_GOODIX_GTX8`
- `CONFIG_TOUCHSCREEN_HUION_PANELS`
- `CONFIG_TOUCHSCREEN_HDX8801`
- `CONFIG_I2C_HID_WACOM_9013`
- `CONFIG_I2C_HID_WACOM_10S12MI`
- `CONFIG_LS_STK3x1x`
- `CONFIG_LS_LTR578`
- `CONFIG_AW9610X_SAR`
- `CONFIG_HS_WH2506D`

This matches the public-source research: `rk3566-rk817-eink-w103` is the closest
reference line, but it is not the Lenovo BOE DVT1 board.

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

## Recommended porting sequence

1. Keep using the live config as the base `.config`.
2. Merge `sp101fu-public-4.19-supported.config` for public Rockchip builds.
3. Derive a Lenovo board DTS from `live-fdt.dts`, not directly from `w103`.
4. Import or recreate missing drivers before expecting
   `sp101fu-live-required.config` to survive Kconfig:
   HTFY EBC, TPS65185/SY7636A EBC PMIC glue, Wacom 10S12MI, Goodix GTX8,
   Huion/HDX, WH2506D, LTR578/STK3x1x/AW9610X.
5. Use Android Clang 11/LLD 11 if trying to reproduce the vendor kernel ABI.
6. If preserving `bcmdhd.ko`, keep `UTS_RELEASE`, `PREEMPT`, `MODVERSIONS`, and
   exported symbol CRCs compatible, or rebuild BCMDHD from source.
