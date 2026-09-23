# hardware/

KiCad project. placed and routed, 4 layers

[DESIGN.md](DESIGN.md) first [ROUTING.md](ROUTING.md) second

| | |
|---|---|
| `morphcpu.kicad_sch` | generated. ERC 0/0 |
| `morphcpu.kicad_pcb` | 80 components + 4 mounting holes, 546 tracks, 193 vias |
| `morphcpu.kicad_dru` | JLC rules Board Setup cant express |
| [scripts/](scripts/) | generators |
| `fab_output/` | gerbers drill BOM CPL zip |

DRC 0 violations, 0 unconnected, 0 schematic mismatches. LED1 uses FPGA pin 45
and LED2 uses pin 42. the schematic, source netlist and PCF agree

`fab_output/` is off the routed board, all four copper layers with copper in
them. the updated pin map still needs a bitstream build, see [ROUTING.md](ROUTING.md)

## board

Round, 70mm, 4 layer. 4xM2 on a 29mm radius at 45/135/225/315, shared with
[../case/morphcpu_case.scad](../case/morphcpu_case.scad)

was 60mm first and it just didnt go. 79 footprints with a QFN-48, an SSOP-20, a
SOIC-8 and an edge USB-C left nothing between the resistor ring and the outer
parts

## before you touch it

1. two regulators not one. 5V in, UP5K wants 1v2 core and 3v3 io
2. 1v2 before 3v3, the obvious cascade is backwards. both regs off 5V in
   parallel, 3v3 held off by an RC on its enable, so it needs an enable pin and
   AMS1117 is out
3. clock is an active oscillator, no crystal amp in the iCE40 and no XIN/XOUT on
   SG48

citations in [DESIGN.md](DESIGN.md)

## regenerating

dont hand-edit the .kicad_sch or the placement, next regen eats it. routing is
the exception. [scripts/](scripts/) has the commands

tracked: `*.kicad_pro` `*.kicad_sch` `*.kicad_pcb` `*.kicad_sym` `*.kicad_mod`
`*.kicad_dru` the fab zip the two CSVs. rest regenerates, see
[../.gitignore](../.gitignore)
