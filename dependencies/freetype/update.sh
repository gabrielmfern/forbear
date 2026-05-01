#!/usr/bin/env bash
# Update the vendored FreeType tree from upstream.
#
# Usage: ./update.sh [git-ref]
#   git-ref: tag or branch to sync to (default: VER-2-13-3)
#
# Runs against this directory regardless of cwd. The directory does not need to
# be its own git repo — upstream is fetched into a temp clone and rsync'd in.
# Files listed in KEEP are owned by this fork and are never overwritten.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

REF="${1:-VER-2-13-3}"
UPSTREAM="https://gitlab.freedesktop.org/freetype/freetype.git"

KEEP=(
    .git
    .github
    .gitignore
    .zig-cache
    build.zig
    build.zig.zon
    README.md
    update.sh
    verify.sh
)

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Cloning $UPSTREAM @ $REF..."
git clone --depth 1 --branch "$REF" "$UPSTREAM" "$TMP/freetype" >/dev/null

EXCLUDES=()
for k in "${KEEP[@]}"; do
    EXCLUDES+=(--exclude "/$k")
done
EXCLUDES+=(--exclude '/.git')

echo "Syncing into $(pwd)..."
rsync -a --delete "${EXCLUDES[@]}" "$TMP/freetype/" ./

echo "Done. Synced to $REF."
echo "Review the diff, then run ./verify.sh."
