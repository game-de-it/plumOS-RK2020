# RK2020 RTL8811CU driver-load correction

Date: 2026-10-25

Physical symptom: the first frontend boot reports the attached USB Wi-Fi
dongle as missing.

Host result: PASS

Physical retry: pending

## V90S history audit

V90S commit `35a90ef` added the verified UGREEN AC650 / RTL8811CU sequence:

```text
0bda:1a2b Realtek DISK -> eject -s /dev/sr0 -> 0bda:c811 -> 8821cu -> wlan0
```

The RK2020 port already contains that bounded USB-ID match, matching `sr*`
lookup, SCSI eject, `c811` wait, hotplug recovery event, and the System-owned
`/usr/bin/eject` dependency closure. Generic USB storage remains outside the
mode-switch path.

## RK2020-specific load failure

The remaining driver-load branch still assumed the V90S module layout:

```text
/lib/modules/4.4.189/extra/8821cu.ko
```

The captured RK2020 EmuELEC module tree instead places the exact stock module
at:

```text
/lib/modules/4.4.189/kernel/drivers/net/wireless/rtl8821cu/8821cu.ko
```

The generated System preserves that stock path, and its generated
`modules.dep`/`modules.alias` resolve `modprobe 8821cu` to it. The controller
could therefore recognize `0bda:c811` or a successfully switched `c811`, then
log the V90S-only `extra/8821cu.ko` path as missing and never create `wlan0`.

## Correction

The RK2020 network controller now loads every alias-approved driver through
`modprobe` rather than assuming V90S's `extra/` directory. This preserves the
captured stock module location and lets kmod apply declared dependencies. The
special `8188eu` to `8192eu` fallback remains bounded to those two approved
driver names.

The host fixture now places its fake `8821cu.ko` under the real RK2020 stock
path and rejects `modprobe 8821cu` if that file is absent. It then covers the
complete `1a2b -> c811 -> modprobe 8821cu -> wlan0 -> scan` path, including
the already-observed non-zero eject return during successful re-enumeration.

The immutable System verifier independently proves that its generated
`modprobe -n -v 8821cu` resolves to the same stock path. A physical cold-plug
or reinsert test, SSID scan, association, DHCP, and reconnect remain required.
