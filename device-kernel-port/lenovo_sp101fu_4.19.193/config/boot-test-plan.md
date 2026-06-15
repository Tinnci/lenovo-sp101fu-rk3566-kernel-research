# SP101FU non-destructive boot test plan

This plan is for the first hardware validation of the integrated 4.19 baseline.
It uses `fastboot boot` only. Do not flash `boot`, `vbmeta`, `dtbo`, or an
inactive slot during this first pass.

## Current device facts

- ADB is available on the stock system.
- Root is available through `adb shell su -c`.
- Active slot observed for this run: `_a`.
- Verified boot state observed for this run: `orange`; verity mode: `enforcing`.
- Boot partitions: `boot_a`, `boot_b`; metadata partitions: `vbmeta_a`,
  `vbmeta_b`; DT overlay partitions: `dtbo_a`, `dtbo_b`.

## Private backup procedure

The private backup directory for a run lives under `/private/tmp` and is not
tracked by Git. Back up the current device partitions before making any boot
image:

```sh
BACKUP_DIR=/private/tmp/sp101fu-boot-test-$(date +%Y%m%d-%H%M%S)
mkdir -p "$BACKUP_DIR"
for p in boot_a boot_b vbmeta_a vbmeta_b dtbo_a dtbo_b; do
  adb exec-out su -c "dd if=/dev/block/by-name/$p bs=4096 2>/dev/null" \
    > "$BACKUP_DIR/$p.img"
done
shasum -a 256 "$BACKUP_DIR"/*.img > "$BACKUP_DIR/SHA256SUMS.txt"
```

For the current run, the backed-up partition sizes were:

| Partition | Size |
| --- | ---: |
| `boot_a` | 100 MiB |
| `boot_b` | 100 MiB |
| `vbmeta_a` | 1 MiB |
| `vbmeta_b` | 1 MiB |
| `dtbo_a` | 4 MiB |
| `dtbo_b` | 4 MiB |

## Boot image packaging

Use the active-slot boot backup as the source boot image. Local firmware package
boot images are only comparison inputs, not the primary base.

The Rockchip/AOSP boot image scripts have a `python` shebang, but this host uses
`uv`/Python 3. Run them through `uv run python`:

```sh
BOOT_TOOLS=/private/tmp/rk3566_kernel_build/rockchip-kernel-4.19-htfy-src/scripts
uv run python "$BOOT_TOOLS/unpack_bootimg" \
  --boot_img "$BACKUP_DIR/boot_a.img" \
  --out "$BACKUP_DIR/unpack-boot_a"
```

The stock boot image for this run is Android boot header v2 with:

| Field | Value |
| --- | --- |
| page size | `2048` |
| base | `0x10000000` |
| kernel offset | `0x00008000` |
| ramdisk offset | `0x01000000` |
| second offset | `0x00f00000` |
| tags offset | `0x00000100` |
| dtb offset | `0x01f00000` |
| OS version | `11.0.0` |
| OS patch level | `2021-06` |

Before building a test image, perform an original-kernel repack check with the
same ramdisk, second-stage image, DTB, command line, and header parameters. The
repacked image is expected to be smaller than the 100 MiB partition backup
because the partition backup includes unused padding.

The first test image keeps the stock ramdisk, second stage, boot command line,
and header parameters, and replaces only:

- kernel: integrated 4.19 baseline `Image`
- boot DTB: `rk3566-lenovo-sp101fu.dtb`

The current test image was 65,638,400 bytes, below the 100 MiB boot partition
size.

## First test command

Only use temporary boot:

```sh
adb reboot bootloader
fastboot boot "$BACKUP_DIR/sp101fu-4.19-htfy-fastboot-test.img"
adb wait-for-device
adb shell 'uname -a; getprop ro.boot.slot_suffix; cat /proc/modules'
```

If `fastboot boot` fails, run `fastboot reboot` and stop. Do not fall back to
`fastboot flash`.

## Restore path

Because this plan uses `fastboot boot` only, a normal reboot should return to
the stock slot. If a future test writes a partition, restore must use the
matching private backup image and must verify hashes before writing. That is out
of scope for the first pass.

