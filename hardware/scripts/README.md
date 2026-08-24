# hardware/scripts/

Generators for the KiCad project. The schematic and the PCB placement are both
produced from source rather than drawn by hand, so the netlist has exactly one
authority and regenerating is cheap.

| File | What it does |
|---|---|
| [netlist.py](netlist.py) | The netlist, transcribed from [../DESIGN.md](../DESIGN.md). Every connection here maps to a row in a DESIGN.md table |
| [ksym.py](ksym.py) | Small KiCad s-expression reader/writer and symbol-pin extractor |
| [gen_schematic.py](gen_schematic.py) | Emits `../morphcpu.kicad_sch` |
| [gen_pcb.py](gen_pcb.py) | Emits `../morphcpu.kicad_pcb` — outline + placement, no routing |
| [gen_fab.py](gen_fab.py) | Emits `../fab_output/` — Gerbers, drill, JLC BOM and CPL, gerber zip |

## Running

Use KiCad's bundled Python — no extra packages needed:

```sh
KP="/c/Users/ranve/AppData/Local/Programs/KiCad/10.0/bin/python.exe"
"$KP" hardware/scripts/gen_schematic.py
```

Then check it:

```sh
CLI="/c/Users/ranve/AppData/Local/Programs/KiCad/10.0/bin/kicad-cli.exe"
"$CLI" sch erc --output erc.rpt --severity-all --exit-code-violations hardware/morphcpu.kicad_sch
"$CLI" sch export netlist --output morphcpu.net hardware/morphcpu.kicad_sch
```

## Fabrication output

```sh
"$KP" hardware/scripts/gen_fab.py
```

Writes `../fab_output/`: `morphcpu-gerbers.zip` (the file JLC's uploader wants),
`morphcpu-bom.csv`, `morphcpu-cpl.csv`, and a `gerbers/` directory holding the
loose plots. Per [../../.gitignore](../../.gitignore) the loose plots are not
tracked — the zip and the two CSVs are, and the loose files regenerate.

The LCSC column is filled from a table in `gen_fab.py` transcribed from
[../../docs/BOM.md](../../docs/BOM.md). Rows BOM.md has not pinned to an LCSC
number get an **empty** LCSC field, never a guess, and the script lists them on
stderr when it finishes.

Gerbers, drill and CPL are all plotted in **absolute** coordinates. The board
sets no aux axis origin, so the drill/place origin and the page origin coincide
and all three files share one coordinate system. If an aux origin is ever added
to the board, every one of those three exports has to switch to
`--use-drill-file-origin` together, or the CPL will be offset from the copper.

## Why global labels instead of drawn wires

Connectivity is expressed with global labels, not wire segments. A global label
joins nets **by name**, so every pin carrying the same net name is connected
regardless of where its symbol sits.

Drawing wires programmatically means computing polylines between pin endpoints
and trusting that they land exactly on them — a wire that stops 0.01 mm short
looks connected and is not. Labels remove that entire failure mode, and ERC
plus the exported netlist confirm the result. It is a legitimate schematic
style for a dense board, and it is what makes a generated schematic
trustworthy.

## Gotchas found while building this

- **Derived symbols must be embedded flattened.** `ME6211C12M5` only extends
  `ME6211C33M5`. Emitting the parent body under the child's name loads, but
  trips ERC `lib_symbol_mismatch` because the properties still read as the
  parent. The nested per-unit sub-symbols also have to be renamed to the child,
  or the file will not load at all.
- **References need a trailing digit.** `C_EN` reads as unannotated; `C19` does
  not.
- **Symbol origins belong on the 1.27 mm grid.** Pin offsets are multiples of
  1.27, so an off-grid origin puts every pin off-grid.
- **Unit 0 pins apply to all units.** Look pins up in the requested unit first,
  then fall back to unit 0.
