#!/usr/bin/env python3
"""Run a bounded representative launch for every RK2020 frontend system."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import time

REPO = Path(__file__).resolve().parents[1]
CATALOG = REPO / "package/frontend-rk2020/systems.json"
ROOT = "/mnt/plumos"
USER = "/mnt/plumos-user"
LIBRARY = f"{ROOT}/state/frontend/library-index.json"
VALIDATION = f"{USER}/.plumos-validation/rk2020-system-matrix"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="192.168.10.110")
    parser.add_argument("--user", default="root")
    parser.add_argument("--password-env", default="PLUMOS_SSH_PASSWORD")
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--execute", action="store_true")
    parser.add_argument("--only-system", action="append", default=[])
    parser.add_argument("--frames", type=int, default=240)
    return parser.parse_args()


class Device:
    def __init__(self, host: str, user: str, password: str):
        self.base = [
            "sshpass", "-p", password, "ssh", "-q",
            "-o", "ConnectTimeout=8", "-o", "NumberOfPasswordPrompts=1",
            "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null",
            f"{user}@{host}",
        ]

    def run(self, command: str, *, input_text: str | None = None,
            check: bool = True) -> subprocess.CompletedProcess[str]:
        result = subprocess.run(
            [*self.base, command], input=input_text, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, errors="replace",
        )
        if check and result.returncode:
            raise RuntimeError(
                f"device command failed ({result.returncode}): {result.stderr.strip()}"
            )
        return result

    def json_file(self, path: str) -> dict:
        return json.loads(self.run(f"cat {shlex.quote(path)}").stdout)


def launch_log(profile: str, system_id: str) -> str:
    if profile.startswith("retroarch:"):
        return f"{ROOT}/logs/retroarch-launch.log"
    if profile.startswith("pyxel:"):
        return f"{ROOT}/logs/pyxel/runtime.log"
    emulator = profile.split(":", 1)[1]
    names = {
        "ppsspp": "ppsspp-standalone.log",
        "drastic": "drastic-standalone.log",
        "pico8": "pico8-standalone.log",
        "openbor": "openbor-standalone.log",
        "mupen64plus": "mupen64plus-standalone.log",
        "pcsx_rearmed": "pcsx-rearmed-standalone.log",
    }
    return f"{ROOT}/logs/{names.get(emulator, f'standalone-{system_id}.log')}"


def renderer_expectation(profile: str) -> str:
    route = profile.split(":", 1)[1]
    if route in {
        "parallel_n64", "flycast", "flycast_xtreme",
        "km_duckswanstation_xtreme_amped", "ppsspp", "openbor",
    } or profile.startswith("pyxel:"):
        return "mali_required"
    return "no_software_gl"


def plan_command(device: Device, system_id: str, relative_path: str,
                 profile: str) -> tuple[str | None, str]:
    command = " ".join([
        f"PLUMOS_ROOT={ROOT}", f"PLUMOS_SDCARD_ROOT={USER}",
        shlex.quote(f"{ROOT}/bin/plumos-text-ui"), "launch",
        shlex.quote(system_id), shlex.quote(relative_path), "--profile",
        shlex.quote(profile), "--no-scan",
    ])
    result = device.run(command, check=False)
    if result.returncode:
        return None, (result.stderr or result.stdout).strip()
    match = re.search(r"^command: (.+)$", result.stdout, re.MULTILINE)
    return (match.group(1), "") if match else (None, "launch_plan_has_no_command")


SETUP = r'''
set -eu
R=/mnt/plumos
U=/mnt/plumos-user
RUN=$1
BASE=$U/.plumos-validation/rk2020-system-matrix/$RUN
mkdir -p "$BASE/sandbox" "$BASE/screenshots" /run/plumos/validation
if test -r /run/plumos/volume/current; then
    cat /run/plumos/volume/current > /run/plumos/validation/matrix-volume-before
else
    printf '%s\n' 0 > /run/plumos/validation/matrix-volume-before
fi
/bin/busybox sh "$R/bin/plumos-volume-control" apply 0 >/dev/null 2>&1
/bin/busybox sh "$R/bin/plumos-frontend-stop" stop >/dev/null 2>&1 || true
for rel in config/retroarch config/standalone state/retroarch state/picoarch state/standalone state/pyxel saves states; do
    src=$BASE/sandbox/$rel
    dst=$R/$rel
    mkdir -p "$src" "$dst"
    case "$rel" in config/*) cp -a "$dst/." "$src/" 2>/dev/null || true ;; esac
done
for rel in config/retroarch config/standalone state/retroarch state/picoarch state/standalone state/pyxel saves states; do
    mount --bind "$BASE/sandbox/$rel" "$R/$rel"
done
'''


TEARDOWN = r'''
set -u
R=/mnt/plumos
for p in /proc/[0-9]*; do
    for f in "$p"/fd/*; do
        target=$(readlink "$f" 2>/dev/null || true)
        case "$target" in /dev/dri/card0|/dev/fb0) kill -TERM "${p##*/}" 2>/dev/null || true; break ;; esac
    done
done
sleep 1
for mutable_dir in unzip_cache system savestates profiles input_record config backup; do
    dst="$R/standalone/drastic/$mutable_dir"
    while grep -Fq " $dst " /proc/mounts; do umount "$dst" 2>/dev/null || break; done
done
for dst in "$R/states" "$R/saves" "$R/state/pyxel" "$R/state/standalone" "$R/state/picoarch" "$R/state/retroarch" "$R/config/standalone" "$R/config/retroarch"; do
    while grep -Fq " $dst " /proc/mounts; do umount "$dst" 2>/dev/null || break; done
done
volume_before=$(cat /run/plumos/validation/matrix-volume-before 2>/dev/null || printf '%s\n' 0)
rm -f /run/plumos/validation/matrix-volume-before
/bin/busybox sh "$R/bin/plumos-volume-control" apply "$volume_before" >/dev/null 2>&1 || true
/bin/busybox sh "$R/bin/plumos-frontend-launch" >/dev/null 2>&1 || true
'''


RUN_ROUTE = r'''
set -u
CMD=$1
RLOG=$2
LIMIT=$3
WRAP=$4
SHOT=$5
before=0
test -f "$RLOG" && before=$(wc -c < "$RLOG")
/bin/busybox setsid /bin/busybox sh -c "$CMD" >"$WRAP" 2>&1 &
pid=$!
alive=no
display=""
audio=""
mali=""
software_gl=""
pcm_states=""
pcm_progress=no
previous_hw=""
sample=0
while test "$sample" -lt "$LIMIT"; do
    /bin/busybox usleep 250000
    kill -0 "$pid" 2>/dev/null && alive=yes
    for p in /proc/[0-9]*; do
        test -d "$p/fd" || continue
        test "$(/bin/busybox awk '{print $5}' "$p/stat" 2>/dev/null)" = "$pid" || continue
        for f in "$p"/fd/*; do
            target=$(readlink "$f" 2>/dev/null || true)
            case "$target" in /dev/dri/card0|/dev/fb0) display="$display${p##*/}," ;; esac
            case "$target" in /dev/snd/pcmC*D*p) audio="$audio${p##*/}," ;; esac
        done
        if test -r "$p/maps"; then
            grep -qi libmali "$p/maps" 2>/dev/null && mali="$mali${p##*/},"
            grep -Eq 'kms_swrast|swrast_dri|libLLVM' "$p/maps" 2>/dev/null && software_gl="$software_gl${p##*/},"
        fi
    done
    state=$(sed -n 's/^state: //p' /proc/asound/card0/pcm0p/sub0/status 2>/dev/null || true)
    hw=$(sed -n 's/^hw_ptr[[:space:]]*:[[:space:]]*//p' /proc/asound/card0/pcm0p/sub0/status 2>/dev/null || true)
    pcm_states="$pcm_states,${state:-closed}"
    test -n "$previous_hw" && test -n "$hw" && test "$hw" != "$previous_hw" && pcm_progress=yes
    previous_hw=$hw
    sample=$((sample + 1))
    kill -0 "$pid" 2>/dev/null || break
done
if kill -0 "$pid" 2>/dev/null; then
    kill -TERM "$pid" 2>/dev/null || true
    n=0
    while kill -0 "$pid" 2>/dev/null && test "$n" -lt 40; do
        /bin/busybox usleep 100000
        n=$((n + 1))
    done
    kill -0 "$pid" 2>/dev/null && kill -TERM "-$pid" 2>/dev/null || true
fi
wait "$pid" 2>/dev/null
rc=$?
shot=no
test -n "$SHOT" && test -s "$SHOT" && shot=yes
printf '__META__ alive=%s display=%s audio=%s mali=%s software_gl=%s pcm_states=%s pcm_progress=%s rc=%s screenshot=%s\n' \
    "$alive" "${display:-none}" "${audio:-none}" "${mali:-none}" "${software_gl:-none}" \
    "$pcm_states" "$pcm_progress" "$rc" "$shot"
printf '__RUNTIME_LOG__\n'
test -f "$RLOG" && tail -c +$((before + 1)) "$RLOG" | tail -160
printf '__WRAPPER_LOG__\n'
tail -100 "$WRAP" 2>/dev/null || true
'''


def parse_meta(output: str) -> dict[str, str]:
    line = next((line for line in output.splitlines() if line.startswith("__META__ ")), "")
    return dict(re.findall(
        r"(alive|display|audio|mali|software_gl|pcm_states|pcm_progress|rc|screenshot)=([^ ]*)",
        line,
    ))


def main() -> int:
    args = parse_args()
    if args.frames < 1 or args.frames > 3600:
        raise SystemExit("--frames must be between 1 and 3600")
    password = os.environ.get(args.password_env)
    if not password:
        raise SystemExit(f"set {args.password_env}")
    device = Device(args.host, args.user, password)
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    library = device.json_file(LIBRARY)
    live = {entry["id"]: entry for entry in library.get("systems", [])}
    run_id = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    records = []
    for system in catalog["systems"]:
        if system.get("enabled") is False:
            continue
        sid = system["id"]
        if args.only_system and sid not in args.only_system:
            continue
        profile = system.get("default_launch_profile", "")
        roms = live.get(sid, {}).get("roms", [])
        record = {
            "system": sid, "profile": profile, "status": "not_run",
            "content": None, "relative_path": None, "reason": None,
        }
        if not roms:
            record["reason"] = "no_representative_content"
        elif profile.startswith("external:"):
            record["reason"] = "external_port_is_separate_acceptance_gate"
        else:
            rom = roms[0]
            record["content"] = rom["path"]
            record["relative_path"] = rom["relative_path"]
            command, error = plan_command(device, sid, rom["relative_path"], profile)
            if command:
                shot = (
                    f"{VALIDATION}/{run_id}/screenshots/{sid}.png"
                    if profile.startswith("retroarch:") else ""
                )
                if shot:
                    command = (
                        f"PLUMOS_RETROARCH_VALIDATION_MAX_FRAMES={args.frames} "
                        f"PLUMOS_RETROARCH_VALIDATION_SCREENSHOT={shlex.quote(shot)} "
                        + command
                    )
                record.update({
                    "status": "planned", "command": command,
                    "runtime_log": launch_log(profile, sid),
                    "screenshot": shot or None,
                    "renderer_expectation": renderer_expectation(profile),
                })
            else:
                record["reason"] = f"launch_plan_failed: {error}"
        records.append(record)

    report = {
        "schema": 1, "device": "RK2020", "run_id": run_id,
        "catalog_enabled_systems": sum(
            system.get("enabled") is not False for system in catalog["systems"]
        ),
        "library_content_systems": len(live), "frames": args.frames,
        "records": records,
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    if not args.execute:
        print(
            f"planned={sum(r['status'] == 'planned' for r in records)} "
            f"not_run={sum(r['status'] == 'not_run' for r in records)} report={args.report}"
        )
        return 0

    planned = [record for record in records if record["status"] == "planned"]
    device.run(f"/bin/sh -s -- {shlex.quote(run_id)}", input_text=SETUP)
    try:
        for index, record in enumerate(planned, 1):
            safe = re.sub(r"[^A-Za-z0-9_.-]", "_", record["system"])
            wrap = f"{VALIDATION}/{run_id}/{safe}.wrapper.log"
            samples = 60 if record["profile"].startswith("retroarch:") else 40
            remote = "/bin/sh -s -- " + " ".join(
                shlex.quote(str(value)) for value in (
                    record["command"], record["runtime_log"], samples, wrap,
                    record.get("screenshot") or "",
                )
            )
            started = time.monotonic()
            result = device.run(remote, input_text=RUN_ROUTE, check=False)
            output = result.stdout + ("\n" + result.stderr if result.stderr else "")
            meta = parse_meta(output)
            runtime = (
                output.split("__RUNTIME_LOG__\n", 1)[-1].split("__WRAPPER_LOG__\n", 1)[0]
                if "__RUNTIME_LOG__\n" in output else ""
            )
            wrapper = output.split("__WRAPPER_LOG__\n", 1)[-1] if "__WRAPPER_LOG__\n" in output else ""
            screenshot_required = record["profile"].startswith("retroarch:")
            screenshot_ok = meta.get("screenshot") == "yes" if screenshot_required else True
            alive = meta.get("alive") == "yes"
            display = meta.get("display") not in {None, "", "none"}
            software_gl = meta.get("software_gl") not in {None, "", "none"}
            mali = meta.get("mali") not in {None, "", "none"}
            mali_ok = record["renderer_expectation"] != "mali_required" or mali
            rc_ok = meta.get("rc") in {"0", "137", "143"}
            record.update({
                "probe": meta, "runtime_log_delta": runtime[-20000:],
                "wrapper_log_delta": wrapper[-10000:],
                "elapsed_seconds": round(time.monotonic() - started, 2),
                "renderer_contract": (
                    "software_gl_loaded" if software_gl else
                    "required_mali_missing" if not mali_ok else
                    "mali_loaded" if mali else "no_software_gl_loaded"
                ),
                "audio_contract": (
                    "pcm_running_progress" if meta.get("pcm_progress") == "yes" else
                    "pcm_running_observed" if "RUNNING" in meta.get("pcm_states", "") else
                    "not_observed"
                ),
            })
            record["status"] = (
                "started" if alive and display and not software_gl and mali_ok and rc_ok and screenshot_ok
                else "failed"
            )
            if record["status"] == "failed":
                failed = []
                if not alive: failed.append("not_alive_during_probe")
                if not display: failed.append("no_display_owner")
                if software_gl: failed.append("software_gl_loaded")
                if not mali_ok: failed.append("required_mali_missing")
                if not rc_ok: failed.append(f"route_exit_{meta.get('rc', 'unknown')}")
                if not screenshot_ok: failed.append("screenshot_missing")
                record["reason"] = ",".join(failed)
            print(
                f"[{index:02d}/{len(planned):02d}] {record['system']} "
                f"status={record['status']} display={meta.get('display', '?')} "
                f"audio={record['audio_contract']} screenshot={meta.get('screenshot', '-')}",
                flush=True,
            )
            args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    finally:
        device.run("/bin/sh -s", input_text=TEARDOWN, check=False)

    report["completed_at"] = dt.datetime.now(dt.timezone.utc).isoformat()
    report["summary"] = {
        key: sum(record["status"] == key for record in records)
        for key in ("started", "failed", "not_run")
    }
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(report["summary"], sort_keys=True))
    return 1 if report["summary"]["failed"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
