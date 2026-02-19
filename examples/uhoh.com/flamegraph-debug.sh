#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

if ! command -v perf >/dev/null 2>&1; then
    echo "error: 'perf' is not installed"
    echo "install on Arch: sudo pacman -S perf"
    exit 1
fi

if ! command -v speedscope >/dev/null 2>&1 && ! command -v npx >/dev/null 2>&1; then
    echo "error: speedscope is not available"
    echo "install Node/npm (for npx) or install speedscope globally"
    exit 1
fi

out_dir="$script_dir/.zig-cache/flamegraph"
mkdir -p "$out_dir"

timestamp="$(date +%Y%m%d-%H%M%S)"
perf_data="$out_dir/perf-$timestamp.data"
perf_script="$out_dir/perf-$timestamp.script"
folded="$out_dir/perf-$timestamp.folded"
svg="$out_dir/flamegraph-$timestamp.svg"

echo "Building debug executable..."
zig build -Doptimize=Debug

exe="$script_dir/zig-out/bin/uhoh.com"
if [[ ! -x "$exe" ]]; then
    echo "error: executable not found at '$exe'"
    exit 1
fi

echo "Recording profile with perf..."
echo "Close the app window to finish recording."
perf record -F 999 -g --call-graph dwarf -o "$perf_data" -- "$exe"

echo "Generating profile artifacts..."
perf script -i "$perf_data" > "$perf_script"
if command -v inferno-collapse-perf >/dev/null 2>&1 && command -v inferno-flamegraph >/dev/null 2>&1; then
    inferno-collapse-perf "$perf_script" > "$folded"
    inferno-flamegraph "$folded" > "$svg"
    echo "Also generated SVG flamegraph: $svg"
fi

echo "Opening in speedscope..."
if command -v speedscope >/dev/null 2>&1; then
    speedscope "$perf_script"
else
    npx --yes speedscope "$perf_script"
fi

echo "Done."
