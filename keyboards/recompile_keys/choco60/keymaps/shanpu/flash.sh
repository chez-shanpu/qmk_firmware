#!/usr/bin/env bash
# Flash the Choco60 rev1 (Pro Micro / Caterina) on macOS.
#
# Usage: flash.sh [hex]
#   Run this, then double-tap the RST button (or press QK_BOOT).
#   Retries each time the bootloader shows up until TIMEOUT seconds pass.

set -u

repo_root=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
hex=${1:-$repo_root/recompile_keys_choco60_rev1_shanpu.hex}
timeout=${TIMEOUT:-120}
toolbox_res="/Applications/QMK Toolbox.app/Contents/Resources"

if [ ! -f "$hex" ]; then
    echo "hex not found: $hex" >&2
    echo "build it first: SKIP_FLASHING_SUPPORT=1 util/docker_build.sh recompile_keys/choco60/rev1:shanpu" >&2
    exit 1
fi

# Prefer avrdude on PATH; fall back to the one bundled with QMK Toolbox (x86_64, needs Rosetta 2)
if command -v avrdude >/dev/null 2>&1; then
    avrdude=(avrdude)
elif [ -x "$toolbox_res/avrdude" ]; then
    avrdude=("$toolbox_res/avrdude" -C "$toolbox_res/avrdude.conf")
else
    echo "avrdude not found: brew install avrdude" >&2
    exit 1
fi

find_port() {
    ls /dev/cu.usbmodem* 2>/dev/null | head -1
}

echo "Waiting for bootloader (${timeout}s). Double-tap RST now."
end=$(($(date +%s) + timeout))
while [ "$(date +%s)" -lt "$end" ]; do
    port=$(find_port)
    if [ -z "$port" ]; then
        sleep 0.2
        continue
    fi

    # Connecting right after the port appears fails with "Device not configured"
    sleep 1
    if [ ! -e "$port" ]; then
        echo "port vanished: $port"
        continue
    fi

    echo "flashing via $port"
    if "${avrdude[@]}" -p atmega32u4 -c avr109 -P "$port" -U "flash:w:$hex:i"; then
        echo "done"
        exit 0
    fi

    echo "flash failed; double-tap RST again"
    while [ -e "$port" ]; do
        sleep 0.2
    done
done

echo "timeout: bootloader not detected" >&2
exit 1
