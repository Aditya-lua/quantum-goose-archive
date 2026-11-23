#!/usr/bin/env bash
# Portable project ZIP from the committed tree of this folder (git archive), so
# node_modules, out/, work/, whisper.cpp/, caches and credentials are never included.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p out
NAME=barah-bajkar-satrah-minute
# tree path is relative to the repository root
git archive --format=zip --prefix="$NAME/" -o "out/$NAME-project.zip" "HEAD:$(git rev-parse --show-prefix)"
unzip -l "out/$NAME-project.zip" | tail -1
echo "out/$NAME-project.zip"
