#!/usr/bin/env bash
# re-export the case from the OpenSCAD source.
# set OPENSCAD if the binary isnt on PATH, e.g.
#   OPENSCAD="/c/Program Files/OpenSCAD (Nightly)/openscad.com" ./export.sh
set -euo pipefail

cd "$(dirname "$0")"

OPENSCAD="${OPENSCAD:-openscad}"
if ! command -v "$OPENSCAD" >/dev/null 2>&1 && [ ! -x "$OPENSCAD" ]; then
    echo "error: openscad not found. Set OPENSCAD to the binary path." >&2
    exit 1
fi

SRC=morphcpu_case.scad

echo "=== STL (binary) ==="
"$OPENSCAD" -o morphcpu_case.stl --export-format binstl -D 'part="frame"' "$SRC"

echo "=== 3MF ==="
"$OPENSCAD" -o morphcpu_case.3mf -D 'part="frame"' "$SRC"

echo "=== previews ==="
mkdir -p ../docs/img
"$OPENSCAD" -o ../docs/img/case-frame-preview.png --imgsize=1200,900 \
    --colorscheme=Tomorrow --camera=0,0,8,60,0,30,180 -D 'part="frame"' "$SRC"
"$OPENSCAD" -o ../docs/img/case-assembly-preview.png --imgsize=1200,900 \
    --colorscheme=Tomorrow --camera=0,0,8,55,0,25,190 -D 'part="assembly"' "$SRC"

echo
echo "done:"
ls -l morphcpu_case.stl morphcpu_case.3mf
