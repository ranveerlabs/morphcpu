# hardware/

KiCad project for the MorphCPU board.

## Status

**No KiCad files yet.** What exists is the electrical design that has to be
settled first:

- **[DESIGN.md](DESIGN.md)** — power tree, net-by-net connections, decoupling
  plan, PCB brief, JLCPCB assembly notes, and the list of datasheet items still
  open.
- **[../docs/BOM.md](../docs/BOM.md)** — verified LCSC parts and prices.

Read [DESIGN.md](DESIGN.md) before drawing anything. Two findings in it change
the parts list outright:

1. The design needs **two regulators** (3.3 V and 1.2 V). USB-C supplies 5 V and
   the iCE40UP5K runs on neither.
2. The 12 MHz clock must be an **active oscillator module**, not a bare crystal
   — the iCE40 has no crystal amplifier.

## Board summary

| Block | Part | LCSC |
|---|---|---|
| FPGA | ICE40UP5K-SG48I, QFN-48-EP | C2678152 |
| USB–UART | FT231XS-R, SSOP-20 | C132160 |
| Config flash | W25Q32JVSSIQ, SOIC-8 | C179173 |
| USB-C | TYPE-C-31-M-12, 16-pin | C165948 |
| 3.3 V | AMS1117-3.3, SOT-223 | C6186 |
| 1.2 V | 1.2 V LDO | to confirm |
| Clock | 12 MHz active XO, 3225 | to confirm |
| Status | 16 × KT-0603R, 0603 | C2286 |

Round 2-layer board, 60 mm diameter, 4 × M2 mounting holes on a 24 mm radius —
these numbers are shared with [../case/morphcpu_case.scad](../case/morphcpu_case.scad)
and must stay in step with it.

## When the layout exists

Tracked: `*.kicad_pro`, `*.kicad_sch`, `*.kicad_pcb`, `*.kicad_sym`,
`*.kicad_mod`, `*.kicad_dru`. Ignored: backups, autosaves, netlists and
generated fab output — see [../.gitignore](../.gitignore).

Generate fabrication output into `fab_output/` and attach it to a tagged
release rather than committing gerbers.
