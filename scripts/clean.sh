#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

[ -L "$ROOT/dist" ] && rm "$ROOT/dist" && echo "Removed: dist"
[ -d "$ROOT/Iosevka/dist" ] && rm -rf "$ROOT/Iosevka/dist" && echo "Removed: Iosevka/dist"

echo "Done."
