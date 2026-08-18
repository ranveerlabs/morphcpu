# MorphCPU

**A processor where the hardware topology *is* the program.**

MorphCPU is a reconfigurable spatial processor built on a Lattice iCE40UP5K FPGA. Instead of a
control unit pulling instructions from memory and grinding them through a fetch-decode-execute
loop, MorphCPU is a small grid of identical reconfigurable cells. Each cell holds two things: an
**operation** (add, xor, shift, mask, compare, pass-through, …) and a **routing direction**
(north, south, east, west) telling it where to hand its result next. Configure the grid and you
have configured the program — the wiring between cells is the control flow, and the operations
sitting in those cells are the instruction stream.

Data enters at the edge of the grid and *ripples* through it. A value moving from one cell to the
next is transformed by that cell's operation on arrival, then forwarded along that cell's routing
direction to a neighbour, where it is transformed again. There is no program counter, no
instruction fetch, and no register file being read and written between steps — the intermediate
results live in the wires and cell registers themselves as the data physically moves. A
computation is literally a path through the grid, and its length in cells is its length in cycles.
Independent paths through different regions of the grid run at the same time without any
scheduling logic, because nothing is contending for a shared execution unit.

The grid is reconfigured at runtime over USB. A UART configuration loader on the FPGA accepts a
stream of cell descriptors — one opcode plus one direction per cell — and shifts them into the
grid's configuration registers, so rewriting the "program" means rewriting the topology. That
makes the machine's behaviour observable in a way a conventional CPU's isn't: 16 status LEDs tap
the grid so you can watch data propagate through the fabric as it computes. The goal is a
processor you can *see* thinking.

## Architecture at a glance

| Component | Part / Choice | Purpose |
|---|---|---|
| FPGA | Lattice iCE40UP5K (SG48) | Hosts the cell grid, routing, and config loader |
| USB bridge | FTDI FT231X | USB-C to UART for configuration + host I/O |
| Config flash | SPI NOR flash | Holds the FPGA bitstream for standalone boot |
| Clock | Crystal oscillator | System clock reference |
| Status | 16 LEDs | Live view of data propagating through the grid |
| Control | Reset button | FPGA / system reset |
| Connector | USB-C | Power + data |

## Repository layout

| Path | Contents |
|---|---|
| [gateware/](gateware/) | Verilog source — cell logic, routing fabric, UART config loader |
| [gateware/sim/](gateware/sim/) | Testbenches |
| [hardware/](hardware/) | KiCad schematic + PCB project files |
| [case/](case/) | 3D case CAD source + exported STL |
| [docs/](docs/) | Datasheets, reference links, BOM |

## Toolchain

Open-source iCE40 flow: **yosys** (synthesis) → **nextpnr-ice40** (place & route) →
**icepack** (bitstream) → **iceprog** (flash). Simulation with **Icarus Verilog** / **Verilator**,
waveforms in **GTKWave**. PCB in **KiCad**.

## Status

> Keep this section updated as the build progresses.

**Current phase:** Project setup

| Area | Status | Notes |
|---|---|---|
| Concept / architecture | 🟡 In progress | Cell ISA and routing scheme being defined |
| Gateware | ⚪ Not started | |
| Simulation / testbenches | ⚪ Not started | |
| Schematic | ⚪ Not started | |
| PCB layout | ⚪ Not started | |
| Case | ⚪ Not started | |
| BOM / ordering | ⚪ Not started | |
| Bring-up | ⚪ Not started | |

**Legend:** ⚪ Not started · 🟡 In progress · 🟢 Done · 🔴 Blocked

**Next up:**
- [ ] Define the cell opcode + direction encoding
- [ ] First single-cell Verilog module and testbench
- [ ] Pull iCE40UP5K / FT231X datasheets into [docs/](docs/)

---

*Built for the Gadget Market hardware submission — deadline 21 Aug 2026.*
