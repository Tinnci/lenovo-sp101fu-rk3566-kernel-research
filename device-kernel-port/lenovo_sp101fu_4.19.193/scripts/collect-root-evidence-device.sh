#!/system/bin/sh
set +e

OUT=/data/local/tmp/sp101fu-root-evidence
TAR=/data/local/tmp/sp101fu-root-evidence.tar
BLOBS=/data/local/tmp/sp101fu-vendor-blobs.tar

rm -rf "$OUT" "$TAR" "$BLOBS"
mkdir -p "$OUT/text" "$OUT/manifests"

mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null
mount -t tracefs tracefs /sys/kernel/tracing 2>/dev/null

capture() {
  name="$1"
  shift
  sh -c "$*" > "$OUT/text/$name.txt" 2> "$OUT/text/$name.stderr.txt"
}

capture proc_iomem 'cat /proc/iomem'
capture proc_interrupts 'cat /proc/interrupts'
capture proc_devices 'cat /proc/devices'
capture proc_partitions 'cat /proc/partitions'
capture proc_mounts 'cat /proc/mounts'
capture proc_modules 'cat /proc/modules'
capture proc_kallsyms_head 'head -n 200 /proc/kallsyms'
capture dmesg 'dmesg'
capture mounts_debug 'mount | grep -E "debug|trace|sysfs|proc"'

capture debugfs_top 'find /sys/kernel/debug /d -maxdepth 3 -type f -o -type d 2>/dev/null | sort'
capture debug_gpio 'cat /sys/kernel/debug/gpio 2>/dev/null || cat /d/gpio 2>/dev/null'
capture debug_clk_summary 'cat /sys/kernel/debug/clk/clk_summary 2>/dev/null || cat /d/clk/clk_summary 2>/dev/null'
capture debug_regulator_summary 'cat /sys/kernel/debug/regulator/regulator_summary 2>/dev/null || cat /d/regulator/regulator_summary 2>/dev/null'
capture debug_pinctrl_tree 'find /sys/kernel/debug/pinctrl /d/pinctrl -maxdepth 3 -type f 2>/dev/null | sort'
capture debug_pinctrl_contents 'for f in $(find /sys/kernel/debug/pinctrl /d/pinctrl -maxdepth 3 -type f 2>/dev/null | sort); do echo "### $f"; cat "$f" 2>/dev/null; done'

capture sys_i2c_devices '
for d in /sys/bus/i2c/devices/*; do
  [ -e "$d" ] || continue
  echo "### $d"
  ls -l "$d"
  for f in name modalias uevent status power/wakeup; do
    [ -e "$d/$f" ] && { echo "--- $f"; cat "$d/$f" 2>/dev/null; }
  done
done'

capture sys_spi_devices '
for d in /sys/bus/spi/devices/*; do
  [ -e "$d" ] || continue
  echo "### $d"
  ls -l "$d"
  for f in modalias uevent status power/wakeup; do
    [ -e "$d/$f" ] && { echo "--- $f"; cat "$d/$f" 2>/dev/null; }
  done
done'

capture sys_platform_devices_interesting '
for d in /sys/bus/platform/devices/*; do
  [ -e "$d" ] || continue
  b=$(basename "$d")
  case "$b" in
    *ebc*|*eink*|*goodix*|*wacom*|*hdx*|*huion*|*hall*|*bcmdhd*|*wlan*|*bluetooth*|*rk817*|*tps*|*sy7636*|*pwm*|*backlight*|*gpu*|*mali*|*dmc*|*rknpu*|*i2c*|*spi*)
      echo "### $d"
      ls -l "$d"
      cat "$d/uevent" 2>/dev/null
      ;;
  esac
done'

capture sys_input '
for d in /sys/class/input/input*; do
  [ -e "$d" ] || continue
  echo "### $d"
  for f in name phys uniq properties modalias inhibited; do
    [ -e "$d/$f" ] && { echo "--- $f"; cat "$d/$f" 2>/dev/null; }
  done
  cat "$d/device/uevent" 2>/dev/null
done'

capture getevent_pl 'getevent -pl 2>/dev/null'

capture cpufreq '
for d in /sys/devices/system/cpu/cpu*/cpufreq; do
  [ -d "$d" ] || continue
  echo "### $d"
  for f in scaling_available_frequencies cpuinfo_cur_freq scaling_cur_freq scaling_governor scaling_available_governors cpuinfo_min_freq cpuinfo_max_freq scaling_min_freq scaling_max_freq related_cpus affected_cpus; do
    [ -e "$d/$f" ] && { echo "--- $f"; cat "$d/$f" 2>/dev/null; }
  done
done'

capture devfreq '
for d in /sys/class/devfreq/*; do
  [ -e "$d" ] || continue
  echo "### $d"
  for f in name available_frequencies cur_freq min_freq max_freq governor available_governors trans_stat; do
    [ -e "$d/$f" ] && { echo "--- $f"; cat "$d/$f" 2>/dev/null; }
  done
done'

capture thermal '
for d in /sys/class/thermal/thermal_zone* /sys/class/thermal/cooling_device*; do
  [ -e "$d" ] || continue
  echo "### $d"
  for x in "$d"/type "$d"/temp "$d"/mode "$d"/policy "$d"/trip_point_*_temp "$d"/trip_point_*_type "$d"/cur_state "$d"/max_state; do
    [ -e "$x" ] && { echo "--- $(basename "$x")"; cat "$x" 2>/dev/null; }
  done
done'

capture backlight '
for d in /sys/class/backlight/*; do
  [ -e "$d" ] || continue
  echo "### $d"
  for f in actual_brightness brightness max_brightness scale type bl_power; do
    [ -e "$d/$f" ] && { echo "--- $f"; cat "$d/$f" 2>/dev/null; }
  done
done'

capture modules_params '
for d in /sys/module/*; do
  [ -e "$d" ] || continue
  b=$(basename "$d")
  case "$b" in
    bcmdhd|mali*|bifrost*|goodix*|wacom*|rk817*|ht*|ebc*|sy7636*|tps65185*)
      echo "### $d"
      find "$d" -maxdepth 2 -type f 2>/dev/null | sort | while read f; do
        echo "--- $f"
        cat "$f" 2>/dev/null
      done
      ;;
  esac
done'

capture vendor_modules_list 'find /vendor/lib/modules -maxdepth 4 -type f -print -exec ls -l {} \; -exec sha256sum {} \; 2>/dev/null'
capture vendor_firmware_list 'find /vendor/etc/firmware /vendor/firmware -maxdepth 5 -type f -print -exec ls -l {} \; -exec sha256sum {} \; 2>/dev/null'
capture vendor_configs_list 'find /vendor /odm -maxdepth 5 \( -name "*.rc" -o -name "*.xml" -o -name "*.json" -o -name "*.conf" -o -name "*.kl" -o -name "*.idc" -o -name "*.cfg" -o -name "*.ini" \) -type f -print 2>/dev/null'

find "$OUT/text" -type f -size 0 -delete

tar -C /data/local/tmp -cf "$TAR" sp101fu-root-evidence 2>"$OUT/manifests/evidence-tar.stderr.txt"

paths=""
[ -d /vendor/lib/modules ] && paths="$paths vendor/lib/modules"
[ -d /vendor/etc/firmware ] && paths="$paths vendor/etc/firmware"
[ -d /vendor/firmware ] && paths="$paths vendor/firmware"
[ -n "$paths" ] && tar -C / -cf "$BLOBS" $paths 2>"$OUT/manifests/vendor-blobs-tar.stderr.txt"

echo "$OUT"
echo "$TAR"
echo "$BLOBS"
