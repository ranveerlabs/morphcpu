# hardware/

KiCad schematic and PCB project for the MorphCPU board.

## Design targets

| Block | Part | Notes |
|---|---|---|
| FPGA | Lattice iCE40UP5K (SG48 QFN) | 5280 LUT4, 30 × 4kbit BRAM, 1Mbit SPRAM |
| USB–UART | FTDI FT231X | Config upload + host I/O over USB-C |
| Config flash | SPI NOR flash | FPGA bitstream storage for standalone boot |
| Clock | Crystal oscillator | System clock reference |
| Connector | USB-C | Power + data |
| Status | 16 × LED | Live view of grid activity |
| Control | Reset button | FPGA / system reset |

## Files

Tracked: `*.kicad_pro`, `*.kicad_sch`, `*.kicad_pcb`, `*.kicad_sym`, `*.kicad_mod`, `*.kicad_dru`.
Ignored: backups, autosaves, netlists, and generated fab outputs — see [.gitignore](../.gitignore).

Cut fabrication outputs into a versioned release zip rather than committing gerbers.
