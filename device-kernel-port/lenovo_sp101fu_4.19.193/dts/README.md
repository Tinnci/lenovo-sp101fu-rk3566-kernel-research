# Lenovo SP101FU DTS candidate

`rk3566-lenovo-sp101fu.dts` is a source-level candidate derived from:

- the private live FDT at `../live-device/live-fdt.dts`
- the public Rockchip source file `rk3566-rk817-eink-w103.dts`

It intentionally includes `rk3566-rk817-eink-w103.dts` and then overrides the
SP101FU board-specific nodes. This keeps the public Rockchip board baseline
visible while avoiding publication of bootloader-injected runtime state such as
`/chosen/bootargs`, initrd addresses, memory map, serial number, Wi-Fi MAC, or
BT MAC.

## Preserved from the live FDT

- root model string for the BOE 10.3 DVT1 board
- E Ink panel timing, mirror flag, DPI, dimensions, and VCOM value
- dual warm/cold PWM frontlight nodes
- Goodix GT9886 touch node
- Wacom 10S12MI pen node
- disabled Huion and HDX8801 touch residue nodes retained for traceability
- TPS65185 and SY7636A E Ink PMIC nodes and GPIO mapping
- WH2506D Hall sensor
- LTR578, STK3x1x, AW9610X SAR, MXC6655XA, and ET7303 board peripherals
- Wi-Fi/BT reset, wake, host-wake, and SDIO reset GPIOs
- disabled Goodix fingerprint node from the live FDT

## Not preserved

- `/chosen/bootargs`
- `/memory/reg`
- `linux,initrd-*`
- `serial-number`
- phandle values from the decompiled live FDT

## Current status

This DTS is integrated into the private HTFY/Rockchip 4.19 build tree and
produces `arch/arm64/boot/dts/rockchip/rk3566-lenovo-sp101fu.dtb` as part of a
clean `make Image dtbs` rebuild. Goodix GT9886 is enabled; Huion and HDX8801 are
left present but `status = "disabled"` because live probe evidence shows they
are unused multi-panel residue on this SP101FU hardware.
