# hardware/scripts/

generators for the KiCad project. the schematic and the placement are both
produced from source instead of drawn by hand, so the netlist has exactly one
authority and regenerating costs nothing.

| File | What it does |
|---|---|
| [netlist.py](netlist.py) | the netlist, transcribed from [../DESIGN.md](../DESIGN.md). every connection maps to a row in a DESIGN.md table |
| [ksym.py](ksym.py) | small KiCad s-expression reader/writer + symbol pin extractor |
| [gen_schematic.py](gen_schematic.py) | emits `../morphcpu.kicad_sch` |
| [gen_pcb.py](gen_pcb.py) | emits `../morphcpu.kicad_pcb`, outline + placement, no routing |
| [gen_fab.py](gen_fab.py) | emits `../fab_output/`: gerbers, drill, JLC BOM and CPL, zip |

## running

use KiCad's bundled python, nothing extra to install:

```sh
KP="/c/Users/ranve/AppData/Local/Programs/KiCad/10.0/bin/python.exe"
"$KP" hardware/scripts/gen_schematic.py
```

then check it:

```sh
CLI="/c/Users/ranve/AppData/Local/Programs/KiCad/10.0/bin/kicad-cli.exe"
"$CLI" sch erc --output erc.rpt --severity-all --exit-code-violations hardware/morphcpu.kicad_sch
"$CLI" sch export netlist --output morphcpu.net hardware/morphcpu.kicad_sch
```

**regenerating the PCB blows away hand routing.** placement is generated, tracks
are not. once you start routing, stop running `gen_pcb.py` or keep the routed
file somewhere safe first.

## fab output

```sh
"$KP" hardware/scripts/gen_fab.py
```

writes `../fab_output/`: `morphcpu-gerbers.zip` (the file JLC's uploader wants),
`morphcpu-bom.csv`, `morphcpu-cpl.csv`, and a `gerbers/` dir with the loose
plots. the loose plots aren't tracked, the zip and the two CSVs are, and the
loose files regenerate.

the LCSC column comes from a table inside `gen_fab.py` transcribed out of
[../../docs/BOM.md](../../docs/BOM.md). any row BOM.md hasn't pinned gets an
**empty** LCSC field, never a guess, and the script lists them on stderr when it
finishes. right now all 22 are pinned so it should print nothing.

gerbers, drill and CPL are all plotted in **absolute** coordinates. the board
sets no aux axis origin, so the drill/place origin and the page origin are the
same point and all three files share one coordinate system. if an aux origin
ever gets added, all three exports have to switch to `--use-drill-file-origin`
together, or the CPL ends up offset from the copper and you find out at
assembly.

## why global labels instead of drawn wires

connectivity is expressed with global labels, not wire segments. a global label
joins nets **by name**, so every pin carrying the same net name is connected no
matter where its symbol sits.

drawing wires programmatically means computing polylines between pin endpoints
and trusting they land exactly on them. a wire that stops 0.01 mm short looks
connected and isn't. labels delete that failure mode entirely, and ERC plus the
exported netlist confirm the result. it's a legitimate schematic style for a
dense board and it's what makes a generated schematic trustworthy.

## gotchas found the hard way

- **derived symbols have to be embedded flattened.** `ME6211C12M5` only extends
  `ME6211C33M5`. emitting the parent body under the child's name loads fine but
  trips ERC `lib_symbol_mismatch`, because the properties still read as the
  parent. the nested per-unit sub-symbols also have to be renamed to the child
  or the file won't load at all. `kicad-cli` says "Failed to load schematic" and
  nothing else, which is not much to go on.
- **references need a trailing digit.** `C_EN` reads as unannotated, `C19`
  doesn't.
- **symbol origins belong on the 1.27 mm grid.** pin offsets are multiples of
  1.27, so an off-grid origin puts every single pin off-grid.
- **unit 0 pins apply to all units.** look pins up in the requested unit first,
  then fall back to unit 0.
- **`board.Add(fp)` before `fp.Flip()`.** pcbnew segfaults with no traceback if
  you flip a footprint that isn't on the board yet. the bindings don't check
  ownership.
