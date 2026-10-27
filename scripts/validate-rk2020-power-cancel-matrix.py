#!/usr/bin/env python3
"""Validate power-menu Cancel across RK2020 direct-display runtime families."""

from __future__ import annotations

import argparse
import datetime as dt
import importlib.util
import json
from pathlib import Path
import re
import shlex
import time
from typing import Any


ROOT = Path(__file__).resolve().parent.parent
MEDIA_VALIDATOR = ROOT / "scripts/validate-rk2020-device-media.py"
spec = importlib.util.spec_from_file_location("rk2020_device_media", MEDIA_VALIDATOR)
if spec is None or spec.loader is None:
    raise SystemExit(f"cannot load {MEDIA_VALIDATOR}")
media = importlib.util.module_from_spec(spec)
spec.loader.exec_module(media)


CASES: dict[str, dict[str, str]] = {
    "ra": {
        "family": "RetroArch",
        "system": "nes",
        "profile": "retroarch:fceumm",
        "rom": "FC/Akumajou Densetsu.nes",
    },
    "pico": {
        "family": "PicoArch",
        "system": "nes",
        "profile": "picoarch:quicknes",
        "rom": "FC/Akumajou Densetsu.nes",
    },
    "mupen": {
        "family": "Mupen64Plus standalone",
        "system": "n64",
        "profile": "standalone:mupen64plus",
        "rom": "N64/SUPERMARIO64.Z64",
    },
    "drastic": {
        "family": "DraStic standalone",
        "system": "nds",
        "profile": "standalone:drastic",
        "rom": "NDS/99のなみだ バンダイナムコゲームス.nds",
    },
    "openbor": {
        "family": "OpenBOR standalone",
        "system": "openbor",
        "profile": "standalone:openbor",
        "rom": "OPENBOR/Crisis Evil 1.pak",
    },
}


def launch_command(case: dict[str, str]) -> str:
    common = (
        "PLUMOS_ROOT=/mnt/plumos PLUMOS_SDCARD_ROOT=/mnt/plumos-user "
        "PLUMOS_RUNTIME_ROOT=/run/plumos"
    )
    return (
        f"exec env {common} /mnt/plumos/bin/plumos-text-ui launch "
        f"{shlex.quote(case['system'])} {shlex.quote(case['rom'])} "
        f"--profile {shlex.quote(case['profile'])} --execute --no-scan"
    )


def resolve_rom(device: Any, case: dict[str, str]) -> str:
    """Use the device cache so Unicode normalization cannot alter a ROM path."""
    script = f"""
import json
preferred = {case['rom']!r}
with open('/mnt/plumos/state/frontend/systems/{case['system']}.json', encoding='utf-8') as handle:
    cached = json.load(handle)
roms = [
    rom.get('relative_path')
    for system in cached.get('systems', [])
    for rom in system.get('roms', [])
    if rom.get('relative_path')
]
print(preferred if preferred in roms else (roms[0] if roms else ''))
"""
    resolved = device.run("python3 -", input_text=script).stdout.strip()
    if not resolved:
        raise RuntimeError(f"{case['system']}: no representative ROM in cache")
    return resolved


def live_group(ps_text: str, pgid: int) -> list[dict[str, str]]:
    rows = []
    for line in ps_text.splitlines():
        columns = line.split(None, 5)
        if len(columns) < 5 or columns[2] != str(pgid):
            continue
        if columns[3].startswith("Z"):
            continue
        rows.append(
            {
                "pid": columns[0],
                "ppid": columns[1],
                "pgid": columns[2],
                "state": columns[3],
                "command": columns[4],
                "args": columns[5] if len(columns) > 5 else "",
            }
        )
    return rows


def audio_advances(first: dict[str, Any], second: dict[str, Any]) -> bool:
    return (
        first.get("state") == "RUNNING"
        and second.get("state") == "RUNNING"
        and isinstance(first.get("hw_ptr"), int)
        and isinstance(second.get("hw_ptr"), int)
        and first["hw_ptr"] != second["hw_ptr"]
    )


def active_scanout(result: dict[str, Any]) -> bool:
    return any(
        plane.get("width", 0) * plane.get("height", 0) >= 320 * 400
        and plane.get("plane", 0) > 0
        for plane in result.get("planes", [])
    )


def collect(device: Any, prefix: str, phase: str) -> None:
    target = f"{prefix}-{phase}"
    device.run(
        f"ps -eo pid,ppid,pgid,stat,comm,args >{target}.ps; "
        f"/tmp/drm-scanout-capture /dev/dri/card0 {target} "
        f"2>{target}.capture.log || true; "
        f"sed -i 's/ height=\\([0-9][0-9]*\\) pitch=/ height=\\1 format=XR24 pitch=/' "
        f"{target}.capture.log; "
        f"sed -i 's/$/ crtc_xy=0,0/' {target}.capture.log; "
        f"plane=$(sed -n 's/^plane=\\([0-9][0-9]*\\).*/\\1/p' {target}.capture.log | head -n 1); "
        f"[ -z \"$plane\" ] || [ ! -s {target} ] || "
        f"cp {target} {target}-plane-$plane.xrgb8888; "
        f"cat /proc/asound/card0/pcm0p/sub0/status >{target}.audio1 2>&1 || true; "
        "sleep 1; "
        f"cat /proc/asound/card0/pcm0p/sub0/status >{target}.audio2 2>&1 || true",
        timeout=20,
    )


