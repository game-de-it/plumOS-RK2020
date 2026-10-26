#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
RA_CFG="$ROOT_DIR/package/retroarch-rk2020/retroarch.cfg"
RA_AUTOCONFIG="$ROOT_DIR/package/retroarch-rk2020/rk2020-joypad-udev.cfg"
RA_LAUNCHER="$ROOT_DIR/package/app-layer-rk2020/bin/plumos-retroarch-launch"
INPUT_ENV="$ROOT_DIR/package/app-layer-rk2020/config/system/input-map.env"
PICO_PATCH="$ROOT_DIR/docker/rk2020-tools/picoarch/picoarch-rk2020-input-aspect.patch"
PICO_POLL_PATCH="$ROOT_DIR/docker/rk2020-tools/picoarch/picoarch-rk2020-host-input-poll.patch"
PCSX_PATCH="$ROOT_DIR/patches/pcsx_rearmed/pcsx-rearmed-r26l-rk2020-evdev-menu.patch"
PCSX_PICOFE_PATCH="$ROOT_DIR/patches/pcsx_rearmed/libpicofe-r26l-rk2020-input.patch"
OPENBOR_PATCH="$ROOT_DIR/patches/openbor/openbor-v6391-rk2020-sdl.patch"
SA_BUILD="$ROOT_DIR/scripts/build-standalone-rk2020.sh"
SA_LAUNCHER="$ROOT_DIR/package/standalone-rk2020/plumos/bin/plumos-standalone-launch"
SA_STOP="$ROOT_DIR/package/standalone-rk2020/plumos/bin/plumos-standalone-stop"
PICO8_WGET="$ROOT_DIR/package/standalone-rk2020/plumos/standalone/pico8/bin/wget"
DRASTIC_RUNNER_PATCH="$ROOT_DIR/patches/drastic/steward-fu-nds-rk2020-runner-readiness.patch"
DRASTIC_ROTATION_PATCH="$ROOT_DIR/patches/drastic/steward-fu-nds-rk2020-runner-rotation.patch"
DRASTIC_MENU_PRESENT_PATCH="$ROOT_DIR/patches/drastic/steward-fu-nds-rk2020-menu-present.patch"
DRASTIC_RUNNER_ASPECT_PATCH="$ROOT_DIR/patches/drastic/steward-fu-nds-rk2020-runner-aspect.patch"
DRASTIC_INPUT_PATCH="$ROOT_DIR/patches/drastic/steward-fu-nds-rk2020-input.patch"
DRASTIC_TOUCH_MODE_PATCH="$ROOT_DIR/patches/drastic/steward-fu-nds-rk2020-touch-mode.patch"
DRASTIC_TOUCH_SPEED_PATCH="$ROOT_DIR/patches/drastic/steward-fu-nds-rk2020-touch-speed.patch"
DRASTIC_INPUT_DRAIN_PATCH="$ROOT_DIR/patches/drastic/steward-fu-nds-rk2020-input-drain.patch"
PPSSPP_CONTROLS="$ROOT_DIR/package/standalone-rk2020/plumos/factory-defaults/standalone/ppsspp/PSP/SYSTEM/controls.ini"
PPSSPP_CONFIG="$ROOT_DIR/package/standalone-rk2020/plumos/factory-defaults/standalone/ppsspp/PSP/SYSTEM/ppsspp.ini"
PPSSPP_CONTROLLER_PATCH="$ROOT_DIR/patches/ppsspp/ppsspp-1.20.4-rk2020-controller.patch"
PPSSPP_DISPLAY_PATCH="$ROOT_DIR/patches/ppsspp/ppsspp-1.20.4-rk2020-display-rotation.patch"
PICO8_SDL_ADAPTER="$ROOT_DIR/package/portmaster-rk2020/src/plumos_portmaster_sdl_rotate.c"
PICO8_DOWNLOAD_SHIM="$ROOT_DIR/package/standalone-rk2020/src/pico8-download-shim.c"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

grep -Fqx 'PLUMOS_INPUT_FUNCTION_CODE=706' "$INPUT_ENV" ||
    fail 'raw RK2020 L2/function code is not documented'
grep -Fqx 'PLUMOS_INPUT_FUNCTION_UDEV_BTN=12' "$INPUT_ENV" ||
    fail 'RetroArch compact L2/function index is not documented'
