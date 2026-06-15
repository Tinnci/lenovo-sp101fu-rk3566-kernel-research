# SP101FU boot image format analysis

This note records the packaging findings from the first temporary boot failure.
It intentionally omits raw boot image hashes, device serials, MAC addresses, and
complete device command lines.

## Summary

The active-slot stock boot image is not a plain "kernel + ramdisk only" Android
boot image. It is an Android boot header v2 image whose `second` field contains a
Rockchip resource image.

The first integrated test image replaced the kernel `Image` and Android header
DTB, but kept the stock `second` resource image. Because the stock resource image
also contains `rk-kernel.dtb`, the test image was internally mixed:

- kernel: integrated 4.19 baseline
- Android boot header DTB: integrated `rk3566-lenovo-sp101fu.dtb`
- Rockchip `second` resource `rk-kernel.dtb`: stock DTB

That DTB split is now a primary suspect for the failed temporary boot.

## Android boot header layout

The stock active-slot boot image uses Android boot image header v2:

| Field | Stock value |
| --- | --- |
| page size | `2048` |
| kernel payload | raw arm64 `Image` |
| ramdisk payload | gzip-compressed ramdisk |
| `second` payload | Rockchip `RSCE` resource image |
| header DTB | present |

The stock and integrated kernel payloads both identify as raw arm64 boot
`Image` files. Neither is a compressed `Image.gz`, `Image.lz4`, FIT image, or
obvious Rockchip wrapper. A valid appended DTB was not found in either kernel
payload.

## Rockchip resource image

The boot image `second` field starts with the Rockchip resource magic `RSCE`.
Vendor `scripts/resource_tool` can parse it. The stock resource contains:

| Entry | Purpose |
| --- | --- |
| `rk-kernel.dtb` | Device tree used by Rockchip loader flows |
| `battery_*.bmp` | charging UI assets |
| `logo.bmp` | boot logo |
| `logo_kernel.bmp` | kernel logo |

The `rk-kernel.dtb` inside the stock resource is byte-for-byte identical to the
Android boot header DTB in the stock image. This is an important stock invariant.

Rockchip's vendor `scripts/mkimg` generates `resource.img` from the target DTB
and passes it to `mkbootimg` as `--second resource.img`. For this device class,
repacking should keep the Android header DTB and resource `rk-kernel.dtb`
consistent unless a controlled test proves the bootloader ignores one of them.

## Partition tail

The full `boot_a` partition backup is 100 MiB. The exact original-kernel repack
is smaller and is identical to the stock partition from byte zero through the
repacked boot image length. The remaining partition tail contains non-zero,
high-entropy data and strings such as `DTB_LOADER`, `FDT`, kernel configuration
symbols, and `Linux version`.

No `AVB0` marker was found in that tail during this pass. The tail may still be
vendor loader, verification, hashtree, FEC, or other partition-level metadata.
It is not part of the standard Android boot header sections produced by
`mkbootimg`.

For `fastboot boot`, a normal bootloader should consume the supplied boot image
payload rather than the flashed partition tail. However, the observed bootloader
appears U-Boot/Rockchip-specific, so a future control test should determine
whether temporary boot actually uses the supplied image or silently falls back to
the flashed slot.

## Current hypotheses

| Hypothesis | Evidence | Next check |
| --- | --- | --- |
| Temporary image not actually used | `fastboot boot` returned OKAY but stock kernel booted | Boot a stock-kernel image with a harmless cmdline marker and check `/proc/cmdline` |
| Resource/header DTB mismatch blocks boot | First test used new header DTB but stock resource DTB | Build test image with matching new DTB in both places |
| Bootloader requires partition-shaped tail | Stock partition has a large non-standard tail | Only test after marker/resource checks; keep non-flash path |
| Kernel payload wrapper missing | Stock and new payloads are both raw arm64 `Image` | Low priority unless later evidence contradicts |
| Appended DTB required | No valid appended DTB in stock or new kernel payload | Not supported by current evidence |

## Recommended next experiment order

1. Build a stock-kernel temporary boot image with a harmless cmdline marker.
   This verifies whether `fastboot boot` uses the supplied image at all.
2. If the marker appears, rebuild the integrated image with a regenerated
   Rockchip resource image so `rk-kernel.dtb` matches the Android header DTB.
3. If that still falls back, try an integrated-kernel image with stock DTB in
   both header and resource to separate kernel payload problems from DTB
   problems.
4. Only after those checks, investigate whether the bootloader needs a
   partition-shaped image that preserves stock tail metadata.

All experiments remain non-destructive: use `fastboot boot` only and do not
write boot, vbmeta, dtbo, or inactive-slot partitions.
