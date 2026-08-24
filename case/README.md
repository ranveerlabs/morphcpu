# case/

slim open-face frame for the MorphCPU board, parametric OpenSCAD.

![Case with a mock board fitted](../docs/img/case-assembly-preview.png)

| File | What it is |
|---|---|
| [morphcpu_case.scad](morphcpu_case.scad) | parametric source, the real deliverable |
| [morphcpu_case.stl](morphcpu_case.stl) | binary STL, print-ready |
| [morphcpu_case.3mf](morphcpu_case.3mf) | 3MF, same geometry, nicer for CAD import |
| [export.sh](export.sh) | regenerates both plus the preview renders |

## what this is

the face is completely open. the 16-LED grid is the demo, so nothing sits between
it and whoever's looking at it. the frame just wraps the board edge, lifts it off
the desk, and takes the USB-C strain. board drops in from the top onto four
standoff posts and screws down. no lid, no light pipe to align.

current geometry: **75.4 mm outside diameter, 7.8 mm tall**, 2.4 mm wall, 3 mm of
clearance under the board for back-side parts, eight lightening holes in the
floor.

75.4 falls out of the params: 70 mm board + 2 × 0.3 mm fit clearance + 2 × 2.4 mm
wall. change any of those and the OD moves with them.

## the dimensions are assumptions

the PCB doesn't exist yet, so every board-derived param is a stated assumption:

| Parameter | Assumed | Set from |
|---|---|---|
| `pcb_dia` | 70.0 mm | final board outline |
| `pcb_thickness` | 1.6 mm | JLCPCB default stackup |
| `mount_hole_r` | 29.0 mm | mounting hole bolt circle |
| `mount_hole_count` | 4 | layout |
| `mount_hole_angle_offset` | 45° | layout |
| `usb_angle` | 0° (+X edge) | where the connector ends up |
| `usb_z_centre` | 1.2 mm above board top | connector datasheet + placement |

when the layout is done, update those seven numbers and re-run `export.sh`.
nothing else should need touching, that's the whole point of the params.

## how to rebuild

```sh
cd case
./export.sh
# openscad not on PATH:
OPENSCAD="/c/Program Files/OpenSCAD (Nightly)/openscad.com" ./export.sh
```

render variants without exporting via `part`:

```sh
openscad -D 'part="assembly"' morphcpu_case.scad   # frame + mock board
openscad -D 'part="frame"'    morphcpu_case.scad   # printable part only
openscad -D 'part="pcb"'      morphcpu_case.scad   # mock board only
```

the exported solid is manifold with genus 12 (four screw holes, eight vents),
which OpenSCAD prints on every export. worth a glance after a param change, a
non-manifold result there usually means two features started intersecting.

## no STEP file

OpenSCAD can't export STEP. its CLI does `stl, off, wrl, amf, 3mf, csg, dxf, svg,
pdf, png` and that's it, because OpenSCAD is a mesh/CSG modeller and STEP is
B-rep. there's no boundary representation to write out.

if you genuinely need STEP:

1. import the 3MF into FreeCAD, export STEP from there. valid STEP file but a
   *tessellated* one, thousands of flat facets instead of real analytic
   cylinders. fine for fit checks and for a fabricator who just wants a solid,
   not a clean parametric model.
2. rebuild it in a B-rep tool (FreeCAD Part Design, or CadQuery if the
   parametric-source thing matters) if you need a real one.

STL and 3MF cover 3D printing, which is all this part is for. option 1 is the
cheap path if some submission requirement asks for STEP.

## printing

no supports, flat bottom, single extrusion direction. 0.2 mm layers,
3 perimeters. PLA is fine, PETG or ABS if it'll live somewhere warm.

`fit_clearance` is 0.3 mm, which suits a well-calibrated FDM printer. print a
test ring first if the board comes out tight or sloppy.