grep -Fqx 'PLUMOS_INPUT_VOLUME_MODIFIER_CODE=706' "$INPUT_ENV" ||
    fail 'RK2020 L2 volume modifier is not documented'
grep -Fqx 'PLUMOS_INPUT_L2_UDEV_BTN=12' "$INPUT_ENV" ||
    fail 'RetroArch compact L2 index is not documented'
grep -Fqx 'PLUMOS_INPUT_R2_UDEV_BTN=13' "$INPUT_ENV" ||
    fail 'RetroArch compact R2 index is not documented'

grep -Fqx 'input_enable_hotkey_btn = "10"' "$RA_CFG" ||
    fail 'RetroArch SELECT hotkey modifier is missing'
grep -Fqx 'input_menu_toggle_btn = "0"' "$RA_CFG" ||
    fail 'RetroArch persistent SELECT+B menu binding is missing'
grep -Fqx 'input_menu_toggle_btn = "0"' "$RA_AUTOCONFIG" ||
    fail 'RetroArch controller SELECT+B menu binding is missing'
if grep -Eq '^input_(enable_hotkey|exit_emulator)_btn[[:space:]]*=' "$RA_AUTOCONFIG"; then
    fail 'RetroArch global hotkey modifier must remain in the main config'
fi
grep -Fq 'PLUMOS_INPUT_B_UDEV_BTN:-0' "$RA_LAUNCHER" ||
    fail 'RetroArch launch append config does not enforce SELECT+B menu'

for binding in \
    'BTN_TRIGGER_HAPPY3, PBTN_MENU'; do
    grep -Fq "$binding" "$PICO_PATCH" ||
        fail "PicoArch FUNCTION menu binding missing: $binding"
done
if grep -Fq 'BTN_TRIGGER_HAPPY3, IN_BINDTYPE_EMU, EACTION_MENU' "$PICO_PATCH"; then
    fail 'PicoArch must preserve standalone L2 input during gameplay'
fi
for token in \
    'core_input_begin_frame();' \
    'core_input_finish_frame();' \
    'if (input_polled_this_frame)' \
    'RETRO_DEVICE_ID_JOYPAD_L2' \
    'RETRO_DEVICE_ID_JOYPAD_START' \
    'actions[IN_BINDTYPE_EMU] |= 1U << EACTION_MENU' \
    'Core omitted input_poll_cb; enabling frontend fallback polling'; do
    grep -Fq "$token" "$PICO_POLL_PATCH" ||
        fail "PicoArch host input fallback missing: $token"
done
grep -Fq 'picoarch-rk2020-host-input-poll.patch' \
    "$ROOT_DIR/scripts/build-picoarch-rk2020.sh" ||
    fail 'PicoArch host input fallback patch is not applied by the build'
grep -Fq 'apply_zero_context_once "$PATCH_DIR/picoarch-rk2020-host-input-poll.patch"' \
    "$ROOT_DIR/scripts/build-picoarch-rk2020.sh" ||
    fail 'PicoArch host input fallback must use the zero-context patch gate'
for binding in \
    'BTN_DPAD_UP,    IN_BINDTYPE_PLAYER12, RETRO_DEVICE_ID_JOYPAD_UP' \
    'BTN_DPAD_DOWN,  IN_BINDTYPE_PLAYER12, RETRO_DEVICE_ID_JOYPAD_DOWN' \
    'BTN_DPAD_LEFT,  IN_BINDTYPE_PLAYER12, RETRO_DEVICE_ID_JOYPAD_LEFT' \
    'BTN_DPAD_RIGHT, IN_BINDTYPE_PLAYER12, RETRO_DEVICE_ID_JOYPAD_RIGHT' \
    'BTN_DPAD_UP,    PBTN_UP' \
    'BTN_DPAD_DOWN,  PBTN_DOWN' \
    'BTN_DPAD_LEFT,  PBTN_LEFT' \
    'BTN_DPAD_RIGHT, PBTN_RIGHT'; do
    grep -Fq "$binding" "$PICO_PATCH" ||
        fail "PicoArch RK2020 physical D-pad binding missing: $binding"
