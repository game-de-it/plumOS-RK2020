#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SERVICE="$ROOT_DIR/rootfs/rk2020/usr/lib/plumos/init.d/15-usb-host-reenumerate"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/plumos-rk2020-usb-host.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/usb" "$TMP/dwc2" "$TMP/platform" "$TMP/config/system" \
    "$TMP/log"
printf 'network={}\n' >"$TMP/config/wpa_supplicant.conf"
printf '{"wifi_enabled": true}\n' >"$TMP/config/system/settings.json"
printf '0\n' >"$TMP/usb-online"
printf 'otg\n' >"$TMP/otg-mode"
printf '0x00000000\n' >"$TMP/phy-status"
: >"$TMP/gusbcfg"
: >"$TMP/dwc2/bind"
: >"$TMP/dwc2/unbind"
ln -s "$TMP/dwc2" "$TMP/platform/driver"
cat >"$TMP/modprobe" <<'EOF'
#!/bin/sh
printf '%s\n' "$1" >>"$PLUMOS_USB_HOST_MODPROBE_LOG"
ln -s "$PLUMOS_USB_HOST_DWC2_DRIVER" \
    "$PLUMOS_USB_HOST_PLATFORM_DEVICE/driver"
if [ "${PLUMOS_USB_HOST_MODPROBE_ENUMERATE:-0}" = 1 ]; then
    mkdir -p "$PLUMOS_USB_HOST_DEVICES_ROOT/1-1"
    printf '0bda\n' >"$PLUMOS_USB_HOST_DEVICES_ROOT/1-1/idVendor"
fi
EOF
chmod +x "$TMP/modprobe"

service_env=(
    PLUMOS_USB_HOST_USB_ONLINE="$TMP/usb-online"
    PLUMOS_USB_HOST_DEVICES_ROOT="$TMP/usb"
    PLUMOS_USB_HOST_DWC2_DRIVER="$TMP/dwc2"
    PLUMOS_USB_HOST_PLATFORM_DEVICE="$TMP/platform"
    PLUMOS_USB_HOST_DEVICE_ID=ff300000.usb
    PLUMOS_USB_HOST_OTG_MODE="$TMP/otg-mode"
    PLUMOS_USB_HOST_PHY_STATUS_FILE="$TMP/phy-status"
    PLUMOS_USB_HOST_DWC2_GUSBCFG_FILE="$TMP/gusbcfg"
    PLUMOS_USB_HOST_MODPROBE="$TMP/modprobe"
    PLUMOS_USB_HOST_MODPROBE_LOG="$TMP/modprobe.log"
    PLUMOS_USB_HOST_WPA_CONFIG="$TMP/config/wpa_supplicant.conf"
    PLUMOS_USB_HOST_SETTINGS="$TMP/config/system/settings.json"
    PLUMOS_USB_HOST_LOG="$TMP/log/service.log"
    PLUMOS_USB_HOST_RESET_DELAY=0
    PLUMOS_USB_HOST_MODE_SETTLE=0
    PLUMOS_USB_HOST_ENUMERATION_WAIT=0
    PLUMOS_USB_HOST_PRE_RESET_WAIT=0
    PLUMOS_USB_HOST_LOCK_WAIT=0
    PLUMOS_USB_HOST_LOCK_DIR="$TMP/control.lock"
    PLUMOS_USB_HOST_TRANSITION_MARKER="$TMP/probe-active"
)

env "${service_env[@]}" "$SERVICE" worker
grep -Fxq otg "$TMP/otg-mode"
grep -Fxq 'ff300000.usb' "$TMP/dwc2/unbind"
grep -Fxq 'ff300000.usb' "$TMP/dwc2/bind"
grep -q 'result=reset-complete downstream=absent owner=otg' "$TMP/log/service.log"

# A dongle that enumerates during the host-mode settle period must be retained
# without an intentional DWC2 unbind/remove cycle.
: >"$TMP/dwc2/bind"
: >"$TMP/dwc2/unbind"
printf '0\n' >"$TMP/usb-online"
printf '0x00000000\n' >"$TMP/phy-status"
printf 'otg\n' >"$TMP/otg-mode"
(
  sleep 0.1
  mkdir -p "$TMP/usb/1-1"
  printf '0bda\n' >"$TMP/usb/1-1/idVendor"
) &
late_pid=$!
env "${service_env[@]}" PLUMOS_USB_HOST_MODE_SETTLE=1 \
  "$SERVICE" worker
wait "$late_pid"
grep -Fxq host "$TMP/otg-mode"
test ! -s "$TMP/dwc2/bind"
test ! -s "$TMP/dwc2/unbind"
grep -q 'result=enumerated-after-host-force' "$TMP/log/service.log"
rm -rf "$TMP/usb/1-1"

# The production image does not auto-load dwc2.  Loading it must get the first
# opportunity to enumerate a dongle naturally, without forcing GUSBCFG.
rm "$TMP/platform/driver"
: >"$TMP/dwc2/bind"
: >"$TMP/dwc2/unbind"
: >"$TMP/modprobe.log"
printf 'UNKNOWN\n' >"$TMP/otg-mode"
printf '0x40001234\n' >"$TMP/gusbcfg"
env "${service_env[@]}" PLUMOS_USB_HOST_MODPROBE_ENUMERATE=1 \
  "$SERVICE" worker
