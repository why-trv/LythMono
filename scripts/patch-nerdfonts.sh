#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT/dist"
NERDFONTS_DIR="$ROOT/.nerd-fonts"
PATCHER="$NERDFONTS_DIR/font-patcher"

DO_HINTED=false
DO_UNHINTED=false
MAX_JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

for arg in "$@"; do
  case $arg in
    --hinted) DO_HINTED=true ;;
    --unhinted) DO_UNHINTED=true ;;
    -j=*|--jobs=*) MAX_JOBS="${arg#*=}" ;;
    --help|-h)
      echo "Usage: $0 [--hinted] [--unhinted] [-j=N|--jobs=N]"
      echo "  --hinted    Patch TTF (hinted) fonts"
      echo "  --unhinted  Patch TTF-Unhinted fonts"
      echo "  -j=N        Run N jobs in parallel (default: number of CPU cores)"
      echo "  Both flags can be passed to patch both variants"
      echo "  If no flags: patch hinted if available, otherwise unhinted"
      exit 0 ;;
  esac
done

if [ ! -d "$DIST_DIR" ]; then
  echo "Error: dist/ directory not found. Run 'npm run build' first."
  exit 1
fi

# If no flags specified, auto-detect: prefer hinted if available
if [ "$DO_HINTED" = false ] && [ "$DO_UNHINTED" = false ]; then
  if ls -d "$DIST_DIR"/*/TTF/ >/dev/null 2>&1; then
    DO_HINTED=true
  else
    DO_UNHINTED=true
  fi
fi

# Download patcher if not already present
if [ ! -f "$PATCHER" ]; then
  echo "Downloading Nerd Fonts patcher..."
  mkdir -p "$NERDFONTS_DIR"
  curl -fsSL https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/font-patcher -o "$PATCHER"
  chmod +x "$PATCHER"

  echo "Downloading glyph source fonts..."
  curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FontPatcher.zip -o "$NERDFONTS_DIR/FontPatcher.zip"
  unzip -o "$NERDFONTS_DIR/FontPatcher.zip" -d "$NERDFONTS_DIR"
  rm "$NERDFONTS_DIR/FontPatcher.zip"
fi

# Build list of TTF subdirs to process
TTF_SUBDIRS=()
[ "$DO_HINTED" = true ] && TTF_SUBDIRS+=("TTF")
[ "$DO_UNHINTED" = true ] && TTF_SUBDIRS+=("TTF-Unhinted")

# Collect all patch jobs
declare -a JOBS
for family_dir in "$DIST_DIR"/*/; do
  family_name=$(basename "$family_dir")
  [[ "$family_name" == *NerdFont* ]] && continue

  nf_family_name="${family_name}NerdFont"
  nf_family_dir="$DIST_DIR/$nf_family_name"

  for ttf_subdir in "${TTF_SUBDIRS[@]}"; do
    [ ! -d "$family_dir/$ttf_subdir" ] && continue
    nf_ttf_dir="$nf_family_dir/$ttf_subdir"
    mkdir -p "$nf_ttf_dir"

    for ttf in "$family_dir/$ttf_subdir"/*.ttf; do
      [ ! -f "$ttf" ] && continue
      JOBS+=("$ttf|$nf_ttf_dir")
    done
  done
done

TOTAL=${#JOBS[@]}
echo "Patching $TOTAL fonts with up to $MAX_JOBS parallel jobs..."

# Run jobs in parallel using xargs
printf '%s\n' "${JOBS[@]}" | xargs -P "$MAX_JOBS" -I {} bash -c '
  job="$1"
  ttf="${job%%|*}"
  out_dir="${job##*|}"
  filename=$(basename "$ttf")
  echo "  Patching $filename..."
  fontforge -script "'"$PATCHER"'" --complete --careful -out "$out_dir" "$ttf" >/dev/null 2>&1
' _ {}

echo "Nerd Font patching complete!"
