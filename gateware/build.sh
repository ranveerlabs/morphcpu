#!/usr/bin/env bash
# MorphCPU bitstream build: yosys -> nextpnr-ice40 -> icepack
# target: Lattice iCE40UP5K, SG48 package, 16 MHz external oscillator.
#   ./build.sh          synthesise, place and route, pack a bitstream
#   ./build.sh prog     ...then flash it to the SPI config flash via iceprog
#   ./build.sh clean    remove build/
# needs the OSS CAD Suite (yosys, nextpnr-ice40, icepack, iceprog):
#   https://github.com/YosysHQ/oss-cad-suite-build/releases
set -euo pipefail

cd "$(dirname "$0")"

TOP=morphcpu_top
PCF=morphcpu.pcf
BUILD=build
DEVICE=up5k
PACKAGE=sg48
FREQ=16          # MHz, must match the XO and the CLK_HZ parameter

if [ "${1:-}" = "clean" ]; then
    rm -rf "$BUILD"
    echo "cleaned"
    exit 0
fi

for tool in yosys nextpnr-ice40 icepack; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "error: $tool not found on PATH." >&2
        echo "Install the OSS CAD Suite and re-run:" >&2
        echo "  https://github.com/YosysHQ/oss-cad-suite-build/releases" >&2
        exit 1
    fi
done

mkdir -p "$BUILD"

echo "=== 1/3  synthesis (yosys) ==="
yosys -p "read_verilog rtl/*.v; synth_ice40 -top $TOP -json $BUILD/$TOP.json" \
      -l "$BUILD/yosys.log"

echo "=== 2/3  place and route (nextpnr-ice40) ==="
# --freq sets the timing target, nextpnr reports achieved Fmax against it.
nextpnr-ice40 \
    --"$DEVICE" \
    --package "$PACKAGE" \
    --json "$BUILD/$TOP.json" \
    --pcf "$PCF" \
    --asc "$BUILD/$TOP.asc" \
    --freq "$FREQ" \
    --pcf-allow-unconstrained \
    --log "$BUILD/nextpnr.log"

echo "=== 3/3  bitstream (icepack) ==="
icepack "$BUILD/$TOP.asc" "$BUILD/$TOP.bin"

echo
echo "bitstream: $BUILD/$TOP.bin"
ls -l "$BUILD/$TOP.bin"

# numbers worth pasting into JOURNAL.md
echo
echo "=== utilisation ==="
grep -E "^Info: +(ICESTORM_LC|ICESTORM_RAM|SB_IO|ICESTORM_PLL|SB_GB)" \
     "$BUILD/nextpnr.log" || true
echo "=== timing ==="
grep -E "Max frequency|Max delay" "$BUILD/nextpnr.log" || true

if [ "${1:-}" = "prog" ]; then
    echo
    echo "=== flashing via iceprog ==="
    iceprog "$BUILD/$TOP.bin"
fi
