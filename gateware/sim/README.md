# gateware/sim/

iverilog only, no vendor tools

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

13 + 5. [tb_grid.v](tb_grid.v) drives the config chain directly so it only tests
the fabric. [tb_morphcpu_top.v](tb_morphcpu_top.v) goes in thru the UART and
never reaches into the hierarchy so it covers the wire protocol and the config
bit ordering too. second one breaking on its own points at the protocol

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

`out/` and any `*.vcd` / `*.fst` are gitignored. commit the testbench, not the
dump

## pictures out of the dump

[vcd_png.js](vcd_png.js) turns a dump into a png of the activity taps, one row
per cell, one column per tick. no deps, node only

```sh
node vcd_png.js out/tb_grid.vcd ../../docs/img/sim-002-grid-activity.png
```

a value moving across the fabric shows up as a diagonal streak, one cell per
tick, so a routing bug slopes the wrong way and you see it instantly. the top
level dump has no `tick` in scope so there it samples on led changes instead and
you get a filled triangle instead of a diagonal, the leds are pulse stretched
