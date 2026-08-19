#!/usr/bin/env bash
# Run every MorphCPU testbench under Icarus Verilog.
# Exits non-zero if any testbench fails, so it works as a pre-commit check.
set -u

cd "$(dirname "$0")"
RTL=../rtl
OUT=out
mkdir -p "$OUT"

TBS="tb_grid tb_morphcpu_top"
fail=0

for tb in $TBS; do
    echo "=============================================================="
    echo "  $tb"
    echo "=============================================================="

    if ! iverilog -g2005 -Wall -o "$OUT/$tb.vvp" -s "$tb" "$RTL"/*.v "$tb.v"; then
        echo "  COMPILE FAILED: $tb"
        fail=1
        continue
    fi

    # Waveforms land next to the .vvp; both are gitignored.
    if ( cd "$OUT" && vvp "$tb.vvp" ); then
        echo "  $tb OK"
    else
        echo "  $tb FAILED"
        fail=1
    fi
    echo
done

if [ "$fail" -ne 0 ]; then
    echo "RESULT: at least one testbench failed"
    exit 1
fi

echo "RESULT: all testbenches passed"
