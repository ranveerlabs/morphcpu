# MorphCPU

A processor that changes its hardware topology to match the computation.

Instead of sending every operation through a fixed datapath, MorphCPU uses 16 small reconfigurable cells. Each cell holds an operation and a direction, so the same 4×4 grid can become different data paths. Values enter from the west, move one cell per tick, and leave at the east edge over UART.

It's written in Verilog for an iCE40UP5K FPGA. Python tooling generates the schematic and board layout; the gateware build runs synthesis and place-and-route with Yosys and nextpnr.

## Why

Conventional processors move data through mostly fixed hardware. MorphCPU asks what happens if the hardware itself can be rearranged around the computation—and makes that movement visible on a grid of LEDs.

## The grid

![MorphCPU board front](docs/img/pcb-top.svg)

Each cell has a 4-bit configuration: a 2-bit operation and a 2-bit output direction. The four operations are pass, invert, 8-bit add, and XOR. Cells can route north, east, south, or west; inputs that meet at a cell can be combined.

```text
        c0    c1    c2    c3
      +-----+-----+-----+-----+
  r0  |  0  |  1  |  2  |  3  |  -> out
      +-----+-----+-----+-----+
  r1  |  4  |  5  |  6  |  7  |  -> out
      +-----+-----+-----+-----+
  r2  |  8  |  9  | 10  | 11  |  -> out
      +-----+-----+-----+-----+
  r3  | 12  | 13  | 14  | 15  |  -> out
      +-----+-----+-----+-----+
         ^
      data in
```

At 4 Hz, a value crossing four cells takes about a second. The slow clock is deliberate: you can watch the computation move.

## A tiny example

Set cell 0 to pass south, cell 4 to add and point east, then cells 5–7 to pass east. Inject 200 on row 0 and 100 on row 1. After stepping through the grid, the UART returns `0x2C`: 300 truncated to 8 bits. The full byte sequence and timing are in the [gateware guide](gateware/README.md#worked-example-add-two-numbers-while-they-travel).

## Build and test

You need Icarus Verilog for simulation and OSS CAD Suite for the FPGA bitstream.

```sh
bash gateware/sim/run_sims.sh
bash gateware/build.sh
bash case/export.sh
```

The simulation has 18 passing checks. GitHub Actions also runs the simulations and gateware build on changes; see the [workflow](https://github.com/ranveerlabs/morphcpu/actions/workflows/gateware.yml).

## Status

The 4-layer PCB is routed: KiCad reports no violations or unconnected items. The latest recorded bitstream build used 2,020 of 5,280 logic cells and routed at 37.33 MHz against a 16 MHz clock. That build predates two pin-map changes, and the board has not been flashed yet, so those timing numbers are not verification of the current layout. Routing details and pin changes are in [hardware/ROUTING.md](hardware/ROUTING.md).

![Routed back of the PCB](docs/img/routed-bcu.svg)

The board is 70 mm across with a 4×4 LED grid. The case is printable without supports. More board images are in [`docs/img`](docs/img/README.md); the parts and cost are in the [BOM](docs/BOM.md).

## License

[AGPL-3.0-only](LICENSE)