grep -Fxq dwc2 "$TMP/modprobe.log"
grep -Fxq '0x40001234' "$TMP/gusbcfg"
test ! -s "$TMP/dwc2/bind"
test ! -s "$TMP/dwc2/unbind"
grep -q 'stage=module-loaded module=dwc2' "$TMP/log/service.log"
grep -q 'result=enumerated-after-controller-load' "$TMP/log/service.log"
rm -rf "$TMP/usb/1-1"

# If the stock PHY ABI reports UNKNOWN, force only DWC2's host bit, retain all
# unrelated bits, perform the reset fallback, then return to automatic OTG.
rm "$TMP/platform/driver"
: >"$TMP/dwc2/bind"
: >"$TMP/dwc2/unbind"
: >"$TMP/modprobe.log"
printf 'UNKNOWN\n' >"$TMP/otg-mode"
printf '0x40001234\n' >"$TMP/gusbcfg"
env "${service_env[@]}" "$SERVICE" worker
grep -Fxq dwc2 "$TMP/modprobe.log"
grep -Fxq '0x00001234' "$TMP/gusbcfg"
grep -Fxq 'ff300000.usb' "$TMP/dwc2/unbind"
grep -Fxq 'ff300000.usb' "$TMP/dwc2/bind"
grep -q 'stage=host-mode-forced source=dwc2-register old=0x40001234 new=0x20001234' \
  "$TMP/log/service.log"
grep -q 'stage=otg-mode-released source=dwc2-register old=0x20001234 new=0x00001234' \
  "$TMP/log/service.log"
printf 'otg\n' >"$TMP/otg-mode"

# Concurrent boot recovery and FE scan probes must not reset the same DWC2
# controller or change its role underneath each other.
mkdir "$TMP/control.lock"
printf 'otg\n' >"$TMP/otg-mode"
env "${service_env[@]}" "$SERVICE" worker
grep -Fxq otg "$TMP/otg-mode"
grep -q 'reason=operation-in-progress operation=worker' "$TMP/log/service.log"
rmdir "$TMP/control.lock"

: >"$TMP/dwc2/bind"
: >"$TMP/dwc2/unbind"
printf '1\n' >"$TMP/usb-online"
printf 'host\n' >"$TMP/otg-mode"
env "${service_env[@]}" "$SERVICE" worker
grep -Fxq otg "$TMP/otg-mode"
test ! -s "$TMP/dwc2/bind"
test ! -s "$TMP/dwc2/unbind"
grep -q 'result=skipped reason=usb-upstream-online' "$TMP/log/service.log"

printf '0\n' >"$TMP/usb-online"
printf 'host\n' >"$TMP/otg-mode"
mkdir -p "$TMP/usb/1-1"
printf '0bda\n' >"$TMP/usb/1-1/idVendor"
env "${service_env[@]}" "$SERVICE" worker
grep -Fxq host "$TMP/otg-mode"
test ! -s "$TMP/dwc2/bind"
test ! -s "$TMP/dwc2/unbind"
grep -q 'result=skipped reason=downstream-already-enumerated' \
    "$TMP/log/service.log"

rm -rf "$TMP/usb/1-1"
printf '0x00000200\n' >"$TMP/phy-status"
printf 'otg\n' >"$TMP/otg-mode"
: >"$TMP/dwc2/bind"
: >"$TMP/dwc2/unbind"
env "${service_env[@]}" "$SERVICE" worker
grep -Fxq otg "$TMP/otg-mode"
test ! -s "$TMP/dwc2/bind"
test ! -s "$TMP/dwc2/unbind"
grep -q 'result=skipped reason=usb-upstream-online' "$TMP/log/service.log"

# Explicit FE scan/on probing is allowed without saved credentials, but an
# empty probe must always return the shared connector to stock OTG mode.
rm -f "$TMP/config/wpa_supplicant.conf"
printf '0x00000000\n' >"$TMP/phy-status"
: >"$TMP/dwc2/bind"
: >"$TMP/dwc2/unbind"
env "${service_env[@]}" "$SERVICE" probe
grep -Fxq otg "$TMP/otg-mode"
grep -Fxq 'ff300000.usb' "$TMP/dwc2/unbind"
grep -Fxq 'ff300000.usb' "$TMP/dwc2/bind"

printf 'host\n' >"$TMP/otg-mode"
env "${service_env[@]}" "$SERVICE" release
grep -Fxq otg "$TMP/otg-mode"
grep -q 'result=released reason=requested' "$TMP/log/service.log"

printf 'host\n' >"$TMP/otg-mode"
mkdir -p "$TMP/usb/1-1"
printf '0bda\n' >"$TMP/usb/1-1/idVendor"
env "${service_env[@]}" "$SERVICE" release-if-idle
grep -Fxq host "$TMP/otg-mode"
grep -q 'result=skipped reason=downstream-still-present' "$TMP/log/service.log"

rm -rf "$TMP/usb/1-1"
env "${service_env[@]}" PLUMOS_USB_HOST_RELEASE_DELAY=0 \
  "$SERVICE" release-later
for _ in 1 2 3 4 5; do
  grep -Fxq otg "$TMP/otg-mode" && break
  sleep 0.1
done
grep -Fxq otg "$TMP/otg-mode"

# Production must outlast the network controller's five-second 1a2b -> c811
# re-enumeration window before deciding that the dongle was physically removed.
grep -q 'PLUMOS_USB_HOST_RELEASE_DELAY:-8' "$SERVICE"

printf 'rk2020_usb_host_reenumerate=result-ok\n'
