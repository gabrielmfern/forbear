#!/usr/bin/env bash
set -euo pipefail

git remote add upstream https://github.com/google/brotli.git || true
git fetch upstream
git merge upstream/master || true
git status --porcelain | awk '{if ($1=="DU") print $2}' | xargs git rm
