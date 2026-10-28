#!/bin/sh
set -eu
dir=${1:-.}
base=https://raw.githubusercontent.com/gabrielmfern/forbear/${FORBEAR_REF:-main}
mkdir -p "$dir"
cd "$dir"
curl -fsSL --create-dirs \
  -o main.jai "$base/apps/quick-start.jai" \
  -o Inter.ttf "$base/apps/Inter.ttf" \
  -o modules/forbear.jai "$base/forbear.jai"
echo "Run: cd $dir && jai main.jai +forbear"