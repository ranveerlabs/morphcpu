# gateware/sim/

Testbenches and simulation harnesses.

Run with Icarus Verilog:

    iverilog -g2012 -o tb_cell.vvp tb_cell.v ../cell.v
    vvp tb_cell.vvp
    gtkwave tb_cell.vcd

Waveform dumps (`*.vcd`, `*.fst`) are gitignored — commit the testbench, not the output.

| Testbench | Covers |
|---|---|
| _(tbd)_ `tb_cell.v` | Single-cell operation + routing behaviour |
| _(tbd)_ `tb_grid.v` | Multi-cell propagation through the fabric |
| _(tbd)_ `tb_config_loader.v` | UART config stream → grid configuration |
