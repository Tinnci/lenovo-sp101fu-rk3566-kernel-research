# SP101FU module ABI status

This note records the module ABI decision for the first hardware boot test of
the integrated 4.19 baseline.

## Running stock kernel

- Kernel: `4.19.193 #1 SMP PREEMPT Fri Jul 12 16:55:06 CST 2024`
- Compiler identity: Android Clang 11 (`CONFIG_CC_IS_CLANG=y`,
  `CONFIG_CLANG_VERSION=110002`)
- `CONFIG_PREEMPT=y`
- `CONFIG_MODULES=y`
- `CONFIG_MODVERSIONS=y`
- `CONFIG_LOCALVERSION=""`

Runtime `/proc/modules` shows only:

| Module | Runtime state |
| --- | --- |
| `bcmdhd` | loaded |
| `mali_kbase` | not listed in `/proc/modules` |

Vendor `modules.load` lists both `mali_kbase.ko` and `bcmdhd.ko`, but the live
kernel exposes built-in or loaded module state for `bifrost_kbase`, `mali`,
`wacom`, `wacom_10s12mi`, and the E Ink/debug stack through `/sys/module`.

## Vendor module files

| Module file | SHA-256 | vermagic | Runtime implication |
| --- | --- | --- | --- |
| `/vendor/lib/modules/bcmdhd.ko` | `e4ebbd5fe3c8a6bd41dc6d000a839f742292da99cb87a7ee62c41e620fb1a3e3` | `4.19.193 SMP preempt mod_unload modversions aarch64` | Matches the stock kernel and is loaded at runtime. |
| `/vendor/lib/modules/mali_kbase.ko` | `694dcbb19dc70a492776c3ccc1b3a34dfe017c6ead6868cbd562ff07de5fe140` | `4.19.161 SMP preempt mod_unload modversions aarch64` | Does not match the stock kernel release and is not listed in `/proc/modules`. |

## Integrated 4.19 baseline decision

The integrated baseline builds as `4.19.232` with GCC 15.2.0 and keeps
`CONFIG_PREEMPT=y`, `CONFIG_MODULES=y`, and `CONFIG_MODVERSIONS=y`. It is not
trying to preserve byte-for-byte or module-ABI parity with the stock Lenovo
Clang 11 kernel.

For the first temporary boot test:

- ADB bootability is the gating requirement.
- Wi-Fi may be unavailable if the stock `bcmdhd.ko` refuses to load against the
  `4.19.232` test kernel.
- GPU/module parity is not a blocker because the stock `mali_kbase.ko` is not
  proven to be the live runtime GPU path.
- If Wi-Fi or GPU fail after the test kernel boots, open a focused M6 follow-up
  instead of reverting the baseline to stock ABI identity.

