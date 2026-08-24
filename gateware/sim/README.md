# gateware/sim/

testbenches. Icarus Verilog only, no vendor tools.

```sh
./run_sims.sh
```

18/18 checks passing.

| Testbench | Covers |
|---|---|
| [tb_grid.v](tb_grid.v) | the fabric. per-tick latency, all four ops, two streams converging, activity taps |
| [tb_morphcpu_top.v](tb_morphcpu_top.v) | end to end over the real UART protocol |

the split matters. `tb_grid` drives the config chain directly, so it tests the
fabric. `tb_morphcpu_top` goes in through the UART and never reaches into the
hierarchy, so it also proves the wire protocol and the config bit ordering are
right. if only the second one breaks, it's the protocol, not the logic.

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
dump.

## pictures out of the dump

[vcd_png.js](vcd_png.js) turns a dump into a png of the activity taps, one row
per cell, one column per tick. no deps, node only.

```sh
node vcd_png.js out/tb_grid.vcd ../../docs/img/sim-002-grid-activity.png
```

a value moving across the fabric shows up as a diagonal streak, one cell per
tick, so a routing bug slopes the wrong way and you see it instantly. the top
level dump has no `tick` in scope so there it samples on led changes instead,
which makes a filled triangle rather than a diagonal because the leds are pulse
stretched.
