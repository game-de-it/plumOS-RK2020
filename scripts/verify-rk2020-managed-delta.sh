#!/bin/sh
set -eu

usage() {
    printf 'usage: %s ROOT COMPONENT PATH...\n' "$0" >&2
    exit 2
}

[ "$#" -ge 3 ] || usage

root=$1
component=$2
shift 2

[ -d "$root" ] || { printf 'delta-verify: missing root: %s\n' "$root" >&2; exit 1; }
component_index="components/$component/checksums.sha256"
component_manifest="components/$component/manifest.json"
license_manifest="licenses/component-manifests/$component.json"
root_index=checksums.sha256

for required in "$component_index" "$component_manifest" "$license_manifest" "$root_index"; do
    [ -f "$root/$required" ] || {
        printf 'delta-verify: missing managed file: %s\n' "$required" >&2
        exit 1
    }
done

checksum_for() {
    index=$1
    managed_file=$2
    awk -v managed_file="$managed_file" '
        substr($0, 67) == managed_file { print substr($0, 1, 64); count++ }
        END { if (count != 1) exit 1 }
    ' "$index"
}

verify_entry() {
    index=$1
    managed_file=$2
    expected=$(checksum_for "$index" "$managed_file") || {
        printf 'delta-verify: missing or duplicate entry: %s in %s\n' \
            "$managed_file" "${index#$root/}" >&2
        exit 1
    }
    [ -f "$root/$managed_file" ] || {
        printf 'delta-verify: missing target: %s\n' "$managed_file" >&2
        exit 1
    }
    actual=$(sha256sum "$root/$managed_file" | awk '{print $1}')
    [ "$actual" = "$expected" ] || {
        printf 'delta-verify: checksum mismatch: %s\n' "$managed_file" >&2
        exit 1
    }
}

for managed_file in "$@"; do
    case "$managed_file" in
        /*|*../*|../*|*/..|..)
            printf 'delta-verify: unsafe path: %s\n' "$managed_file" >&2
            exit 1
            ;;
    esac
    if [ "$managed_file" != "$root_index" ]; then
        verify_entry "$root/$root_index" "$managed_file"
    fi
    if checksum_for "$root/$component_index" "$managed_file" >/dev/null 2>&1; then
        verify_entry "$root/$component_index" "$managed_file"
    fi
done

# The root index intentionally has no self-referential hash. Validate its
# records and uniqueness instead; the deployment bundle verifies its file hash.
awk '
    length($0) < 67 || substr($0, 65, 2) != "  " { exit 1 }
    substr($0, 1, 64) !~ /^[0-9a-f]+$/ { exit 1 }
    { managed_file = substr($0, 67); if (!managed_file || seen[managed_file]++) exit 1 }
' "$root/$root_index" || {
    printf 'delta-verify: malformed or duplicate root checksum entry\n' >&2
    exit 1
}

# Verify the metadata chain that makes a component delta boot-safe without
# scanning every unrelated payload file.
verify_entry "$root/$root_index" "$component_index"
verify_entry "$root/$root_index" "$component_manifest"
verify_entry "$root/$root_index" "$license_manifest"
cmp -s "$root/$component_manifest" "$root/$license_manifest" || {
    printf 'delta-verify: component license manifest drift: %s\n' "$component" >&2
    exit 1
}

printf 'delta-verify: PASS component=%s files=%s\n' "$component" "$#"
