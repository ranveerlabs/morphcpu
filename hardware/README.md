# hardware/

KiCad project for the MorphCPU board.

## whats here

| Path | What it is |
|---|---|
| [DESIGN.md](DESIGN.md) | the electrical spec. power tree, every net, decoupling, PCB brief, JLC notes. read this first |
| [ROUTING.md](ROUTING.md) | net classes, JLC DRC rules, what to route in what order, post-routing checklist. read this second |
| `morphcpu.kicad_dru` | the JLC rules Board Setup cant express. via drill floor, split hole-to-hole, PTH-to-track |
| `morphcpu.kicad_sch` | schematic, generated. ERC clean, 0 errors 0 warnings |
| `morphcpu.kicad_pcb` | board. 80 footprints, 92 nets, **0 tracks** |
| [scripts/](scripts/) | the generators. schematic and placement both come from source, not hand-drawing |
| `fab_output/` | gerbers, drill, JLC BOM and CPL, plus the zip JLC's uploader wants |

## state

schematic done, placement done, **routing not done**. zero tracks on the board.

placement is DRC clean on everything that matters: 0 courtyard overlaps, 0
shorting pads, 0 clearance violations. the 167 unconnected items and 3 cosmetic
silk overlaps are exactly what an unrouted board looks like.

the fab package in `fab_output/` is real and JLC will quote from it, because a
quote only reads size, layer count and placement. it is **not** orderable. route
it first.

why no routing: KiCad has no autorouter, and emitting trace coordinates without
looking at the board produces a file that looks finished and isnt. on a $210
budget thats the worst possible outcome. see
[What is not here](DESIGN.md#what-is-not-here).

## board summary

| Block | Part | LCSC |
|---|---|---|
| FPGA | ICE40UP5K-SG48I, QFN-48-EP | C2678152 |
| USB-UART | FT231XS-R, SSOP-20 | C132160 |
| config flash | W25Q32JVSSIQ, SOIC-8 | C179173 |
| USB-C | TYPE-C-31-M-12, 16-pin | C165948 |
| ESD array | USBLC6-2SC6, SOT-23-6 | C7519 |
| 3.3 V | ME6211C33M5G-N, SOT-23-5 | C82942 |
| 1.2 V | ME6211C12M5G-N, SOT-23-5 | C236672 |
| clock | 1532H4-16000JWPDTSNL, 16 MHz XO, 3225 | C5383161 |
| status | 17 × KT-0603R, 0603 | C2286 |

round 2-layer board, **70 mm diameter**, 4 × M2 on a 58 mm bolt circle (29 mm
radius) at 45/135/225/315 deg. those numbers are shared with
[../case/morphcpu_case.scad](../case/morphcpu_case.scad) and have to stay in
step with it.

it was 60 mm and didnt fit. 79 footprints with a QFN-48, an SSOP-20, a SOIC-8
and an edge-mounted USB-C left nothing between the LED resistor ring and the
outer parts, and DRC only cleared if you stacked parts over the mounting holes.
70 mm clears with margin. the case is parametric so following the change was two
numbers and a re-export.

## three things that bit

worth knowing before you touch anything here:

1. **two regulators, not one.** USB-C gives you 5 V and the iCE40UP5K runs on
   neither 5 V nor a single rail. it needs 1.2 V core and 3.3 V I/O.
2. **1.2 V has to come up before 3.3 V.** the obvious cascade 5V -> 3V3 -> 1V2
   is exactly backwards per the datasheet power-up sequence. both regulators run
   off 5 V in parallel and the 3.3 V one is held off by an RC on its enable.
   thats why the 3.3 V part must have an enable pin, and why AMS1117 is out.
3. **the clock is an active oscillator module, not a bare crystal.** the iCE40
   has no crystal amplifier and the SG48 pinout has no XIN/XOUT pair.

all three are written up properly with citations in [DESIGN.md](DESIGN.md).

## regenerating

everything here is generated. see [scripts/](scripts/) for how to run them.
dont hand-edit the .kicad_sch or the placement, youll lose it on the next
regen. hand routing is the exception, that lives in the .kicad_pcb and theres
no generator that will overwrite it.

## whats tracked

tracked: `*.kicad_pro`, `*.kicad_sch`, `*.kicad_pcb`, `*.kicad_sym`,
`*.kicad_mod`, `*.kicad_dru`, the fab zip and the two CSVs. ignored: backups,
autosaves, the exported `morphcpu.net`, and the loose gerber plots, all of which
regenerate. see
[../.gitignore](../.gitignore).