done
for binding in \
    'BTN_TRIGGER_HAPPY1, IN_BINDTYPE_PLAYER12, RETRO_DEVICE_ID_JOYPAD_SELECT' \
    'BTN_TRIGGER_HAPPY3, IN_BINDTYPE_PLAYER12, RETRO_DEVICE_ID_JOYPAD_L2' \
    'BTN_TRIGGER_HAPPY4, IN_BINDTYPE_PLAYER12, RETRO_DEVICE_ID_JOYPAD_R2' \
    'BTN_TRIGGER_HAPPY6, IN_BINDTYPE_PLAYER12, RETRO_DEVICE_ID_JOYPAD_START'; do
    grep -Fq "$binding" "$PICO_PATCH" ||
        fail "PicoArch RK2020 raw special-button binding missing: $binding"
done
for stale_binding in \
    'BTN_SELECT, IN_BINDTYPE_PLAYER12' \
    'BTN_START,  IN_BINDTYPE_PLAYER12' \
    'BTN_TL2,    IN_BINDTYPE_PLAYER12' \
    'BTN_TR2,    IN_BINDTYPE_PLAYER12'; do
    if grep -Fq "$stale_binding" "$PICO_PATCH"; then
        fail "PicoArch retained non-RK2020 special-button mapping: $stale_binding"
    fi
done
if grep -Fq 'BTN_MODE' "$PICO_PATCH"; then
    fail 'PicoArch still treats RK2020 FUNCTION as BTN_MODE'
fi

for binding in \
    'in_evdev_init(&in_rk2020_evdev_platform_data)'; do
    grep -Fq "$binding" "$PCSX_PATCH" ||
        fail "PCSX-ReARMed RK2020 evdev contract missing: $binding"
done
for binding in \
    'BTN_DPAD_UP,        IN_BINDTYPE_PLAYER12, DKEY_UP' \
    'BTN_DPAD_DOWN,      IN_BINDTYPE_PLAYER12, DKEY_DOWN' \
    'BTN_DPAD_LEFT,      IN_BINDTYPE_PLAYER12, DKEY_LEFT' \
    'BTN_DPAD_RIGHT,     IN_BINDTYPE_PLAYER12, DKEY_RIGHT' \
    'BTN_DPAD_UP,        PBTN_UP' \
    'BTN_DPAD_DOWN,      PBTN_DOWN' \
    'BTN_DPAD_LEFT,      PBTN_LEFT' \
    'BTN_DPAD_RIGHT,     PBTN_RIGHT'; do
    grep -Fq "$binding" "$PCSX_PATCH" ||
        fail "PCSX-ReARMed physical D-pad contract missing: $binding"
done
for binding in \
    'BTN_SOUTH,          IN_BINDTYPE_PLAYER12, DKEY_CROSS' \
    'BTN_EAST,           IN_BINDTYPE_PLAYER12, DKEY_CIRCLE' \
    'BTN_NORTH,          IN_BINDTYPE_PLAYER12, DKEY_TRIANGLE' \
    'BTN_WEST,           IN_BINDTYPE_PLAYER12, DKEY_SQUARE' \
    'BTN_SOUTH,          PBTN_MOK' \
    'BTN_EAST,           PBTN_MBACK'; do
    grep -Fq "$binding" "$PCSX_PATCH" ||
        fail "PCSX-ReARMed saved global ABXY default missing: $binding"
done
if grep -Fq 'BTN_SOUTH,          IN_BINDTYPE_PLAYER12, DKEY_CIRCLE' "$PCSX_PATCH" ||
        grep -Fq 'BTN_EAST,           IN_BINDTYPE_PLAYER12, DKEY_CROSS' "$PCSX_PATCH"; then
    fail 'PCSX-ReARMed retained the pre-calibration A/B mapping'
fi
for binding in \
    'BTN_TRIGGER_HAPPY3, IN_BINDTYPE_PLAYER12, DKEY_L2' \
    'BTN_TRIGGER_HAPPY4, IN_BINDTYPE_PLAYER12, DKEY_R2' \
    'BTN_TRIGGER_HAPPY1, IN_BINDTYPE_PLAYER12, DKEY_SELECT' \
    'BTN_TRIGGER_HAPPY6, IN_BINDTYPE_PLAYER12, DKEY_START'; do
    grep -Fq "$binding" "$PCSX_PATCH" ||
        fail "PCSX-ReARMed RK2020 physical button binding missing: $binding"
