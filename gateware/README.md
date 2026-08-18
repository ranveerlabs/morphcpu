# gateware/

Verilog source for the iCE40UP5K.

| File | Purpose |
|---|---|
| _(tbd)_ `cell.v` | A single reconfigurable cell: operation ALU + routing register |
| _(tbd)_ `grid.v` | The cell array and inter-cell interconnect |
| _(tbd)_ `uart_rx.v` | UART receiver (config + host input) |
| _(tbd)_ `config_loader.v` | Shifts cell descriptors into the grid's config registers |
| _(tbd)_ `top.v` | Top level: clock, reset, LEDs, USB-UART pins |
| _(tbd)_ `morphcpu.pcf` | Pin constraints for the iCE40UP5K-SG48 |

Build flow: `yosys` → `nextpnr-ice40` → `icepack` → `iceprog`.

Testbenches live in [sim/](sim/).