def copy_evidence(device: Any, prefix: str, output: Path) -> None:
    files = device.run(
        f"for f in {prefix}*; do [ -f \"$f\" ] && printf '%s\\n' \"$f\"; done",
        check=False,
    ).stdout.splitlines()
    for remote in files:
        device.copy_from(remote, output / Path(remote).name)


def run_case(
    device: Any,
    output: Path,
    case_id: str,
    case: dict[str, str],
    startup_seconds: int,
) -> dict[str, Any]:
    case = {**case, "rom": resolve_rom(device, case)}
    base = f"plumos-power-cancel-{case_id}"
    prefix = f"/tmp/{base}"
    command = launch_command(case)
    device.run(
        "/mnt/plumos/bin/plumos-frontend-stop stop >/dev/null 2>&1 || true; "
        f"setsid /bin/sh -c {shlex.quote(command)} "
        f">{prefix}.launch.log 2>&1 </dev/null & echo $! >{prefix}.pid"
    )
    pid_text = device.run(f"cat {prefix}.pid").stdout.strip()
    if not pid_text.isdigit():
        raise RuntimeError(f"{case_id}: launcher PID missing")
    pid = int(pid_text)
    try:
        time.sleep(startup_seconds)
        collect(device, prefix, "pre")
        device.run(
            f"service=/mnt/plumos/bin/plumos-hardware-keys-service; "
            f"log=/mnt/plumos/logs/hardware-keys.log; "
            f"overlay=/mnt/plumos/logs/power-menu-overlay.log; "
            f"before=$(wc -l <\"$log\"); overlay_before=$(wc -l <\"$overlay\"); "
            f"$service stop >/dev/null; "
            f"PLUMOS_POWER_MENU_OVERLAY_UI=/tmp/rk2020-power-cancel-auto-select "
            f"$service start >/dev/null; "
            f"daemon=$(sed -n '1p' /run/plumos/hardware-keys/service.pid); "
            f"kill -USR1 \"$daemon\"; i=0; "
            f"while [ \"$i\" -lt 150 ]; do "
            f"  lines=$(wc -l <\"$log\"); "
            f"  if [ \"$lines\" -gt \"$before\" ] && "
            f"     sed -n \"$((before + 1)),${{lines}}p\" \"$log\" | "
            f"       grep -q 'display-owner=resume'; then break; fi; "
            f"  sleep 0.1; i=$((i + 1)); "
            f"done; "
            f"lines=$(wc -l <\"$log\"); "
            f"overlay_lines=$(wc -l <\"$overlay\"); "
            f"sed -n \"$((before + 1)),${{lines}}p\" \"$log\" >{prefix}.hardware.log; "
            f"sed -n \"$((overlay_before + 1)),${{overlay_lines}}p\" \"$overlay\" >{prefix}.overlay.log; "
            f"printf 'enabled=' >{prefix}.connector; "
            f"cat /sys/class/drm/card0-DSI-1/enabled >>{prefix}.connector; "
            f"printf 'dpms=' >>{prefix}.connector; "
            f"cat /sys/class/drm/card0-DSI-1/dpms >>{prefix}.connector; "
            f"$service restart >/dev/null",
            timeout=30,
        )
        time.sleep(2)
        collect(device, prefix, "post")
        copy_evidence(device, prefix, output)

        pre_ps = (output / f"{base}-pre.ps").read_text(errors="replace")
        post_ps = (output / f"{base}-post.ps").read_text(errors="replace")
        hardware = (output / f"{base}.hardware.log").read_text(errors="replace")
        overlay = (output / f"{base}.overlay.log").read_text(errors="replace")
        connector = (output / f"{base}.connector").read_text(errors="replace")
        pre_capture = media.analyze_capture(output, f"{base}-pre")
        post_capture = media.analyze_capture(output, f"{base}-post")
        pre_audio = [
            media.parse_audio((output / f"{base}-pre.audio{i}").read_text(errors="replace"))
            for i in (1, 2)
        ]
        post_audio = [
            media.parse_audio((output / f"{base}-post.audio{i}").read_text(errors="replace"))
            for i in (1, 2)
        ]
        owner_match = re.search(r"drm-output=snapshot owner=(\d+) rc=0", hardware)
        output_restore = bool(
            owner_match
            and f"drm-output=restore owner={owner_match.group(1)} rc=0" in hardware
        )
        checks = {
            "startup": bool(live_group(pre_ps, pid)),
            "scanout_before": active_scanout(pre_capture),
            "output_snapshot": owner_match is not None,
            "output_restore": output_restore,
            "handoff_complete": output_restore if owner_match else "drm-master=broker" not in hardware,
            "cancel_selected": "selection=cancel" in overlay,
            "connector_restored": "enabled=enabled" in connector and "dpms=On" in connector,
            "same_process_group": bool(live_group(post_ps, pid)),
            "scanout_after": active_scanout(post_capture),
        }
        required = (
            "startup",
            "scanout_before",
            "handoff_complete",
            "cancel_selected",
            "connector_restored",
            "same_process_group",
            "scanout_after",
        )
        return {
            "id": case_id,
            **case,
            "pid": pid,
            "checks": checks,
            "direct_drm_owner": owner_match is not None,
            "overall": "pass" if all(checks[name] for name in required) else "fail",
            "audio_before": audio_advances(*pre_audio),
            "audio_after": audio_advances(*post_audio),
            "hardware_log": hardware.rstrip(),
            "overlay_log": overlay.rstrip(),
            "connector": connector.rstrip(),
            "pre_capture": pre_capture,
            "post_capture": post_capture,
        }
    finally:
        media.stop_launch(device, pid, case["profile"])
        device.run(
            "/mnt/plumos/bin/plumos-hardware-keys-service restart >/dev/null 2>&1 || true",
            check=False,
        )