done
for binding in \
    'BTN_TRIGGER_HAPPY3, IN_BINDTYPE_EMU, SACTION_ENTER_MENU' \
    'BTN_TRIGGER_HAPPY6, IN_BINDTYPE_EMU, SACTION_ENTER_MENU' \
    'BTN_TRIGGER_HAPPY3, PBTN_MENU'; do
    grep -Fq "$binding" "$PCSX_PATCH" ||
        fail "PCSX-ReARMed L2+START menu contract missing: $binding"
done
for binding in \
    'RK2020 controller input is owned by evdev' \
    'joycount = 0' \
    'KEYBITS_BIT(BTN_TRIGGER_HAPPY3)' \
    'KEYBITS_BIT(BTN_TRIGGER_HAPPY6)' \
    'result[IN_BINDTYPE_PLAYER12] &='; do
    grep -Fq "$binding" "$PCSX_PICOFE_PATCH" ||
        fail "PCSX-ReARMed single input path contract missing: $binding"
done

for binding in \
    'CONTROL_ESC                 (JOY_LIST_FIRST + 11)' \
    'CONTROL_DEFAULT1_UP         (JOY_LIST_FIRST + 7)' \
    'CONTROL_DEFAULT1_RIGHT      (JOY_LIST_FIRST + 10)' \
    'CONTROL_DEFAULT1_DOWN       (JOY_LIST_FIRST + 8)' \
    'CONTROL_DEFAULT1_LEFT       (JOY_LIST_FIRST + 9)' \
    'CONTROL_DEFAULT1_FIRE1      (JOY_LIST_FIRST + 2)' \
    'CONTROL_DEFAULT1_FIRE2      (JOY_LIST_FIRST + 3)' \
    'CONTROL_DEFAULT1_FIRE3      (JOY_LIST_FIRST + 4)' \
    'CONTROL_DEFAULT1_FIRE4      (JOY_LIST_FIRST + 5)' \
    'CONTROL_DEFAULT1_FIRE5      (JOY_LIST_FIRST + 1)' \
    'CONTROL_DEFAULT1_FIRE6      (JOY_LIST_FIRST + 6)' \
    'CONTROL_DEFAULT1_START      (JOY_LIST_FIRST + 16)' \
    'CONTROL_DEFAULT1_ESC        (JOY_LIST_FIRST + 11)'; do
    grep -Fq "$binding" "$OPENBOR_PATCH" ||
        fail "OpenBOR RK2020 controller contract missing: $binding"
done
for contract in \
    'savedata.keys[0][SDID_ATTACK] == JOY_LIST_FIRST + 2' \
    'savedata.keys[0][SDID_ATTACK2] == JOY_LIST_FIRST + 1' \
    'savedata.keys[0][SDID_JUMP] == JOY_LIST_FIRST + 5'; do
    grep -Fq "$contract" "$OPENBOR_PATCH" ||
        fail "OpenBOR previous RK2020 defaults migration missing: $contract"
done
for contract in \
    'Make the measured ABS_X/ABS_Y stick mirror the physical D-pad' \
    '0x01 << (JOY_AXIS_Y * 2)' \
    '0x02 << (JOY_AXIS_X * 2)' \
    'PLUMOS_OPENBOR_SDL_ROTATION' \
    'libplumos-openbor-sdl-rotate.so'; do
    grep -Fq "$contract" "$OPENBOR_PATCH" "$SA_BUILD" "$SA_LAUNCHER" ||
        fail "OpenBOR RK2020 display/input contract missing: $contract"
done
for contract in \
    'export PLUMOS_OPENBOR_SDL_ROTATION=270' \
    'export SDL_RENDER_DRIVER=opengles2' \
    'XDG_DATA_HOME}/${openbor_data}' \
    'openbor_rotation}${LD_PRELOAD'; do
    grep -Fq "$contract" "$SA_LAUNCHER" ||
        fail "OpenBOR launcher contract missing: $contract"
done

for contract in \
    'controls_b[CONTROL_INDEX_MENU] = 1154' \
    'controls_b[CONTROL_INDEX_MENU] = 1032'; do
    grep -Fq "$contract" "$SA_BUILD" ||
        fail "DraStic build menu migration missing: $contract"
    grep -Fq "$contract" "$SA_LAUNCHER" ||
        fail "DraStic live config migration missing: $contract"
done

grep -Fq 'kill -CONT "$runner_pid"' "$SA_LAUNCHER" ||
    fail 'DraStic cleanup must resume a power-overlay-stopped runner'
grep -Fq 'runner_stop_wait' "$SA_LAUNCHER" ||
    fail 'DraStic runner cleanup must remain bounded'

