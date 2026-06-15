# SP101FU hardware runtime map

This map summarizes rooted runtime evidence for the SP101FU hardware nodes that
must be preserved before boot testing and future trimming. Raw logs remain
outside Git.

## Evidence sources

- Root `sys_i2c_devices` capture
- Root `sys_input` and `getevent -pl` captures
- Root `/proc/interrupts`
- Root backlight and platform-device captures
- Existing live FDT and config summaries

## Runtime map

| Area | Runtime evidence | Status | Trim rule |
| --- | --- | --- | --- |
| RK817 PMIC | I2C `0-0020`, driver `rk808`, wakeup enabled; child battery/charger/codec platform devices present. | keep | Core power path; never trim in 4.19 baseline. |
| SYR827 buck | I2C `0-0041`, driver `fan53555-regulator`. | keep | CPU/regulator support required. |
| Goodix GT9886 touch | I2C `1-005d`, driver `gtx8`; input `goodix_ts`; axes `1404x1872`; IRQ `gpio0 17`. | keep | Primary touch path. |
| Wacom 10S12MI pen | I2C `3-0009`, driver `wacom_pencil`; input `Wacom Pencil`; pressure max `4095`; IRQs `gpio0 14` and pen detect `gpio0 4`. | keep | Primary pen path. |
| Huion alternate touch | I2C `3-0008` has OF node but no bound driver in sysfs; earlier dmesg probe failed. | trim | Vendor multi-panel residue; keep DTS node disabled for traceability. |
| HDX8801 alternate touch | I2C `3-0011` has OF node but no bound driver in sysfs; earlier dmesg probe failed. | trim | Vendor multi-panel residue; keep DTS node disabled for traceability. |
| E Ink TCON/EBC | Platform `fdec0000.ebc` driver `rk-ebc-tcon`; `ebc-dev` driver `ebcx-dev`; IRQ `fdec0000.ebc` active. | keep | Display update path; not a trim candidate. |
| E Ink PMICs | I2C `3-0062` SY7636A bound to driver `sy7636a`; I2C `3-0068` TPS65185 node present but no bound driver in current sysfs. | defer | Keep both until a test kernel boots and proves TPS65185 is unused. |
| Frontlight | Platform `backlight-cold` and `backlight-warm`, driver `pwm-backlight`; max brightness `215` for both. | keep | Lenovo dual frontlight path. |
| Hall cover key | Input `hall-key`, driver `wh2506d`; IRQ `gpio0 0`. | keep | Cover sleep/wake path. |
| Light/proximity sensors | I2C `1-0048` STK3x1x and `1-0053` LTR578 both bound; input `lightsensor-level`. | keep | Confirmed sensor path. |
| SAR / USB-C controller | I2C `1-004e` ET7303 bound; AW9610X firmware blob is preserved from vendor storage. | keep | Keep until post-boot smoke testing proves otherwise. |
| Accelerometer | I2C `4-0015`, driver `gsensor_mxc6655`; input `gsensor`; IRQ `gpio0 30`. | keep | Orientation/sensor path. |
| Wi-Fi / BT | `bcmdhd` loaded on stock kernel; BT wake host IRQ `gpio0 19`; vendor Wi-Fi/BT firmware preserved. | keep | Wi-Fi may need ABI follow-up under the test kernel. |
| Camera / fingerprint | No runtime camera or fingerprint probe; fingerprint live node is disabled. | trim | Already disabled in the tailored baseline. |

## Unknowns

- TPS65185 remains `defer`, not `trim`, because it is present in the live board
  description even though SY7636A is the bound PMIC path in current sysfs.
- Debugfs pinctrl/regulator captures are useful but not required to trim
  Huion/HDX/camera/fingerprint because those already have stronger evidence.

