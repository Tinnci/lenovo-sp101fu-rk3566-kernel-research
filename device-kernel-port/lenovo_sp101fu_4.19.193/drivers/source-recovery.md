# SP101FU vendor driver source recovery

This note records public source matches for Lenovo SP101FU live-kernel symbols
that are missing from the current public Rockchip 4.19 tree.

The actual fetched files are kept out of Git under `vendor-source-candidates/`.
That local cache mirrors source location as:

```text
vendor-source-candidates/github.com/<owner>/<repo>/<commit>/<original-path>
```

`vendor-source-candidates/MANIFEST.tsv` records `repo`, `ref`, `commit`,
`source_path`, `local_path`, `bytes`, `sha256`, and `file_type` for each file.
Do not publish that cache without a separate license and binary review.

## Fetched public candidates

| Repository | Ref | Commit | Files | Bytes | Role |
| --- | --- | --- | ---: | ---: | --- |
| `Supernote-Ratta/kernel_Nomad_Manta` | `main` | `1d5ba6e2668c14e70ad7738ef0776931257d040a` | 101 | 3337536 | Primary RK3566 HT E Ink source match |
| `Supernote-Ratta/kernel_a6x_a5x` | `master` | `bdc77c244cd3d6318da3b1e8503dde087aadac08` | 41 | 1927157 | Older HT E Ink comparison |
| `armbian/linux-rockchip` | `rk-6.1-rkr5.1` | `95e85f6cb496c75807c5b16f158853578e7e7d1b` | 12 | 216647 | Newer GTX8 comparison |

The local cache is about 7 MB. Most files are C/Kconfig/Makefile/DTS text.
The important exception is `ht_ebc.px`.

## Status by live config symbol

| Live symbol | Status | Best current source |
| --- | --- | --- |
| `CONFIG_HTFY_EBC` | Partial, not full source | Supernote Kconfig and Makefile are public, but `ht_ebc.o` is made by copying prebuilt `ht_ebc.px`. |
| `CONFIG_PMIC_EBC_TPS65185` | Source found | `drivers/gpu/drm/rockchip/ht_eink/htfy_tps65185.c` in both Supernote trees. |
| `CONFIG_PMIC_EBC_SY7636A` | Source found | `drivers/gpu/drm/rockchip/ht_eink/htfy_sy7636a.c`; it contains the `papyrus_probe_sy7636a` log string seen on the live device. |
| `CONFIG_HTFY_DUMP` / `CONFIG_HTFY_DEBUG` | Source found around closed core | `htfy_dbg.c` plus Kconfig entries in Nomad/Manta. |
| `CONFIG_I2C_HID_WACOM_10S12MI` | Source found | `drivers/hid/i2c-hid/wacom_10s12mi.c` in Nomad/Manta, with Makefile/Kconfig integration. |
| `CONFIG_TOUCHSCREEN_GOODIX_GTX8` | Source found | `drivers/input/touchscreen/gtx8/` in Supernote and Armbian; both include `compatible = "goodix,gt9886"`. |
| `CONFIG_TOUCHSCREEN_HUION_PANELS` | Source found | `drivers/input/touchscreen/huiontablet/` in Nomad/Manta, with `compatible = "huion,hgtxx"`. |
| `CONFIG_TOUCHSCREEN_HDX8801` | Source found | `drivers/input/touchscreen/hdx8801.c` in Nomad/Manta, using driver name `hdx8801_touch`. |
| `CONFIG_HS_WH2506D` | Source found | `drivers/input/sensors/hall/wh2506d.c` in Nomad/Manta, with `compatible = "hall-wh2506d"`. |
| `CONFIG_LS_LTR578` | Source found | `drivers/input/sensors/lsensor/ls_ltr578.c` and `.h` in Nomad/Manta. |
| `CONFIG_LS_STK3x1x` | Source found | `drivers/input/sensors/lsensor/ls_stk3x1x.c` and `.h` in Nomad/Manta. |
| `CONFIG_AW9610X_SAR` | Source found | `drivers/input/sensors/pressure/aw9610x/` in Nomad/Manta. |
| `CONFIG_INPUT_FINGERPRINT` / `CONFIG_GOODIX_FINGERPRINT` | Source found, low priority | Nomad/Manta has `drivers/input/fingerprint/gf3956/`; A6X/A5X has `gf3626/`. The live DTS currently disables Goodix fingerprint. |

## HTFY EBC object evidence

Nomad/Manta:

```text
path: drivers/gpu/drm/rockchip/ht_eink/ht_ebc.px
size: 1524344
sha256: cab323bb78b2fa34664b5ff9993231c0fad4e82d514438d2bd3973502c512966
file: ELF 64-bit LSB relocatable, ARM aarch64, version 1 (SYSV), with debug_info, not stripped
```

A6X/A5X:

```text
path: drivers/gpu/drm/rockchip/ht_eink/ht_ebc.px
size: 1298216
sha256: 55c1d84c23d65f0b828653972b19b01a7c2ebc9d62ca1995ea1f0a223c8376d7
file: ELF 64-bit LSB relocatable, ARM aarch64, version 1 (SYSV), with debug_info, not stripped
```

The Nomad/Manta Makefile has:

```make
obj-$(CONFIG_HTFY_EBC)   += ht_ebc.o htfy_dbg.o
$(obj)/ht_ebc.o: $(srctree)/$(obj)/ht_ebc.px
	cp $(srctree)/$(obj)/ht_ebc.px $(obj)/ht_ebc.o
```

`objdump` identifies the object as `elf64-littleaarch64` and exposes compiled
unit names such as `htfy_rk3566_tcon.c`, `htfy_pvi_waveform.c`, and
`htfy_ebc.c`. Exported or visible symbols include:

```text
htfy_pvi_wf_input
htfy_pvi_wf_get_version
htfy_pvi_wf_get_lut
htfy_ebc_register_notifier
ebc_set_tp_power
fb_is_power_off
fb_eink
```

Useful strings in the object include `waveform.bin`, `htfy_eink_probe`,
`rk-ebc-tcon`, `panel,width`, `panel,mirror`, `panel,vcom-mv`,
`ebc_pmic.vcom`, and `Htfyun EBC`.

This means the Supernote repositories are mixed source plus prebuilt object
trees. They are valuable for reproducing the vendor driver shape, but
`CONFIG_HTFY_EBC` is not fully open source there.

## Porting implication

For a same-generation 4.19 experiment, the fastest path is to integrate the
Nomad/Manta source set into a private build tree and test whether `ht_ebc.px`
links against the selected Rockchip 4.19 base and the SP101FU DTS.

For a maintainable 5.10, 6.1, or mainline port, `ht_ebc.px` remains the hard
blocker. The surrounding PMIC, Wacom, Goodix, Huion, HDX, Hall, light/proximity,
SAR, and fingerprint drivers have usable source candidates, but the EBC core
would still need a source replacement, a compatibility layer around a fixed
object ABI, or a rewrite based on public RK EBC work.
