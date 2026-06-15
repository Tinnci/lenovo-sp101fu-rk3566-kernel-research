# SP101FU first temporary boot result

## Result

`fastboot boot` accepted the generated integrated-baseline boot image, but the
device returned to the stock kernel rather than running the test kernel.

Classification: **fails to boot test kernel; stock fallback/reboot succeeds**.

No partition was flashed.

## Test image

The temporary boot image was built from the active-slot boot backup:

- stock ramdisk retained
- stock second-stage image retained
- stock command line retained
- Android boot header v2 parameters retained
- kernel replaced with the integrated 4.19 baseline `Image`
- boot DTB replaced with `rk3566-lenovo-sp101fu.dtb`

The generated test image was 65,638,400 bytes, below the 100 MiB boot partition
size.

## Observed command result

`fastboot boot` returned:

```text
Sending 'boot.img' ... OKAY
Booting ... OKAY
```

After the device returned to ADB:

- `uname -a` still reported stock `4.19.193`.
- active slot remained `_a`.
- verified boot state remained `orange`.
- boot reason was `bootloader`.
- `boot_a` and `vbmeta_a` SHA-256 matched the pre-test backups.

## Interpretation

The bootloader accepts the temporary boot command, but the generated test image
does not become the running kernel. The most likely next investigations are:

- check whether this bootloader silently falls back to the flashed slot after a
  temporary boot failure;
- verify whether the kernel image format needs Rockchip-specific wrapping or a
  different DTB placement;
- compare the stock boot kernel payload layout against the integrated `Image`;
- keep using `fastboot boot` for the next experiment unless a separate issue
  explicitly approves flashing an inactive slot.

## Safety outcome

The first test met the non-destructive requirement. The device returned to the
stock system, ADB/root remained available, and the checked boot/vbmeta
partitions were unchanged.

