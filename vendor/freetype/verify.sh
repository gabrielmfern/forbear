#!/usr/bin/env bash
set -euo pipefail

git diff $(git merge-base master upstream/master)..master \
    --diff-filter=d \
    ':(exclude)README.md' \
    ':(exclude)build.zig' \
    ':(exclude)build.zig.zon' \
    ':(exclude)update.sh' \
    ':(exclude)verify.sh' \
    ':(exclude).github' \
    ':(exclude).gitignore'
