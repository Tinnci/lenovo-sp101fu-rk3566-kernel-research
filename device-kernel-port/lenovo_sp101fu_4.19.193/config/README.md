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

After vendor driver sources are imported, merge the full required fragment:

```sh
scripts/kconfig/merge_config.sh -m .config \
  "/Users/driezy/yoga paper/device-kernel-port/lenovo_sp101fu_4.19.193/config/sp101fu-live-required.config"
make ARCH=arm64 olddefconfig
```

Any symbol that disappears after `olddefconfig` is not supported by the current
source tree. Treat it as a source/Kconfig gap, not as a config typo.

## Toolchain note

The live kernel was built with Android Clang 11 and LLD 11:

- `CONFIG_CC_IS_CLANG=y`
- `CONFIG_LD_IS_LLD=y`
- `CONFIG_CLANG_VERSION=110002`

Do not hand-edit generated compiler identity symbols. They are selected by the
toolchain invocation. To match the vendor build more closely, use an Android
Clang 11 based build instead of GCC. GCC 12/15 is useful for experiments, but it
changes generated config symbols and exposes extra warnings in this 4.19 tree.

## Current missing vendor driver set

The current public Rockchip 4.19 tree does not contain the full Lenovo/HT board
support required by the live DTB:

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
- `CONFIG_INPUT_FINGERPRINT`
- `CONFIG_GOODIX_FINGERPRINT`

Those are the highest-priority items to recover from firmware/source drops or
replace with compatible upstream/vendor alternatives.

## Validation in current public Rockchip 4.19 tree

Validated fragments:

- `sp101fu-public-4.19-supported.config`: all requested symbols survive
  `olddefconfig`.
- `sp101fu-live-required.config`: the Lenovo/HT vendor symbols are dropped by
  `olddefconfig`, confirming Kconfig/source support is missing.

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