for contract in \
    'NDS_RUNNER_STARTUP_TIMEOUT_MS' \
    'NDS_RUNNER_READY_FILE' \
    'display_ready=first-frame' \
    'printf '\''%s\n'\'' "$loader" >"$exe_file"' \
    'DraStic display runner exited during emulation'; do
    grep -Fq "$contract" "$SA_LAUNCHER" ||
        fail "DraStic first-frame lifecycle contract missing: $contract"
done
for contract in \
    'startup_timeout_ms = 15000' \
    'NDS_RUNNER_READY_FILE' \
    'no frame from emulator after %ld ms'; do
    grep -Fq "$contract" "$DRASTIC_RUNNER_PATCH" ||
        fail "DraStic runner readiness patch missing: $contract"
done
if grep '^+' "$DRASTIC_RUNNER_PATCH" | grep -Fq 'pidof drastic'; then
    fail 'DraStic runner patch must not retain guessed pidof termination'
fi
grep -Fq 'DRASTIC_RUNNER_PATCH' "$SA_BUILD" ||
    fail 'DraStic build does not consume runner readiness patch'
for contract in \
    '#define DEV_KEY_CODE_L2         -1' \
    '#define DEV_KEY_CODE_R2         707' \
    '#define DEV_KEY_CODE_START      709' \
    '#define DEV_KEY_CODE_SELECT     704' \
    '#define DEV_KEY_CODE_MENU       706' \
    'got RK2020 analog stick axis event' \
    'handle_rk2020_stick_axis' \
    'one non-clickable analog stick as ABS_X/ABS_Y' \
    '#define RK2020_AXIS_PRESS_THRESHOLD   450' \
    '#define RK2020_AXIS_RELEASE_THRESHOLD 250' \
    'next = rk2020_axis_direction(e->value,' \
    'myconfig.hotkey = HOTKEY_BIND_MENU' \
    '#elif !defined(GKD_RK2020)'; do
    grep -Fq "$contract" "$DRASTIC_INPUT_PATCH" ||
        fail "DraStic RK2020 input contract missing: $contract"
done
grep -Fq 'DRASTIC_INPUT_PATCH' "$SA_BUILD" ||
    fail 'DraStic build does not consume RK2020 input patch'
grep -Fq 'input_patch_sha256' "$SA_BUILD" ||
    fail 'DraStic manifest does not record input patch'
for contract in \
    'hit_hotkey(KEY_BIT_X)' \
    'NDS_TOUCH_MODE : NDS_KEY_MODE' \
    'release_key();' \
    'RK2020 input mode=%s'; do
    grep -Fq "$contract" "$DRASTIC_TOUCH_MODE_PATCH" ||
        fail "DraStic RK2020 touch-mode contract missing: $contract"
done
grep -Fq 'DRASTIC_TOUCH_MODE_PATCH' "$SA_BUILD" ||
    fail 'DraStic build does not consume RK2020 touch-mode patch'
grep -Fq 'touch_mode_patch_sha256' "$SA_BUILD" ||
    fail 'DraStic manifest does not record touch-mode patch'
for contract in \
    '#if defined(GKD_RK2020)' \
    'move = (myconfig.pen.speed + 1) / 2;' \
    'move = (move + 2) / 3;' \
    'if (move < 1)'; do
    grep -Fq "$contract" "$DRASTIC_TOUCH_SPEED_PATCH" ||
        fail "DraStic RK2020 touch-speed contract missing: $contract"
done
grep -Fq 'DRASTIC_TOUCH_SPEED_PATCH' "$SA_BUILD" ||
    fail 'DraStic build does not consume RK2020 touch-speed patch'
grep -Fq 'touch_speed_patch_sha256' "$SA_BUILD" ||
    fail 'DraStic manifest does not record touch-speed patch'
for contract in \
    '#define RK2020_INPUT_DRAIN_MAX 64' \
    'drain_rk2020_input' \
    'read(fd, &e, sizeof(e)) == sizeof(e)' \
    'sleep_us = 1000;' \
    'changed = handle_rk2020_stick_axis(&e);'; do
    grep -Fq "$contract" "$DRASTIC_INPUT_DRAIN_PATCH" ||
        fail "DraStic RK2020 input-drain contract missing: $contract"
