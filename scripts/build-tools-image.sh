#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
IMAGE="${PLUMOS_RK2020_TOOLS_IMAGE:-plumos-rk2020-tools:dev}"

docker build \
    --platform "${PLUMOS_RK2020_TOOLS_PLATFORM:-linux/arm64}" \
    -t "$IMAGE" \
    -f "$ROOT_DIR/docker/rk2020-tools/Dockerfile" \
    "$ROOT_DIR"

