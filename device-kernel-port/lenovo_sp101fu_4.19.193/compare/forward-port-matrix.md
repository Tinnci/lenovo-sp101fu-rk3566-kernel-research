# SP101FU forward-port matrix

This matrix records the current migration decision after establishing a
self-compilable 4.19 baseline.

## Recommendation

Short term: keep stabilizing and boot-testing the integrated HTFY/Rockchip 4.19
baseline. It is the only path currently known to link the Lenovo/HT E Ink stack
and SP101FU board DTS.

Medium term: evaluate Rockchip 5.10/6.1 vendor kernels only after the 4.19
baseline has a known boot result and a clean hardware trim log.

Long term: mainline is the maintenance goal, but it is gated by replacing or
rewriting the HTFY EBC core currently represented by `ht_ebc.px`.

## Candidate paths

| Path | Pros | Blockers | Decision |
| --- | --- | --- | --- |
| Integrated HTFY/Rockchip 4.19 | Builds `Image` and SP101FU DTB today; contains recovered Goodix, Wacom, PMIC, sensor, and E Ink glue. | Temporary boot image returned to stock kernel; EBC core still uses prebuilt `ht_ebc.px`. | Active baseline. |
| Public Rockchip 4.19 only | Useful comparison base; contains RK3566/RK817/E Ink board family. | Missing Lenovo/HT board drivers and HTFY EBC stack. | Not an execution target. |
| Rockchip vendor 5.10/6.1 | Better long-term Android/vendor base than 4.19; likely has newer RK356x platform support. | Unknown EBC parity; Lenovo/HT drivers must be forward-ported; `ht_ebc.px` likely unusable without ABI work. | Evaluate after 4.19 boots. |
| Android common / GKI | Cleaner Android integration direction. | Board-specific E Ink stack, vendor modules, and display pipeline do not fit without substantial glue. | Research only. |
| PineNote/RK3566 community work | Relevant RK3566 E Ink prior art and mainline-oriented thinking. | Different panel, PMIC, touch/pen stack, and userspace assumptions. | Reference for replacement design. |
| Mainline RK3566 | Best maintainability target. | No drop-in HTFY EBC replacement; SP101FU panel/frontlight/pen/touch/power stack needs bindings and drivers. | Long-term target after EBC plan. |

## Subsystem portability

| Subsystem | 4.19 baseline state | Forward-port posture |
| --- | --- | --- |
| HTFY EBC core | Links through prebuilt `ht_ebc.px`. | Main blocker; needs source replacement or rewrite. |
| E Ink PMIC | TPS65185/SY7636A glue source exists; SY7636A binds at runtime. | Likely portable with binding cleanup and power-sequence validation. |
| Goodix GT9886 touch | Vendor GTX8 driver binds and exposes correct axes. | Prefer upstream Goodix path only if GT9886 support and firmware loading match; otherwise port vendor driver first. |
| Wacom 10S12MI pen | Vendor driver binds and exposes pen axes/pressure. | Needs HID/I2C review; may require vendor driver carry initially. |
| Frontlight | Dual PWM backlight nodes bind. | Likely portable through standard PWM backlight once DTS is clean. |
| Wi-Fi/BT | Stock `bcmdhd` module is ABI-bound to 4.19.193. | Rebuild driver or accept temporary Wi-Fi loss during early forward-port bring-up. |
| Sensors/Hall/SAR | Vendor drivers bind on 4.19. | Port only confirmed hardware; defer ambiguous pieces until post-boot evidence. |
| Camera/fingerprint/Huion/HDX | Confirmed absent or unused on this device. | Do not forward-port unless new hardware evidence appears. |

## Next migration work

1. Resolve why the temporary 4.19 test image falls back to stock.
2. Boot the integrated 4.19 baseline at least once.
3. Finish the evidence-driven hardware trim on 4.19.
4. Compare Rockchip 5.10/6.1 E Ink/display support against the trimmed 4.19
   hardware map.
5. Start an EBC replacement design before promising a mainline boot target.

