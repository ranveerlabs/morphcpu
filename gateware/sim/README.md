# gateware/sim/

These simulations only need Icarus Verilog, not the FPGA vendor tools.

```sh
./run_sims.sh
```

what that prints, tail end of it:

```
  ok  tick 4 -> only cell 3 lit

PASS: 13/13 checks

tb_grid.v:252: $finish called at 4040000 (1ps)
  tb_grid OK

==============================================================
  tb_morphcpu_top
==============================================================
VCD info: dumpfile tb_morphcpu_top.vcd opened for output.
TEST 1: PASS chain across row 0, driven entirely over UART
  ok  PASS chain result over UART -> 0xa5
TEST 2: INV in the chain
  ok  INV chain result over UART -> 0x5a
TEST 3: ADD convergence across two rows
  ok  ADD convergence result over UART -> 0x2c
TEST 4: LEDs track fabric activity
  ok  all LEDs dark after CLEAR
  ok  led[0] lit while cell 0 holds the value

PASS: 5/5 checks

tb_morphcpu_top.v:228: $finish called at 7044773750 (1ps)
  tb_morphcpu_top OK

RESULT: all testbenches passed
```

There are 13 fabric checks and 5 top-level checks. [tb_grid.v](tb_grid.v) drives
the config chain directly, so it only tests the fabric.
[tb_morphcpu_top.v](tb_morphcpu_top.v) sends data through the UART without
reaching into the design hierarchy. That also checks the wire protocol and bit
ordering, so if only this testbench breaks, the UART path is a good place to look.

run one by hand:

```sh
iverilog -g2005 -Wall -o out/tb_grid.vvp -s tb_grid ../rtl/*.v tb_grid.v
(cd out && vvp tb_grid.vvp)
```

waveforms:

```sh
cd out
gtkwave tb_grid.vcd
```

`out/` and `*.vcd` / `*.fst` files are gitignored. Commit the testbench, not the
waveform dump.

## pictures out of the dump

[vcd_png.js](vcd_png.js) turns a dump into a png of the activity taps, one row
per cell, one column per tick. no deps, node only

```sh
node vcd_png.js out/tb_grid.vcd ../../docs/img/sim-002-grid-activity.png
```

As a value moves across the fabric, it leaves a diagonal streak, one cell per
tick. A routing bug changes the slope. The top-level dump has no `tick` in scope,
so it samples on LED changes instead. Since the LEDs are pulse-stretched, that
plot looks like a filled triangle rather than a diagonal.
