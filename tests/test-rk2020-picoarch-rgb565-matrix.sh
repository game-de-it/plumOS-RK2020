#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
systems="$root/package/frontend-rk2020/systems.json"
matrix="$root/package/picoarch-rk2020/plumos/share/picoarch/rgb565-byte-order.tsv"
overrides="$root/package/picoarch-rk2020/plumos/share/picoarch/rgb565-route-overrides.tsv"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

jq -r '.systems[].launch_profiles[] | select(startswith("picoarch:")) |
  sub("^picoarch:"; "")' "$systems" | sort -u >"$tmp/routes"
awk -F '\t' '
  /^#/ { next }
  NF != 5 { exit 1 }
  $1 !~ /^[A-Za-z0-9._-]+$/ { exit 1 }
  $2 != "rgb565" && $2 != "xrgb8888" { exit 1 }
  $3 != "native" && $3 != "byteswap" { exit 1 }
  $2 == "xrgb8888" && $3 != "native" { exit 1 }
  $4 != "frontend" || $5 == "" { exit 1 }
  seen[$1]++ { exit 1 }
  { print $1 > routes }
  $3 == "byteswap" { print $1 > swaps }
  $2 == "xrgb8888" { print $1 > xrgb }
  END { if (length(seen) != 22) exit 1 }
' routes="$tmp/matrix-routes" swaps="$tmp/matrix-swaps" xrgb="$tmp/matrix-xrgb" "$matrix"
sort -o "$tmp/matrix-routes" "$tmp/matrix-routes"
sort -o "$tmp/matrix-swaps" "$tmp/matrix-swaps"
sort -o "$tmp/matrix-xrgb" "$tmp/matrix-xrgb"
cmp "$tmp/routes" "$tmp/matrix-routes"

cat >"$tmp/expected-swaps" <<'EOF'
gambatte
gearboy
gearsystem
genesis_plus_gx
mednafen_supafaust
mednafen_supergrafx
vbam
EOF
cmp "$tmp/expected-swaps" "$tmp/matrix-swaps"
cat >"$tmp/expected-xrgb" <<'EOF'
fceumm
nestopia
EOF
cmp "$tmp/expected-xrgb" "$tmp/matrix-xrgb"

jq -r '.systems[] as $system | $system.launch_profiles[] |
  select(. == "picoarch:picodrive") | [$system.id, "picodrive"] | @tsv' \
  "$systems" | sort -u >"$tmp/picodrive-routes"
awk -F '\t' '
  /^#/ { next }
  NF != 6 { exit 1 }
  $1 !~ /^[A-Za-z0-9._-]+$/ || $2 != "picodrive" { exit 1 }
  $3 != "rgb565" { exit 1 }
  $4 != "native" && $4 != "byteswap" { exit 1 }
  $5 != "frontend" || $6 == "" { exit 1 }
  seen[$1 FS $2]++ { exit 1 }
  { print $1 FS $2 > routes }
  END { if (length(seen) != 5) exit 1 }
' routes="$tmp/override-routes" "$overrides"
sort -o "$tmp/override-routes" "$tmp/override-routes"
cmp "$tmp/picodrive-routes" "$tmp/override-routes"
test "$(awk -F '\t' '$1 == "gamegear" && $4 == "byteswap" { n++ } END { print n + 0 }' "$overrides")" -eq 1
test "$(awk -F '\t' '$1 == "sega32x" && $4 == "byteswap" { n++ } END { print n + 0 }' "$overrides")" -eq 1
test "$(awk -F '\t' '$1 == "megadrive" && $4 == "byteswap" { n++ } END { print n + 0 }' "$overrides")" -eq 1
test "$(awk -F '\t' '!/^#/ && $4 == "byteswap" { n++ } END { print n + 0 }' "$overrides")" -eq 3

printf '%s\n' 'rk2020_picoarch_rgb565_matrix=result-ok routes=22 rgb565=20 core_byteswap=7 route_overrides=5 route_byteswap=3 xrgb8888=2'