done
grep -Fq 'DRASTIC_INPUT_DRAIN_PATCH' "$SA_BUILD" ||
    fail 'DraStic build does not consume RK2020 input-drain patch'
grep -Fq 'input_drain_patch_sha256' "$SA_BUILD" ||
    fail 'DraStic manifest does not record input-drain patch'
for contract in \
    '#define R_DISPLAY_W 320' \
    '#define R_DISPLAY_H 480' \
    'vec4(-vert_tex_pos.y, vert_tex_pos.x' \
    'glViewport(0, 0, R_DISPLAY_W, R_DISPLAY_H)'; do
    grep -Fq "$contract" "$DRASTIC_ROTATION_PATCH" ||
        fail "DraStic RK2020 rotation patch missing: $contract"
done
grep -Fq 'DRASTIC_ROTATION_PATCH' "$SA_BUILD" ||
    fail 'DraStic build does not consume runner rotation patch'
grep -Fq 'runner_rotation_patch_sha256' "$SA_BUILD" ||
    fail 'DraStic manifest does not record runner rotation patch'
for contract in \
    'draw_cached_foreground' \
    'menu_active' \
    'menu_present_at = SDL_GetTicks() + 16' \
    'SDL_GL_SwapWindow(myrunner.sdl2.win)'; do
    grep -Fq "$contract" "$DRASTIC_MENU_PRESENT_PATCH" ||
        fail "DraStic RK2020 menu presentation patch missing: $contract"
done
grep -Fq 'DRASTIC_MENU_PRESENT_PATCH' "$SA_BUILD" ||
    fail 'DraStic build does not consume runner menu presentation patch'
grep -Fq 'runner_menu_present_patch_sha256' "$SA_BUILD" ||
    fail 'DraStic manifest does not record runner menu presentation patch'
for contract in \
    '#define R_VIEWPORT_Y 26' \
    '#define R_VIEWPORT_H 427' \
    'glViewport(R_VIEWPORT_X, R_VIEWPORT_Y, R_VIEWPORT_W, R_VIEWPORT_H)' \
    'glClear(GL_COLOR_BUFFER_BIT);'; do
    grep -Fq "$contract" "$DRASTIC_RUNNER_ASPECT_PATCH" ||
        fail "DraStic RK2020 aspect contract missing: $contract"
done
grep -Fq 'DRASTIC_RUNNER_ASPECT_PATCH' "$SA_BUILD" ||
    fail 'DraStic build does not consume runner aspect patch'
grep -Fq 'runner_aspect_patch_sha256' "$SA_BUILD" ||
    fail 'DraStic manifest does not record runner aspect patch'
grep -Fq 'readlink "/proc/${pid}/exe"' "$SA_STOP" ||
    fail 'standalone stop ownership check is missing'

for contract in \
    'pico8_machine' \
    '[ "$pico8_machine" = b700 ]' \
    'roms/pico-8' \
    'roms/pico8' \
    'PLUMOS_PICO8_SDL_ROTATION=270' \
    'SDL_RENDER_DRIVER=opengles2' \
    'PLUMOS_PICO8_PIXEL_PERFECT:-0' \
    'SDL_GAMECONTROLLERCONFIG=' \
    'dpup:b6,dpdown:b7,dpleft:b8,dpright:b9' \
    '-root_path "$pico8_system_root"' \
    '-pixel_perfect "$pico8_pixel_perfect"' \
    'PICO-8 HTTPS download adapter is missing' \
    'PICO-8 HTTPS command adapter is missing' \
    'libplumos-pico8-download.so' \
    'use_wget 1' \
    'export PATH="${EMU_ROOT}/pico8/bin:${PATH}"' \
    '-run "$rom"'; do
    grep -Fq -- "$contract" "$SA_LAUNCHER" ||
        fail "PICO-8 RK2020 launch contract missing: $contract"
done
for contract in \
    'strncmp(command, "wget ", 5)' \
    '/standalone/pico8/bin/wget%s' \
    'dlsym(RTLD_NEXT, "system")' \
    'PICO-8 download: using managed HTTPS adapter'; do
    grep -Fq -- "$contract" "$PICO8_DOWNLOAD_SHIM" ||
        fail "PICO-8 system command shim missing contract: $contract"
