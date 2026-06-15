# SP101FU hardware trim audit

This note records the evidence-driven rule for trimming the SP101FU 4.19
baseline: keep hardware that is present and probed on the rooted tablet; disable
vendor reference-board or multi-panel residue that does not exist on this
device. The goal is a self-compilable baseline we can carry toward newer and
eventually mainline kernels, not a byte-for-byte recreation of every Lenovo/HTFY
vendor option.

## Evidence already captured

The current workspace already contains enough live-device evidence for the
first trim pass, so new ADB collection is only needed when a question is not
answerable from these files:

| Evidence | Use |
| --- | --- |
| `../live-device/live-fdt.dts` | Live DTB topology, compatible strings, GPIOs, buses, and disabled vendor residue. |
| `../live-device/proc-config.config` | Running vendor kernel config from `/proc/config.gz`. |
| `../root-evidence/text/dmesg.txt` | Runtime probe success/failure evidence. |
| `../root-evidence/text/getevent_pl.txt` | Actual input devices exposed to Android/Linux. |
| `../root-evidence/text/proc_modules.txt` | Runtime external modules. |
| `../root-evidence/manifests/key-blobs.md` | Firmware/module blobs needed by confirmed hardware, without publishing blobs. |
| `hardware-runtime-map.md` | Sanitized bus/input/interrupt map from a fresh rooted capture before the first boot test. |

Some root sysfs debug captures in `../root-evidence/text/*.stderr.txt` failed
with permission or path errors; treat those as gaps, not negative evidence.

## Current trim decisions

| Area | Evidence | Decision | Baseline state |
| --- | --- | --- | --- |
| Goodix GT9886 touch | Live DTB has `goodix-gtx8@5d`; `getevent -pl` exposes `goodix_ts`; `dmesg` requests Goodix firmware. | Keep. | `CONFIG_TOUCHSCREEN_GOODIX_GTX8=y`; DTS node enabled. |
| Wacom 10S12MI pen | Live DTB has `wacom@09`; `getevent -pl` exposes `Wacom Pencil`. | Keep. | `CONFIG_I2C_HID_WACOM_10S12MI=y`; DTS node enabled. |
| Huion touch | Live DTB has `huion@08`, but root `dmesg` probe fails. | Trim as vendor multi-panel residue. | `CONFIG_TOUCHSCREEN_HUION_PANELS` disabled; DTS node retained with `status = "disabled"`. |
| HDX8801 touch | Live DTB has `hdx8801@11`, but root `dmesg` probe fails. | Trim as vendor multi-panel residue. | `CONFIG_TOUCHSCREEN_HDX8801` disabled; DTS node retained with `status = "disabled"`. |
| Camera / RKISP / CIF / CSI | Device has no camera; root evidence has no camera probe; previous DTS/config work already disabled camera paths. | Trim. | UVC, RKISP, RKCIF, RK628 CSI disabled in the tailored config. |
| Fingerprint | Live DTB only carries disabled `goodix_fp@0`; device has no reader and no runtime probe. | Trim. | Goodix fingerprint remains disabled. |
| E Ink display stack | Live DTB panel timing differs from public W103; `dmesg` confirms HTFY EBC and E Ink PMIC path. | Keep. | HTFY EBC, TPS65185/SY7636A glue, panel timing, and frontlight nodes preserved. |
| TPS65185 vs SY7636A E Ink PMIC | Root evidence shows SY7636A succeeds and TPS65185 init is not the active success path, but both appear in the live board description. | Keep both for now. | Both PMIC EBC drivers and DTS nodes retained until boot testing proves one can be removed. |
| Wi-Fi / Bluetooth | Vendor blobs include BCM/CYW firmware and NVRAM; `/proc/modules` shows `bcmdhd`; live DTB contains Wi-Fi/BT GPIO mapping. | Keep. | BCMDHD and BT UART path retained. |
| Sensors and cover key | Root evidence confirms Hall, light/prox, SAR, accelerometer paths. | Keep. | WH2506D, LTR578, STK3x1x, AW9610X, MXC6655XA retained. |

## Maintenance rule

When trimming further, prefer this sequence:

1. Check the existing live DTB, `/proc/config.gz`, `dmesg`, `getevent`, and
   module evidence first.
2. If the evidence shows real hardware and a successful runtime probe, keep it
   in the 4.19 baseline even if it is awkward vendor code.
3. If the evidence shows absent hardware, disabled live nodes, or consistently
   failed alternate-panel probes, disable the DTS node and Kconfig symbol rather
   than deleting source code.
4. If evidence is ambiguous, keep the feature until the current build has been
   boot-tested on hardware and a fresh rooted ADB capture closes the gap. The
   first `fastboot boot` test did not run the integrated kernel, so ambiguous
   E Ink PMIC/display pieces remain `defer`.
