# case/

Slim open-face frame for the MorphCPU board, written as parametric OpenSCAD.

![Case with a mock board fitted](../docs/img/case-assembly-preview.png)

| File | What it is |
|---|---|
| [morphcpu_case.scad](morphcpu_case.scad) | Parametric source — the real deliverable |
| [morphcpu_case.stl](morphcpu_case.stl) | Binary STL, print-ready |
| [morphcpu_case.3mf](morphcpu_case.3mf) | 3MF, same geometry, better for CAD import |
| [export.sh](export.sh) | Regenerates both plus the preview renders |

## Design

The face is completely open. The 16-LED grid is the demo, so nothing sits
between it and the viewer — the frame only wraps the board edge, lifts it clear
of the desk, and takes the USB-C strain. The board drops straight in from the
top onto four standoff posts and screws down; there is no lid and no light pipe
to align.

Current geometry: **65.4 mm outside diameter, 7.8 mm tall**, 2.4 mm wall,
3 mm of clearance under the board for back-side parts, and eight lightening
holes in the floor.

## Dimensions are assumptions, not measurements

The PCB does not exist yet, so every board-derived parameter is a *stated
assumption*:

| Parameter | Assumed | Set from |
|---|---|---|
| `pcb_dia` | 60.0 mm | Final board outline |
| `pcb_thickness` | 1.6 mm | JLCPCB default stackup |
| `mount_hole_r` | 24.0 mm | Mounting hole bolt circle |
| `mount_hole_count` | 4 | Layout |
| `mount_hole_angle_offset` | 45° | Layout |
| `usb_angle` | 0° (+X edge) | Where the connector ends up |
| `usb_z_centre` | 1.2 mm above board top | Connector datasheet + placement |

When the layout is finished, update those seven numbers and re-run
`export.sh`. Nothing else should need to change — that is what the parameters
are for.

## Rebuilding

```sh
cd case
./export.sh
# or, if openscad is not on PATH:
OPENSCAD="/c/Program Files/OpenSCAD (Nightly)/openscad.com" ./export.sh
```

Render variants without exporting by setting `part`:

```sh
openscad -D 'part="assembly"' morphcpu_case.scad   # frame + mock board
openscad -D 'part="frame"'    morphcpu_case.scad   # printable part only
openscad -D 'part="pcb"'      morphcpu_case.scad   # mock board only
```

The exported solid is manifold with genus 12 (four screw holes, eight vents),
which OpenSCAD reports on every export — worth glancing at after a parameter
change, since a non-manifold result there usually means two features have
started to intersect.

## No STEP file, and why

OpenSCAD cannot export STEP. Its CLI supports `stl, off, wrl, amf, 3mf, csg,
dxf, svg, pdf, png` and nothing else, because OpenSCAD is a mesh/CSG modeller
and STEP is a B-rep format — there is no boundary representation to write out.

If a STEP file is genuinely needed:

1. **Import the 3MF into FreeCAD** and export STEP from there. The result is a
   valid STEP file but a *tessellated* one — thousands of flat facets rather
   than true analytic cylinders. Fine for fit checks and for a fabricator who
   just wants a solid; not a clean parametric model.
2. **Rebuild in a B-rep tool** (FreeCAD's Part Design, or CadQuery if the
   parametric-source requirement matters) if a real STEP is required.

STL and 3MF cover 3D printing, which is what this part is for. Option 1 is the
cheap path if a STEP is needed for a submission requirement.

## Printing

No supports needed — flat bottom, single extrusion direction. 0.2 mm layers,
3 perimeters. PLA is fine; PETG or ABS if it will live somewhere warm.

The `fit_clearance` parameter is 0.3 mm, which suits a well-calibrated FDM
printer. Print a test ring first if the board is a tight or sloppy fit.
