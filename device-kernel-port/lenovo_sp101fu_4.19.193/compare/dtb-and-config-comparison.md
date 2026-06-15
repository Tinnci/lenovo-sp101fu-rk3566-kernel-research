# Lenovo SP101FU live FDT vs Rockchip RK3566 EINK candidates

## Inputs

- Live device tree: `live-device/live-fdt.dtb`
- Live device tree source: `live-device/live-fdt.dts`
- Candidate DTB: `candidate-dtbs/rk3566-rk817-eink-w103.dtb`
- Candidate DTB: `candidate-dtbs/rk3566-rk817-eink.dtb`
- Live kernel config: `live-device/proc-config.config`
- Rockchip 4.19 olddefconfig output: `/private/tmp/rk3566_kernel_build/out-sp101fu-4.19-gcc/.config`

## Top-level result

The live Lenovo SP101FU DTB is not identical to either Rockchip candidate DTB.

`rk3566-rk817-eink-w103.dtb` is the closer public baseline, but the live device tree includes Lenovo/HT board-specific changes that must be preserved before attempting a replacement kernel.

| DTB | Size | SHA-256 | Root model |
| --- | ---: | --- | --- |
| live FDT | 118912 | `e32dafcb1429f5eafb49e745ea6effefe83b49b8ce4fce268436df136a19a472` | `Rockchip RK3566 EINK Boe 10.3 DVT1 Board II` |
| `rk3566-rk817-eink-w103` | 118528 | `288a9034b63e508d3b36176f984151d2139420a3e6f1cc68fbc99b05cd4e3434` | `Rockchip RK3566 RK817 EINK LP4X Board` |
| `rk3566-rk817-eink` | 116356 | `1dba4e15e7219df74a0e6873f5ca6be4a5aa1fc21d9246dc44cde6cb5b1bbc32` | `Rockchip RK3566 RK817 EINK LP4X Board` |

All three share:

- `compatible = "rockchip,rk3566-rk817-eink", "rockchip,rk3566"`
- RK3566/RK3568 common SoC nodes
- RK817 PMIC family
- EBC/eink TCON nodes

## Important DTB differences

| Area | Live Lenovo SP101FU | `rk3566-rk817-eink-w103` | `rk3566-rk817-eink` | Impact |
| --- | --- | --- | --- | --- |
| E Ink panel | `1872x1404`, `sdck=34000000`, `mirror=1`, `width-mm=210`, `height-mm=157`, `dpi=220`, `vcom-mv=1670` | `1872x1404`, `sdck=34000000`, `mirror=0`, `width-mm=157`, `height-mm=210`, no `dpi`, no `vcom-mv` | `1872x1404`, `sdck=33300000`, `mirror=0`, no `dpi`, no `vcom-mv` | Live panel timing is custom. Do not use either candidate panel block directly. |
| Panel porch/timing | `lel=15`, `fel=1` | `lel=7`, `fel=12` | `lel=7`, `fel=12` | EBC waveform/display quality and orientation risk. |
| Backlight | Two nodes: `/backlight-warm`, `/backlight-cold` | Single `/backlight` | none | Frontlight control is Lenovo-specific. |
| Touch | `/i2c@fe5a0000/goodix-gtx8@5d`, `goodix,gt9886`, max `1404x1872` | Cypress `cyttsp5_i2c_adapter` at `/i2c@fe5e0000/tsc@24` | Cypress/GSL variants | Candidate touch nodes do not match hardware. |
| Pen | `/i2c@fe5c0000/wacom@09`, `wacom,10S12MI` | `/i2c@fe5a0000/wacom@9`, `wacom,w9013` | `/i2c@fe5b0000/wacom@9`, `wacom,w9013` | Requires Lenovo Wacom 10S12MI driver/config. |
| E Ink PMIC | `tps65185@68` plus `sy7636a@62` on `/i2c@fe5c0000` | `tps65185@68` only on `/i2c@fe5c0000` | different placement | Live has extra PMIC compatibility path and different GPIOs. |
| Hall sensor | `hall-wh2506d`, GPIO0_A0 | `hall-mh248`, GPIO0_C7 | missing | Cover sleep/wake differs. |
| Wi-Fi power | `reset-gpios = gpio0 pin 0x1b`, vbat GPIO0 pin 0x1d, host wake GPIO0 pin 0x15 | reset GPIO0 pin 0x16, vbat GPIO0_A0, host wake GPIO0 pin 0x15 | disabled | `w103` is closer but reset/vbat differ. |
| Bluetooth GPIO | reset same as `w103`; wake GPIO differs (`0x1c` live vs `0x12` w103) | partly close | disabled | Needs live GPIO mapping. |
| ADC keys | disabled, thresholds look like `w103` | enabled | disabled but different thresholds | Do not blindly take either. |
| LEDs | live `led_r` on different GPIO | `battery_charging` on GPIO3_PC5 | missing | Charging LED differs. |
| Sensors | live has `ls_ltr578`, `ls_stk3x1x`, `awinic,aw9610x_sar`, `etek,et7303`, `gs_mxc6655xa` | only subset/different accelerometer | subset/different | Sensor stack is vendor-board-specific. |
| Fingerprint | live has disabled `goodix,goodix-fp` under `/spi@fe620000` | missing | missing | SP101FU has no fingerprint reader; keep SPI2 fingerprint and fingerprint drivers disabled. |
| Camera | no camera hardware; inherited RKISP/CIF reference nodes may appear | camera reference path inherited from public board files | camera reference path inherited from public board files | Keep UVC, CIF, RKISP, and RK628 CSI disabled for the tailored build. |

