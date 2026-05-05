#!/bin/sh
set -eu

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

git config core.hooksPath .githooks
echo "✅ core.hooksPath=.githooks （已在本地仓库启用）"
