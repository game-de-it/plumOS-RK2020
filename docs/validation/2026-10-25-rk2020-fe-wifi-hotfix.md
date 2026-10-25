# RK2020 frontend and Wi-Fi hardware-test hotfix

Date: 2026-10-25

Target media: `/dev/disk5`, a removable 62.5 GB SD card in the built-in Mac
reader. The mounted volumes were `PLUMOS_BOOT` (`disk5s1`) and `PLUMOS_USER`
(`disk5s3`). `PLUMOS_SYS` (`disk5s2`) remained unmounted on macOS.

## Scope

The hardware boot passed the stock initramfs and reached the plumOS frontend.
Cursor input worked. Two follow-up issues were staged for another hardware pass:

1. top-card artwork was visually unbalanced because the renderer reserved a
   detail footer even when a card had no detail text;
2. an RTL8811CU dongle remained `MISSING` even though the V90S-derived
   `0bda:1a2b` driver-disk ejection flow was already present.

The RK2020 stock module tree places the driver at
`kernel/drivers/net/wireless/rtl8821cu/8821cu.ko`. The controller now asks
`modprobe` to resolve `8821cu` through the stock `modules.dep` instead of using
the V90S-specific `extra/8821cu.ko` path.

## Staged payload

The following files were copied to
`PLUMOS_BOOT/plumos-hotfix/e536b78/`:

| File | SHA-256 |
| --- | --- |
| `plumos-frontend-rk2020` | `8b0015e474bbd92ed84b48b3b1b19287e5423cfd58bec422005d38ed2e60569e` |
| `plumos-network-control` | `5ef93fa5b8536cc5d08da408151d0759d49a4c4d74b9bda5ea8c45180627770c` |

`post-sysroot.sh` was extended with a one-shot installer. Its SD readback hash
is `3743c29a8629b8859c411609157e86436510b19fd656f93b6789394b4d26ae0f`.
The original hook remains recoverable as `post-sysroot.sh.pre-e536b78`, hash
`39018cde631ba5f639ee0af15c7b3b8108abc5656a604283195a568990638774`.

Before changing either runtime file, the hook:

- verifies both payload hashes;
- copies the previous boot logs to the Mac-readable USER partition under
  `.plumos-validation/rk2020-hotfix-e536b78/previous-boot/` when available;
- preserves the installed files under `/storage/backups/hotfix-e536b78/`;
- stages and re-verifies both replacements before renaming them into place;
- records `/storage/update-state/hotfix-e536b78.applied` and becomes
  idempotent on later boots.

Any hotfix failure is logged but deliberately does not stop the stock
initramfs handoff.

## Host verification

- frontend component checksum verification: pass;
- `plumos-network-control` shell syntax: pass;
- SD payload checksum readback: pass;
- SD payload byte comparison against build output: pass;
- two-boot container fixture, including backup, log export, replacement,
  completion marker, and idempotent second boot: pass.
- full `release-image` build from source ref `e536b78`: pass;
- rebuilt image SHA-256:
  `5fe603087b55535a7d11b7d61f2ac6181770ebdeafb15efaff4f2a24d1e6d104`.

## Remaining hardware gates

- the hook reports `plumos-hotfix=e536b78 result=applied` on first boot;
- all three top cards have visually balanced artwork;
- the dongle changes from `0bda:1a2b` to `0bda:c811`, `8821cu` loads, and a
  `wlan0` interface appears;
- the frontend Wi-Fi status changes from `MISSING` and can scan access points;
- cursor/input and normal frontend launch remain functional.

Association, DHCP, SSH, and an application-level network operation remain
separate acceptance gates even if scan succeeds.
