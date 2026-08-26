# hardware/

KiCad project. 0 tracks. placement is done, routing isnt

[DESIGN.md](DESIGN.md) first [ROUTING.md](ROUTING.md) second

| | |
|---|---|
| `morphcpu.kicad_sch` | generated. ERC 0/0 |
| `morphcpu.kicad_pcb` | 80 components + 4 mounting holes, 92 nets, 0 tracks |
| `morphcpu.kicad_dru` | JLC rules Board Setup cant express |
| [scripts/](scripts/) | generators |
| `fab_output/` | gerbers drill BOM CPL zip |

DRC on the placement: 0 courtyard, 0 shorting, 0 clearance. the 167 unconnected
and the one silk overlap are just what unrouted looks like

`fab_output/` will get you a quote but isnt orderable, copper layers are empty.

## board

Round, 70mm, 2 layer. 4xM2 on a 29mm radius at 45/135/225/315, shared with
[../case/morphcpu_case.scad](../case/morphcpu_case.scad)

was 60mm first and it just didnt go. 79 footprints with a QFN-48, an SSOP-20, a
SOIC-8 and an edge USB-C left nothing between the resistor ring and the outer
parts

## before you touch it

1. two regulators not one. 5V in, UP5K wants 1v2 core and 3v3 io.
2. 1v2 before 3v3. obvious cascade is backwards. both regs off 5V in parallel,
   3v3 held off by an RC on its enable. so it needs an enable pin, AMS1117 out.
3. clock is an active oscillator. no crystal amp in the iCE40, no XIN/XOUT on
   SG48.

citations in [DESIGN.md](DESIGN.md)

## regenerating

Dont hand-edit the .kicad_sch or the placement, next regen eats it. routing is
the exception. [scripts/](scripts/) has the commands

tracked: `*.kicad_pro` `*.kicad_sch` `*.kicad_pcb` `*.kicad_sym` `*.kicad_mod`
`*.kicad_dru` the fab zip the two CSVs. rest regenerates, see
[../.gitignore](../.gitignore).
