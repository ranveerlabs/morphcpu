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
