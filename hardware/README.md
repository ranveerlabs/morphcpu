# hardware/

KiCad project for the 4-layer board. It is placed and routed.

Start with [DESIGN.md](DESIGN.md), then see [ROUTING.md](ROUTING.md) for the
routing details.

| | |
|---|---|
| `morphcpu.kicad_sch` | generated. ERC 0/0 |
| `morphcpu.kicad_pcb` | 80 components + 4 mounting holes, 546 tracks, 193 vias |
| `morphcpu.kicad_dru` | JLC rules Board Setup cant express |
| [scripts/](scripts/) | generators |
| `fab_output/` | gerbers drill BOM CPL zip |

The latest DRC run had 0 violations, 0 unconnected items and 0 schematic
mismatches. LED1 uses FPGA pin 45 and LED2 uses pin 42. The schematic, source
netlist and PCF all agree.

`fab_output/` was generated from the routed board, with copper on all four
layers. The updated pin map still needs a bitstream build. See
[ROUTING.md](ROUTING.md).

## board

The board is round, 70 mm across, with four layers. Four M2 holes sit on a 29 mm
radius at 45, 135, 225 and 315 degrees. The case uses the same positions in
[../case/morphcpu_case.scad](../case/morphcpu_case.scad)

I started at 60 mm, but that didnt leave enough room. There are 79 footprints,
including a QFN-48, SSOP-20, SOIC-8 and edge-mounted USB-C, all packed around the
resistor ring.

## before you touch it

1. There are two regulators. The UP5K needs 1.2 V core and 3.3 V I/O.
2. The 1.2 V rail has to come up before 3.3 V. Both regulators run from 5 V in
   parallel, and an RC delay holds 3.3 V off. That means the 3.3 V regulator
   needs an enable pin, so the AMS1117 doesnt work here.
3. The clock comes from an active oscillator. The iCE40 has no crystal amplifier,
   and the SG48 has no XIN/XOUT pins.

citations in [DESIGN.md](DESIGN.md)

## regenerating

Dont hand-edit `.kicad_sch` or the placement. Regenerating replaces them, though
the routed tracks are kept. The commands are in [scripts/](scripts/).

tracked: `*.kicad_pro` `*.kicad_sch` `*.kicad_pcb` `*.kicad_sym` `*.kicad_mod`
`*.kicad_dru` the fab zip the two CSVs. rest regenerates, see
[../.gitignore](../.gitignore)