done
for contract in \
    '${PLUMOS_ROOT}/bin/curl' \
    '--fail --location --silent --show-error' \
    '--data-binary "@$post_file"' \
    'mv -f "$output_tmp" "$output"'; do
    grep -Fq -- "$contract" "$PICO8_WGET" ||
        fail "PICO-8 HTTPS download wrapper missing contract: $contract"
done
grep -Fq 'cleanup_pid="$(cat "$pid_file"' "$SA_LAUNCHER" ||
    fail 'standalone natural exit does not clean matching PID ownership files'
for contract in \
    'PICO8_SDL_ROTATE_SOURCE' \
    'PICO8_DOWNLOAD_SHIM_SOURCE' \
    'PLUMOS_SDL_ROTATION_ENV=' \
    'libplumos-pico8-sdl-rotate.so' \
    'binary_policy' \
    'external-proprietary'; do
    grep -Fq "$contract" "$SA_BUILD" ||
        fail "PICO-8 external runtime build contract missing: $contract"
done
for contract in \
    'PLUMOS_SDL_ROTATION_ENV' \
    'PLUMOS_SDL_ROTATION_LABEL'; do
    grep -Fq "$contract" "$PICO8_SDL_ADAPTER" ||
        fail "shared RK2020 SDL rotation adapter is not reusable: $contract"
done
grep -Fq '"${PLUMOS_USER_ROOT}/roms/pico-8/aarch64/"' "$SA_STOP" ||
    fail 'PICO-8 external runtime stop ownership is missing'
grep -Fq 'pico8_64|_pico8_64|pico8_dyn' "$SA_STOP" ||
    fail 'PICO-8 external runtime stop ownership is too broad'

grep -Eq '^Pause[[:space:]]*=.*(^|,)10-4(,|$)' "$PPSSPP_CONTROLS" ||
    fail 'PPSSPP factory FUNCTION pause binding is missing'
grep -Fq "s/$/,10-4/" "$SA_LAUNCHER" ||
    fail 'PPSSPP existing config migration is missing'
grep -Fqx 'UIScaleFactor = -6' "$PPSSPP_CONFIG" ||
    fail 'PPSSPP RK2020 readable UI scale is missing'
ppsspp_landscape_aspect="$(awk '
    /^\[DisplayLayout.Landscape\]$/ { in_section=1; next }
    /^\[/ && in_section { exit }
    in_section && /^DisplayAspectRatio = / { sub(/^.* = /, ""); print; exit }
' "$PPSSPP_CONFIG")"
[ "$ppsspp_landscape_aspect" = 0.562500 ] ||
    fail 'PPSSPP RK2020 landscape aspect correction is missing'
for contract in \
    'config_migration=rk2020-aspect-ui-v2' \
    'DisplayAspectRatio = 0.562500' \
    'UIScaleFactor = -6'; do
    grep -Fq "$contract" "$SA_LAUNCHER" ||
        fail "PPSSPP existing display config migration missing: $contract"
done
for contract in \
    'GO-Advance Gamepad,a:b1,b:b0,x:b2,y:b3' \
    'back:b10,guide:b12,start:b15' \
    'dpup:b6,dpdown:b7,dpleft:b8,dpright:b9' \
    'leftshoulder:b4,rightshoulder:b5,lefttrigger:b11,righttrigger:b14' \
    'leftx:a0,lefty:a1'; do
    grep -Fq "$contract" "$PPSSPP_CONTROLLER_PATCH" ||
        fail "PPSSPP RK2020 controller mapping missing: $contract"
done
grep -Fq 'PLUMOS_RK2020_DISPLAY_ROTATION' "$PPSSPP_DISPLAY_PATCH" ||
    fail 'PPSSPP RK2020 display presenter patch is missing'
for contract in \
    'PLUMOS_RK2020_DISPLAY_ROTATION=ccw' \
    'PLUMOS_RK2020_DISPLAY_LOGICAL=480x320' \
    'PLUMOS_RK2020_DISPLAY_FORCE_LANDSCAPE=1'; do
    grep -Fq "$contract" "$SA_LAUNCHER" ||
        fail "PPSSPP RK2020 display launch contract missing: $contract"
done
for patch_name in \
    ppsspp-1.20.4-rk2020-display-rotation.patch \
    ppsspp-1.20.4-rk2020-controller.patch; do
    grep -Fq "$patch_name" "$SA_BUILD" ||
        fail "PPSSPP build does not consume patch: $patch_name"
done

printf 'PASS: RK2020 emulator FUNCTION menu contract\n'
