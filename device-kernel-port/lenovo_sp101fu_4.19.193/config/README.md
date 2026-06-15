# SP101FU kernel config workflow

## What root can give us

Root on the tablet can give us the exact running kernel config and runtime hardware state:

- `/proc/config.gz`
- `/sys/firmware/fdt`
- `/proc/cmdline`
- `/proc/iomem`
- `/proc/interrupts`
- `/proc/modules`
- `/sys/bus/i2c/devices`
- `/sys/bus/spi/devices`
- `/sys/bus/platform/devices`
- `/sys/kernel/debug/gpio`
- `/sys/kernel/debug/pinctrl`
- `/sys/module/*/parameters`
- `/vendor/lib/modules`
- `/vendor/etc/firmware`

Root cannot reconstruct vendor C source code for drivers that were built into
the original kernel. Missing Kconfig symbols must be solved by finding/importing
vendor source or by keeping ABI-compatible vendor modules where possible.

## Recommended config method

Start from the live config, not from a generic Rockchip defconfig:

```sh
cp "/Users/driezy/yoga paper/device-kernel-port/lenovo_sp101fu_4.19.193/live-device/proc-config.config" \
  /private/tmp/rk3566_kernel_build/out-sp101fu-4.19/.config
```

Then normalize it against the selected source tree:

```sh
make -C /private/tmp/rk3566_kernel_build/rockchip-kernel-4.19 \
  O=/private/tmp/rk3566_kernel_build/out-sp101fu-4.19 \
  ARCH=arm64 olddefconfig
```

For the current public Rockchip 4.19 tree, merge the supported subset:

```sh
scripts/kconfig/merge_config.sh -m .config \
  "/Users/driezy/yoga paper/device-kernel-port/lenovo_sp101fu_4.19.193/config/sp101fu-public-4.19-supported.config"
make ARCH=arm64 olddefconfig
```

Note: this workspace path contains a space. The kernel `merge_config.sh` script
does not reliably handle that in every invocation. If it splits the path at
`/Users/driezy/yoga`, copy the fragment to a temporary path without spaces first,
for example `/private/tmp/rk3566_kernel_build/sp101fu-config-fragments/`.

In the integrated HTFY/Rockchip tree, merge the tailored live-required fragment:

```sh
scripts/kconfig/merge_config.sh -m .config \
  "/Users/driezy/yoga paper/device-kernel-port/lenovo_sp101fu_4.19.193/config/sp101fu-live-required.config"
make ARCH=arm64 olddefconfig
```

Any symbol that disappears after `olddefconfig` is not supported by the current
source tree. Treat it as a source/Kconfig gap, not as a config typo. In the
current integrated tree, `olddefconfig` preserves the SP101FU trim state:
Goodix GTX8 remains enabled while Huion/HDX touchscreen drivers remain disabled.

## Toolchain note

The live kernel was built with Android Clang 11 and LLD 11:

- `CONFIG_CC_IS_CLANG=y`
- `CONFIG_LD_IS_LLD=y`
- `CONFIG_CLANG_VERSION=110002`

These are vendor-build identity symbols, selected by the toolchain invocation;
do not hand-edit them. Matching them exactly only matters for byte/ABI parity
with the stock kernel, which is not this project's goal.

The self-compilable baseline builds with a GCC cross toolchain
(`aarch64-linux-gnu-gcc` 15) instead. Building 4.19 with GCC 15 requires
suppressing newer warnings that the vendor's Clang whitelist never saw, because
the tree's `scripts/gcc-wrapper.py` treats any non-whitelisted warning as a
fatal error. See `build-status.md` for the full build environment, the
`arch/arm64/Makefile` warning-wall hardening, and the huiontablet link fix.

## Vendor driver set (now integrated)

The stock *public* Rockchip 4.19 tree does not contain the full Lenovo/HT board
support required by the live DTB. The following symbols have no source in that
tree:

- `CONFIG_HTFY_EBC`
- `CONFIG_PMIC_EBC_TPS65185`
- `CONFIG_PMIC_EBC_SY7636A`
- `CONFIG_I2C_HID_WACOM_10S12MI`
- `CONFIG_TOUCHSCREEN_GOODIX_GTX8`
- `CONFIG_TOUCHSCREEN_HUION_PANELS`
- `CONFIG_TOUCHSCREEN_HDX8801`
- `CONFIG_LS_LTR578`
- `CONFIG_LS_STK3x1x`
- `CONFIG_AW9610X_SAR`
- `CONFIG_HS_WH2506D`

These have since been recovered (mostly from `Supernote-Ratta/kernel_Nomad_Manta`,
see `../drivers/source-recovery.md`) and integrated into the build tree, which
now compiles into a complete kernel Image (see `build-status.md`). The Huion and
HDX driver sources remain available as reference multi-panel support, but the
tailored SP101FU config disables them because this hardware uses Goodix GT9886.
The HTFY EBC core
ships as a prebuilt object (`ht_ebc.px`), so `CONFIG_HTFY_EBC` is satisfied by a
binary blob, not open source — this is the remaining blocker for forward porting
to 5.10/6.1/mainline.

The running vendor config contains some reference-platform residue. The SP101FU
hardware has no camera or fingerprint reader, so the tailored build keeps
fingerprint, UVC camera, Rockchip CIF, RKISP, and RK628 CSI disabled even if
they appear in `/proc/config.gz` or inherited candidate DTS files. The Huion and
HDX8801 touch panels are likewise vendor multi-panel residue (their probes fail
on this device, which uses Goodix GT9886) and are disabled in
`sp101fu-live-required.config` plus the SP101FU DTS.

## Validation status

Public Rockchip-only validation:

- `sp101fu-public-4.19-supported.config`: all requested symbols survive
  `olddefconfig`.
- The original full live-required fragment dropped Lenovo/HT vendor symbols
  there, confirming the public-only tree lacked the required source/Kconfig.

Integrated HTFY/Rockchip validation:

- `sp101fu-live-required.config`: the tailored fragment survives `olddefconfig`.
- `make Image dtbs` completes without external `KCFLAGS`.
- The output config keeps Goodix GTX8 enabled and Huion/HDX disabled.

Validation reports:

- `validation-public-supported.txt`
- `validation-live-required.txt`

## Runtime evidence from rooted device

Additional root evidence was collected with:

- `scripts/collect-root-evidence-device.sh`

Output:

- `../root-evidence/sp101fu-root-evidence.tar`
- `../root-evidence/sp101fu-vendor-blobs.tar`
- `../root-evidence/rootfs/vendor/lib/modules`
- `../root-evidence/rootfs/vendor/etc/firmware`
- `../root-evidence/manifests/rootfs-files.tsv`
- `../root-evidence/manifests/runtime-text-files.tsv`

Important blobs now preserved with original paths:

- `/vendor/lib/modules/bcmdhd.ko`
- `/vendor/lib/modules/mali_kbase.ko`
- `/vendor/etc/firmware/W9021_2241.hex`
- `/vendor/etc/firmware/goodix_cfg_group.bin`
- `/vendor/etc/firmware/goodix_firmware.bin`
- `/vendor/etc/firmware/aw9610x_0.bin`
- Broadcom/Cypress Wi-Fi/BT firmware and NVRAM files