def write_report(path: Path, report: dict[str, Any]) -> None:
    lines = [
        "# RK2020 power-menu Cancel matrix",
        "",
        f"- generated: `{report['generated']}`",
        f"- device: `{report['device']}`",
        "",
        "| family | route | snapshot | restore | connector | process | scanout pre/post | audio pre/post | result |",
        "|---|---|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in report["results"]:
        checks = row["checks"]
        snapshot = "PASS" if checks["output_snapshot"] else "N/A"
        restore = "PASS" if checks["output_restore"] else "N/A"
        lines.append(
            f"| {row['family']} | `{row['profile']}` | "
            f"{snapshot} | {restore} | "
            f"{'PASS' if checks['connector_restored'] else 'FAIL'} | "
            f"{'PASS' if checks['same_process_group'] else 'FAIL'} | "
            f"{'PASS' if checks['scanout_before'] and checks['scanout_after'] else 'FAIL'} | "
            f"{'PASS' if row['audio_before'] and row['audio_after'] else 'N/A'} | "
            f"**{row['overall'].upper()}** |"
        )
    lines.extend(
        [
            "",
            "Scanout PASS means an active panel-sized DRM plane existed before and after Cancel.",
            "Legacy GPU framebuffer readback may be black, so it is not treated as pixel-color proof.",
            "Audio is supporting evidence only because some title/menu states are silent.",
            "Orientation, pixel correctness, audible quality, and physical button timing remain operator checks.",
        ]
    )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", required=True)
    parser.add_argument("--user", default="root")
    parser.add_argument("--password", default="")
    parser.add_argument("--cases", default=",".join(CASES))
    parser.add_argument("--startup-seconds", type=int, default=10)
    parser.add_argument(
        "--capture-tool",
        default="output/live/2026-10-26-rk2020-ppsspp-ui/drm-scanout-capture-legacy",
    )
    parser.add_argument("--output", default="")
    args = parser.parse_args()
    selected = [item.strip() for item in args.cases.split(",") if item.strip()]
    unknown = sorted(set(selected) - set(CASES))
    if unknown:
        parser.error("unknown cases: " + ", ".join(unknown))

    stamp = dt.datetime.now().strftime("%Y-%m-%d-%H%M%S")
    output = Path(args.output or f"output/validation/rk2020-power-cancel-{stamp}")
    output.mkdir(parents=True, exist_ok=True)
    device = media.Device(args.host, args.user, args.password)
    capture = Path(args.capture_tool)
    selector = ROOT / "scripts/rk2020-power-cancel-auto-select.sh"
    device.copy_to(capture, "/tmp/drm-scanout-capture")
    device.copy_to(selector, "/tmp/rk2020-power-cancel-auto-select")
    device.run(
        "chmod 0755 /tmp/drm-scanout-capture /tmp/rk2020-power-cancel-auto-select"
    )

    results = []
    try:
        for case_id in selected:
            print(f"[{case_id}] launch/power-menu/cancel", flush=True)
            row = run_case(device, output, case_id, CASES[case_id], args.startup_seconds)
            results.append(row)
            print(f"  result={row['overall']} checks={row['checks']}", flush=True)
    finally:
        device.run(
            "/mnt/plumos/bin/plumos-hardware-keys-service restart >/dev/null 2>&1 || true; "
            "/mnt/plumos/bin/plumos-frontend-stop stop >/dev/null 2>&1 || true; "
            "/mnt/plumos/bin/plumos-frontend-launch >/dev/null 2>&1 || true",
            check=False,
            timeout=20,
        )

    report = {
        "generated": dt.datetime.now(dt.timezone.utc).astimezone().isoformat(),
        "device": f"{args.user}@{args.host}",
        "results": results,
    }
    (output / "report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    write_report(output / "report.md", report)
    print(output / "report.md")
    return 1 if any(row["overall"] != "pass" for row in results) else 0


if __name__ == "__main__":
    raise SystemExit(main())
