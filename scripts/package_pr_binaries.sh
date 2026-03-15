#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="${1:-"$repo_root/dist/pr-binaries"}"
platform="$(uname -s | tr '[:upper:]' '[:lower:]')"
architecture="$(uname -m | tr '[:upper:]' '[:lower:]')"

package_binary() {
    local build_directory="$1"
    local binary_relative_path="$2"
    local archive_basename="$3"
    local binary_name
    local staging_directory

    echo "Building ${archive_basename} in ${build_directory}"
    (
        cd "$build_directory"
        zig build -Doptimize=Debug
    )

    binary_name="$(basename "$binary_relative_path")"
    staging_directory="$(mktemp -d)"
    cp "$build_directory/$binary_relative_path" "$staging_directory/$binary_name"

    tar -C "$staging_directory" -czf \
        "$output_dir/${archive_basename}-debug-${platform}-${architecture}.tar.gz" \
        "$binary_name"

    rm -rf "$staging_directory"
}

rm -rf "$output_dir"
mkdir -p "$output_dir"

package_binary "$repo_root" "zig-out/bin/playground" "playground"
package_binary "$repo_root/examples/uhoh.com" "zig-out/bin/uhoh.com" "uhoh.com"

printf 'Created artifacts:\n'
for artifact in "$output_dir"/*.tar.gz; do
    printf ' - %s\n' "$(basename "$artifact")"
done
