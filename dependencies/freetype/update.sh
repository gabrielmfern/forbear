#!/usr/bin/env bash
set -euo pipefail

git remote add upstream https://gitlab.freedesktop.org/freetype/freetype.git || true
git fetch upstream
git merge upstream/master || true
git status --porcelain | awk '{if ($1=="DU") print $2}' | xargs git rm
