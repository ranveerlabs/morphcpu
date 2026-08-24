# docs/img/

renders, screenshots and build photos.

| File | What |
|---|---|
| `case-frame-preview.png` | the printable case on its own |
| `case-assembly-preview.png` | case with a mock board dropped in |
| `pcb-placement-front.png` | board front, the 4x4 led grid |
| `pcb-placement-back.png` | board back, everything else |
| `pcb-3d.png` | 3d render, top |
| `pcb-3d-back.png` | 3d render, bottom |
| `sim-002-grid-activity.png` | activity taps over 28 ticks, from the fabric sim |
| `sim-003-uart-activity.png` | led states through the end to end run |

case renders come out of `case/export.sh`. board renders out of
`kicad-cli pcb render`. the two sim rasters out of
[../../gateware/sim/vcd_png.js](../../gateware/sim/vcd_png.js), which reads the
simulation dump directly so they regenerate from a real run rather than being
screenshots of one.

naming for anything new: `session-NNN-<short-description>.png`. referenced from
[../../JOURNAL.md](../../JOURNAL.md).
