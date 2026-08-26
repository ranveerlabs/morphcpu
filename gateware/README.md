# gateware/

Verilog, targets iCE40UP5K-SG48

| | |
|---|---|
| [rtl/morph_cell.v](rtl/morph_cell.v) | one cell: config register, 4-op ALU, routing |
| [rtl/grid.v](rtl/grid.v) | the 4x4 fabric and the neighbour interconnect |
| [rtl/uart_rx.v](rtl/uart_rx.v) | 8N1 receiver, synchronised, checks the stop bit |
| [rtl/uart_tx.v](rtl/uart_tx.v) | 8N1 transmitter |
| [rtl/config_loader.v](rtl/config_loader.v) | command decoder, config shifter, tick generator |
| [rtl/morphcpu_top.v](rtl/morphcpu_top.v) | top level: clock, reset, UART, LEDs |
| [morphcpu.pcf](morphcpu.pcf) | pin constraints |
| [build.sh](build.sh) | yosys -> nextpnr -> icepack |
| [sim/](sim/) | testbenches |

its `morph_cell` not `cell` cuz `cell` is reserved in Verilog-2001, it belongs
to the `config`/`design` construct. iverilog does not tell you this nicely

## cells

4 config bits, an op and a direction

| `op` | Operation | Result |
|---|---|---|
| `0` | PASS | `a` |
| `1` | INV | `~a` |
| `2` | ADD | `a + b` (8-bit, wraps) |
| `3` | XOR | `a ^ b` |

| `dir` | Sends its result |
|---|---|
| `0` | north |
| `1` | east |
| `2` | south |
| `3` | west |

inputs get scanned in a fixed priority order, N then E then S then W. first
valid one is `a`, second valid one is `b`. only one input showed up? `b` falls
back to whatever the cell is already holding

that fallback is what gives ADD and XOR meaning. two streams converging on a
cell get combined, and a lone stream walking thru an ADD cell accumulates
against itself instead.

one `tick` moves data exactly one cell, so a value takes as many ticks as there
are cells on its path.

## grid and edges

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

anything routed off the north, south or west edges is dropped. anything going
east out of column 3 leaves the fabric and goes back to the host over UART.
`led[i]` follows cell `i`.

## host protocol

8N1 UART, 115200 baud, through the FT231X. one command byte then a fixed number
of argument bytes.

| Cmd | Name | Args | Effect |
|---|---|---|---|
| `0x01` | CONFIG | 8 | load the whole topology, packing below |
| `0x02` | INJECT | 2 | `[row, value]`, presents `value` at the west edge of `row` until the next tick |
| `0x03` | TICKDIV | 3 | 24-bit big-endian tick divider. `<=1` runs at full clock rate |
| `0x04` | CLEAR | 0 | drop all in-flight data, config survives |
| `0x05` | STEP | 0 | advance exactly one tick |

unknown command bytes get ignored, so recovering from a half-sent command is
just: send `0x04`, carry on

results leaving the east edge come back as single bytes, lowest row first

### config packing

the 8 CONFIG bytes are one nibble per cell, ascending cell order:

```
byte i, upper nibble -> cell (2i)
byte i, lower nibble -> cell (2i + 1)
nibble = {op[1:0], dir[1:0]}
```

so a straight PASS chain along row 0, cells 0-3 all PASS/EAST, nibble `0x1`:

```
01 11 11 00 00 00 00 00 00
^  ^^^^^ cells 0-3         cells 4-15 idle
CONFIG
```

the chain is wired highest-cell-index-first inside the fabric on purpose, so the
host sends cells in plain ascending order and never has to reverse anything

### worked example: add two numbers while they travel

route cell 0 south into cell 4, make cell 4 an adder, run east to the edge

| Cell | op | dir | nibble |
|---|---|---|---|
| 0 | PASS | S | `0x2` |
| 4 | ADD | E | `0x9` |
| 5, 6, 7 | PASS | E | `0x1` |

```
01 20 00 91 11 00 00 00 00     CONFIG
02 00 C8                       INJECT row 0, 200
05                             STEP   (200 in cell 0 now, pointed south)
02 01 64                       INJECT row 1, 100
05                             STEP   (cell 4 adds north + west -> 44)
05 05 05                       STEP x3 (across cells 5, 6, 7)
                               -> board sends 0x2C (300 truncated to 8 bits)
```

that exchange is exactly what `sim/tb_morphcpu_top.v` asserts, byte for byte

## simulation

Icarus Verilog only, no vendor tools

```sh
cd gateware/sim
./run_sims.sh
```

18/18 passing.

| Testbench | Covers |
|---|---|
| [sim/tb_grid.v](sim/tb_grid.v) | fabric: per-tick latency, all four ops, convergence, activity taps |
| [sim/tb_morphcpu_top.v](sim/tb_morphcpu_top.v) | end to end over the real UART protocol |

`tb_grid` drives the config chain directly. `tb_morphcpu_top` goes in through the
UART and never reaches into the hierarchy, so it validates the wire protocol and
the config bit ordering too.

waveforms:

```sh
cd gateware/sim/out
gtkwave tb_grid.vcd
```

## building a bitstream

needs the [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build/releases)
(yosys, nextpnr-ice40, icepack, iceprog) on `PATH`

```sh
cd gateware
./build.sh          # synth, place and route, pack
./build.sh prog     # ...and flash it with iceprog
./build.sh clean
```

what it actually runs:

```sh
yosys -p "read_verilog rtl/*.v; synth_ice40 -top morphcpu_top -json build/morphcpu_top.json"

nextpnr-ice40 --up5k --package sg48 \
    --json build/morphcpu_top.json \
    --pcf morphcpu.pcf \
    --asc build/morphcpu_top.asc \
    --freq 16

icepack build/morphcpu_top.asc build/morphcpu_top.bin

iceprog build/morphcpu_top.bin
```

greps the nextpnr log for utilisation and Fmax at the end

**this has never run.** OSS CAD Suite isnt installed here. the flow above is
written and unexercised. sim is the part thats actually been run.

`morphcpu.pcf` agrees with the
[user I/O assignment](../hardware/DESIGN.md#user-io-assignment) in DESIGN.md,
all 20 pins, checked. DESIGN.md is the source of truth they can drift.

## demo notes

tick defaults to 4 Hz. a hop every 62.5 ns is invisible. LEDs are pulse
stretched to ~150 ms so a single-tick visit still reads

at full tick rate the fabric outruns 115200 baud and east-edge results get
dropped. use `STEP` or a slow `TICKDIV` if you want all of them
