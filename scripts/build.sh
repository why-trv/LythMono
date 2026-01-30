#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IOSEVKA_DIR="$ROOT/Iosevka"
USE_TS=false
KEEP_OLD=false
FORMAT="contents"
EXPLICIT_TARGETS=()

for arg in "$@"; do
  case $arg in
    --ts) USE_TS=true ;;
    --keep-old) KEEP_OLD=true ;;
    --help|-h)
      echo "Usage: $0 [format | target...] [--ts] [--keep-old]"
      echo "  format     Build format for all plans (default: contents)"
      echo "  target     Explicit format::plan targets (e.g., ttf::LythMono)"
      echo "  --ts       Append timestamp to plan/family names"
      echo "  --keep-old Keep old timestamped builds in dist/ (only with --ts)"
      exit 0 ;;
    *::*) EXPLICIT_TARGETS+=("$arg") ;;
    *) FORMAT="$arg" ;;
  esac
done

# Gather plans and generate private-build-plans.toml
if [ "$USE_TS" = true ]; then
  export BUILD_TS=$(date +%Y%m%d-%H%M%S)
  # Remove old timestamped builds unless --keep-old
  if [ "$KEEP_OLD" = false ] && [ -d "$IOSEVKA_DIR/dist" ]; then
    for old in "$IOSEVKA_DIR"/dist/*-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]; do
      [ -d "$old" ] && echo -e "\033[37mrm -rf $old\033[0m" && rm -rf "$old"
    done
  fi
fi

# gather.mjs outputs plan names (with timestamps if BUILD_TS is set).
# We do this for all plans even if we're only building a subset of explicit targets,
# because those targets may inherit from other plans.
PLANS=$(node "$ROOT/scripts/gather.mjs")

TARGETS=()
if [ ${#EXPLICIT_TARGETS[@]} -gt 0 ]; then
  # Match explicit targets against actual plan names from gather
  for target in "${EXPLICIT_TARGETS[@]}"; do
    format="${target%%::*}"
    plan="${target##*::}"
    # Find matching plan (exact or with timestamp suffix)
    for p in $PLANS; do
      if [ "$p" = "$plan" ] || [[ "$p" == "$plan"-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9] ]]; then
        TARGETS+=("${format}::${p}")
        break
      fi
    done
  done
else
  # Build all plans with the specified format
  for plan in $PLANS; do
    TARGETS+=("${FORMAT}::${plan}")
  done
fi

echo "Building targets: ${TARGETS[@]}"

cd "$IOSEVKA_DIR"
npm run build -- "${TARGETS[@]}"

ln -sfnv "$IOSEVKA_DIR/dist" "$ROOT/dist"
