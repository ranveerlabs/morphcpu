# gateware/

Verilog for the MorphCPU fabric, targeting the Lattice iCE40UP5K-SG48.

## Layout

| Path | What it is |
|---|---|
| [rtl/morph_cell.v](rtl/morph_cell.v) | One reconfigurable cell: config register, 4-op ALU, routing |
| [rtl/grid.v](rtl/grid.v) | The 4x4 fabric and its neighbour interconnect |
| [rtl/uart_rx.v](rtl/uart_rx.v) | 8N1 receiver, synchronised, with stop-bit checking |
| [rtl/uart_tx.v](rtl/uart_tx.v) | 8N1 transmitter |
| [rtl/config_loader.v](rtl/config_loader.v) | Host command decoder, config shifter, tick generator |
| [rtl/morphcpu_top.v](rtl/morphcpu_top.v) | Top level: clock, reset, UART, LEDs |
| [morphcpu.pcf](morphcpu.pcf) | Pin constraints (**candidate — not yet locked**) |
| [build.sh](build.sh) | yosys → nextpnr → icepack |
| [sim/](sim/) | Testbenches |

`morph_cell` is not called `cell` because `cell` is a reserved word in
Verilog-2001 — it belongs to the `config`/`design` construct.

## How a cell works

Each cell holds 4 configuration bits: an operation and a routing direction.

| `op` | Operation | Result |
|---|---|---|
| `0` | PASS | `a` |
| `1` | INV | `~a` |
| `2` | ADD | `a + b` (8-bit, wraps) |
| `3` | XOR | `a ^ b` |

| `dir` | Routes its result to |
|---|---|
| `0` | North |
| `1` | East |
| `2` | South |
| `3` | West |

Inputs are scanned in priority order N, E, S, W. The first valid input is `a`;
a second valid input is `b`. If only one input is valid, `b` falls back to the
value the cell is already holding. That is what gives ADD and XOR meaning:
**two streams converging on a cell get combined by it**, and a lone stream
passing through an ADD cell accumulates.

One `tick` moves data exactly one cell. A value therefore takes as many ticks
as the number of cells on its path — the path length *is* the latency.

## Grid and edges

```
        c0    c1    c2    c3
      +-----+-----+-----+-----+
  r0  |  0  |  1  |  2  |  3  |  -> east_out[0]
      +-----+-----+-----+-----+
  r1  |  4  |  5  |  6  |  7  |  -> east_out[1]
      +-----+-----+-----+-----+
  r2  |  8  |  9  | 10  | 11  |  -> east_out[2]
      +-----+-----+-----+-----+
  r3  | 12  | 13  | 14  | 15  |  -> east_out[3]
      +-----+-----+-----+-----+
         ^
     west_in[r] injects into column 0
```

Data routed off the north, south, or west edges is dropped. Data routed east
out of column 3 leaves the fabric and is sent to the host over UART.
`led[i]` follows cell `i`.

## Host protocol

8N1 UART, 115200 baud, over the FT231X. One command byte, then a fixed number
of argument bytes.

| Cmd | Name | Args | Effect |
|---|---|---|---|
| `0x01` | CONFIG | 8 | Load the whole topology (see packing below) |
| `0x02` | INJECT | 2 | `[row, value]` — present `value` at the west edge of `row` until the next tick |
| `0x03` | TICKDIV | 3 | 24-bit big-endian clock divider for the tick; `<=1` runs at full clock rate |
| `0x04` | CLEAR | 0 | Drop all in-flight data; configuration survives |
| `0x05` | STEP | 0 | Advance the fabric exactly one tick |

Unknown command bytes are ignored, so recovering from a half-sent command is
just: send `0x04` and carry on.

Results leaving the east edge are sent back as single bytes, lowest row first.

### Config packing

The 8 CONFIG bytes are one nibble per cell, in ascending cell order:

```
byte i, upper nibble -> cell (2i)
byte i, lower nibble -> cell (2i + 1)
nibble = {op[1:0], dir[1:0]}
```

So a straight PASS chain along row 0 (cells 0–3 all PASS/EAST, nibble `0x1`)
is:

```
01 11 11 00 00 00 00 00 00
^  ^^^^^ cells 0-3         cells 4-15 idle
CONFIG
```

The chain is wired highest-cell-index-first inside the fabric precisely so the
host can send cells in plain ascending order without reversing anything.

### Worked example — add two numbers as they travel

Route cell 0 south into cell 4, make cell 4 an adder, then run east to the edge:

| Cell | op | dir | nibble |
|---|---|---|---|
| 0 | PASS | S | `0x2` |
| 4 | ADD | E | `0x9` |
| 5, 6, 7 | PASS | E | `0x1` |

```
01 20 00 91 11 00 00 00 00     CONFIG
02 00 C8                       INJECT row 0, 200
05                             STEP   (200 now in cell 0, aimed south)
02 01 64                       INJECT row 1, 100
05                             STEP   (cell 4 adds north + west -> 44)
05 05 05                       STEP x3 (across cells 5, 6, 7)
                               -> board sends 0x2C (300 truncated to 8 bits)
```

That exchange is exactly what `sim/tb_morphcpu_top.v` asserts, byte for byte.

## Simulation

Icarus Verilog only — no vendor tools needed.

```sh
cd gateware/sim
./run_sims.sh
```

| Testbench | Covers |
|---|---|
| [sim/tb_grid.v](sim/tb_grid.v) | Fabric: per-tick latency, all four ops, convergence, activity taps |
| [sim/tb_morphcpu_top.v](sim/tb_morphcpu_top.v) | End-to-end over the real UART protocol |

`tb_grid` drives the config chain directly; `tb_morphcpu_top` goes through the
UART and never reaches into the hierarchy, so it also validates the wire
protocol and the config bit ordering.

To look at waveforms:

```sh
cd gateware/sim/out
gtkwave tb_grid.vcd
```

## Building a bitstream

Needs the [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build/releases)
(yosys, nextpnr-ice40, icepack, iceprog) on `PATH`.

```sh
cd gateware
./build.sh          # synthesise, place and route, pack
./build.sh prog     # ...and flash it via iceprog
./build.sh clean
```

The exact commands `build.sh` runs:

```sh
yosys -p "read_verilog rtl/*.v; synth_ice40 -top morphcpu_top -json build/morphcpu_top.json"

nextpnr-ice40 --up5k --package sg48 \
    --json build/morphcpu_top.json \
    --pcf morphcpu.pcf \
    --asc build/morphcpu_top.asc \
    --freq 12

icepack build/morphcpu_top.asc build/morphcpu_top.bin

iceprog build/morphcpu_top.bin
```

`build.sh` also greps the nextpnr log for utilisation and Fmax so the numbers
can go straight into `JOURNAL.md`.

> **Not yet run.** The OSS CAD Suite is not installed on this machine, so the
> synthesis and place-and-route flow above is written but unexercised. The
> simulation flow is the part that has actually been run. Record real LUT
> counts and Fmax in the journal the first time `build.sh` completes.

## Demo notes

The tick defaults to **4 Hz**, not 12 MHz. A hop every 83 ns is invisible, and
the point of the board is watching data cross the LED grid. LEDs are also
pulse-stretched to ~150 ms so a single-tick visit stays legible.

At full tick rate the fabric outruns 115200 baud and east-edge results get
dropped. That is expected — use `STEP` or a slow `TICKDIV` when you want every
result back.
