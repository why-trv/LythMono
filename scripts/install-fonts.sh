#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VARIANT="TTF"
KEEP_OLD=false
CLIPBOARD=false

for arg in "$@"; do
  case $arg in
    --unhinted) VARIANT="TTF-Unhinted" ;;
    --keep-old) KEEP_OLD=true ;;
    --clipboard) CLIPBOARD=true ;;
    --help|-h)
      echo "Usage: $0 [--unhinted] [--keep-old] [--clipboard]"
      echo "  --unhinted   Use unhinted TTF variant"
      echo "  --keep-old   Keep old versions of fonts in destination"
      echo "  --clipboard  Copy family names to clipboard (macOS only)"
      exit 0 ;;
  esac
done

[ ! -d "$ROOT/dist" ] && echo "Error: dist not found. Run build first." && exit 1

# Collect font files
FONT_FILES=()
for plan_dir in "$ROOT"/dist/*/; do
  font_src="$plan_dir$VARIANT"
  if [ -d "$font_src" ]; then
    for f in "$font_src"/*.ttf; do
      [ -f "$f" ] && FONT_FILES+=("$f")
    done
  fi
done

[ ${#FONT_FILES[@]} -eq 0 ] && echo "No font files found." && exit 1

# Determine font dir
case "$(uname -s)" in
  Darwin) FONT_DIR="$HOME/Library/Fonts" ;;
  Linux) FONT_DIR="$HOME/.local/share/fonts" ;;
  *) echo "Unsupported OS" && exit 1 ;;
esac

mkdir -p "$FONT_DIR"
echo "Installing $VARIANT fonts to $FONT_DIR..."

# Remove old timestamped versions unless --keep-old
if [ "$KEEP_OLD" = false ]; then
  for f in "${FONT_FILES[@]}"; do
    base=$(basename "$f" .ttf)
    # Only need to remove for timestamped builds (non-timestamped just overwrites)
    if [[ "$base" =~ -[0-9]{8}-[0-9]{6}- ]]; then
      # e.g., LythMono-20260128-143052-Regular -> remove LythMono-*-Regular.ttf where * is YYYYMMDD-HHMMSS
      base_clean=$(echo "$base" | sed -E 's/-[0-9]{8}-[0-9]{6}(-)/\1/')  # LythMono-Regular
      prefix="${base_clean%%-*}"  # LythMono
      suffix="${base_clean#*-}"   # Regular
      for old in "$FONT_DIR"/${prefix}-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]-${suffix}.ttf; do
        [ -f "$old" ] && echo -e "\033[37mrm $old\033[0m" && rm "$old"
      done
    fi
  done
fi

for f in "${FONT_FILES[@]}"; do
  cp -v "$f" "$FONT_DIR/"
done

# Copy family names to clipboard (macOS only) for clipboard manager recall
if [ "$CLIPBOARD" = true ] && [ "$(uname -s)" = "Darwin" ]; then
  if ! command -v fc-query &>/dev/null; then
    echo "fontconfig not installed, skipping clipboard copy (install via: brew install fontconfig)"
  else
    seen_families=""
    for f in "${FONT_FILES[@]}"; do
      family=$(fc-query -f '%{family}\n' "$f" | head -1 | cut -d, -f1)
      if [ -n "$family" ] && [[ "$seen_families" != *"|$family|"* ]]; then
        seen_families="$seen_families|$family|"
        echo -n "$family" | pbcopy
        echo "Copied to clipboard: $family"
        sleep 0.1  # Give clipboard manager time to capture
      fi
    done
  fi
fi

echo "Done."