## Bootloader-injected runtime data

The live FDT includes runtime data not present in the compiled candidate DTBs:

- `/memory/reg` with the actual RAM map
- `/chosen/bootargs` with Android slot, AVB, serial, language/country, firmware path, boot devices
- `/chosen/linux,initrd-start` and `/chosen/linux,initrd-end`
- `serial-number`

This means the source DTB should not hard-code all runtime bootargs, but the boot image and bootloader flow must continue to pass them.

## Kernel config and compiler differences

The running kernel was built as:

- Kernel: `4.19.193 #1 SMP PREEMPT Fri Jul 12 16:55:06 CST 2024`
- Compiler: Android Clang `11.0.2`, LLD `11.0.2`
- Config: `CONFIG_CC_IS_CLANG=y`, `CONFIG_LD_IS_LLD=y`, `CONFIG_CLANG_VERSION=110002`

The current public Rockchip source checkout is:

- Source version: `4.19.232`
- Local test compiler: GCC `12.5.0`
- Generated config: `CONFIG_CC_IS_GCC=y`, `CONFIG_GCC_VERSION=120500`

The live config and public-source `olddefconfig` differ materially. The diff is saved at:

- `compare/proc-config_vs_rockchip-4.19-olddefconfig.diff`

Important live config symbols missing or changed in the public-source `olddefconfig`:

- `CONFIG_HTFY_EBC=y`
- `CONFIG_PMIC_EBC_TPS65185=y`
- `CONFIG_PMIC_EBC_SY7636A=y`
- `CONFIG_I2C_HID_WACOM_10S12MI=y`
- `CONFIG_TOUCHSCREEN_GOODIX_GTX8=y`
- `CONFIG_TOUCHSCREEN_HUION_PANELS=y`
- `CONFIG_TOUCHSCREEN_HDX8801=y`
- `CONFIG_LS_LTR578=y`
- `CONFIG_LS_STK3x1x=y`
- `CONFIG_AW9610X_SAR=y`
- `CONFIG_HS_WH2506D=y`

The live vendor config also enables some reference-platform options that are
not target hardware for this tablet. The tailored SP101FU build keeps
fingerprint, UVC camera, Rockchip CIF, RKISP, and RK628 CSI disabled.

Stable/common config facts:

- `CONFIG_IKCONFIG=y`
- `CONFIG_IKCONFIG_PROC=y`
- `CONFIG_ARCH_ROCKCHIP=y`
- `CONFIG_ARM64=y`
- `CONFIG_PREEMPT=y`
- `CONFIG_HZ=300`
- `CONFIG_MODULES=y`
- `CONFIG_BCMDHD=y`
- `CONFIG_BCMDHD_FW_PATH="/vendor/etc/firmware/fw_bcmdhd.bin"`
- `CONFIG_BCMDHD_NVRAM_PATH="/vendor/etc/firmware/nvram.txt"`
- `CONFIG_BATTERY_RK817=y`
- `CONFIG_CHARGER_RK817=y`
- `CONFIG_SND_SOC_RK817=y`

## Current conclusion

Use `rk3566-rk817-eink-w103.dts` only as the closest public starting point. A working Lenovo SP101FU kernel needs a Lenovo/HT board DTS derived from the live FDT plus the vendor driver/Kconfig set for HTFY EBC, PMIC EBC, Wacom 10S12MI, Goodix GTX8/GT9886, Huion/HDX pen stack, WH2506D Hall, Lenovo frontlight, and sensors.

The public Rockchip 4.19 tree is not sufficient by itself for a bootable, fully functional replacement kernel.
