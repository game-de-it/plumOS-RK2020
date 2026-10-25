#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
IMAGE="${PLUMOS_RK2020_TOOLS_IMAGE:-plumos-rk2020-tools:dev}"

usage() {
    printf '%s\n' \
        'Usage: scripts/docker-build.sh TARGET [ARGS...]' \
        '' \
        'Targets: image kernel-modules frontend retroarch cores core-catalog picoarch standalone audio-router pyxel-runtime nextcommander music-player network-services portmaster shared-apps app-layer audit update-package system-rootfs sd-image release-image'
}

if [ "${1:-}" = --inside ]; then
    shift
    target=${1:-}
    [ -n "$target" ] || { usage >&2; exit 2; }
    shift
    case "$target" in
        kernel-modules) exec ./scripts/build-rtl8821cu-rk2020.sh --inside "$@" ;;
        frontend) exec ./scripts/build-frontend-component.sh --inside "$@" ;;
        retroarch) exec ./scripts/build-retroarch.sh --inside "$@" ;;
        cores) exec ./scripts/build-libretro-cores.sh --inside "$@" ;;
        core-catalog) exec ./scripts/build-libretro-core-catalog-rk2020.sh "$@" ;;
        picoarch) exec ./scripts/build-picoarch-rk2020.sh --inside "$@" ;;
        standalone) exec ./scripts/build-standalone-rk2020.sh --inside "$@" ;;
        audio-router) exec ./scripts/build-audio-router-rk2020.sh "$@" ;;
        pyxel-runtime) exec ./scripts/build-pyxel-runtime-rk2020.sh --inside "$@" ;;
        nextcommander) exec ./scripts/build-nextcommander-rk2020.sh "$@" ;;
        music-player) exec ./scripts/build-music-player-rk2020.sh "$@" ;;
        network-services) exec ./scripts/build-network-services-rk2020.sh "$@" ;;
        portmaster) exec ./scripts/build-portmaster-rk2020.sh "$@" ;;
        shared-apps)
            pids=()
            ./scripts/build-nextcommander-rk2020.sh "$@" & pids+=("$!")
            ./scripts/build-music-player-rk2020.sh "$@" & pids+=("$!")
            ./scripts/build-network-services-rk2020.sh "$@" & pids+=("$!")
            ./scripts/build-portmaster-rk2020.sh "$@" & pids+=("$!")
            rc=0
            for pid in "${pids[@]}"; do wait "$pid" || rc=1; done
            exit "$rc"
            ;;
        app-layer) exec ./scripts/build-app-layer.sh --inside "$@" ;;
        audit) exec ./scripts/audit-rk2020-implementation.py "$@" ;;
        update-package) exec ./scripts/build-rk2020-update-package.py "$@" ;;
        system-rootfs) exec ./scripts/build-system-rootfs.sh --inside "$@" ;;
        sd-image) exec ./scripts/build-sd-image.sh --inside "$@" ;;
        release-image)
            ./scripts/build-rtl8821cu-rk2020.sh --inside
            ./scripts/build-frontend-component.sh --inside
            ./scripts/build-retroarch.sh --inside
            ./scripts/build-libretro-core-catalog-rk2020.sh --filter all
            ./scripts/build-picoarch-rk2020.sh --inside
            ./scripts/build-standalone-rk2020.sh --inside
            ./scripts/build-audio-router-rk2020.sh
            ./scripts/build-pyxel-runtime-rk2020.sh --inside
            pids=()
            ./scripts/build-nextcommander-rk2020.sh & pids+=("$!")
            ./scripts/build-music-player-rk2020.sh & pids+=("$!")
            ./scripts/build-network-services-rk2020.sh & pids+=("$!")
            ./scripts/build-portmaster-rk2020.sh & pids+=("$!")
            rc=0
            for pid in "${pids[@]}"; do wait "$pid" || rc=1; done
            [ "$rc" -eq 0 ] || exit "$rc"
            ./scripts/build-app-layer.sh --inside --strict
            ./scripts/audit-rk2020-implementation.py --release-gate
            ./scripts/build-system-rootfs.sh --inside
            exec ./scripts/build-sd-image.sh --inside
            ;;
        *) printf 'error: unknown target: %s\n' "$target" >&2; exit 2 ;;
    esac
fi

target=${1:-}
[ -n "$target" ] || { usage >&2; exit 2; }
if [ "$target" = image ]; then
    exec docker build --platform linux/arm64 -t "$IMAGE" "$ROOT_DIR/docker/rk2020-tools"
fi
docker image inspect "$IMAGE" >/dev/null 2>&1 || "$ROOT_DIR/scripts/build-tools-image.sh"
host_boot_prefix="${PLUMOS_RK2020_BOOT_PREFIX:-$ROOT_DIR/artifacts/vendor/rk2020-stock-source/rockchip-boot-prefix.bin}"
host_boot_prefix="$(CDPATH= cd -- "$(dirname -- "$host_boot_prefix")" && pwd)/$(basename -- "$host_boot_prefix")"
case "$host_boot_prefix" in
    "$ROOT_DIR"/*) container_boot_prefix="/work/${host_boot_prefix#"$ROOT_DIR"/}" ;;
    *) printf 'error: boot prefix must be under the repository\n' >&2; exit 2 ;;
esac
docker_env=(
    -e "PLUMOS_RK2020_VERSION=${PLUMOS_RK2020_VERSION:-0.1.0-dev}"
    -e "PLUMOS_RK2020_BOOT_PREFIX=$container_boot_prefix"
)
kernel_cache_volume="${PLUMOS_RK2020_KERNEL_CACHE_VOLUME:-plumos-rk2020-kernel-cache}"
if [ -n "${SOURCE_DATE_EPOCH:-}" ]; then
    docker_env+=(-e "SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH")
fi
container="$(
    docker create --platform linux/arm64 \
    "${docker_env[@]}" \
    -v "$kernel_cache_volume:/plumos-kernel-cache" \
    -v "$ROOT_DIR:/work" -w /work "$IMAGE" \
    ./scripts/docker-build.sh --inside "$@"
)"
cleanup_container() {
    [ -n "${container:-}" ] || return 0
    docker rm -f "$container" >/dev/null 2>&1 || true
}
trap cleanup_container INT TERM HUP
docker start "$container" >/dev/null
docker logs -f "$container"
rc="$(docker wait "$container")"
docker rm "$container" >/dev/null 2>&1 || true
trap - INT TERM HUP
exit "$rc"
