# case/

Open-face frame, parametric OpenSCAD. board drops onto four posts and screws
down. no lid, nothing over the leds

![case with a mock board in it](../docs/img/case-assembly-preview.png)

75.4mm OD, 7.8mm tall, 2.4mm wall, 3mm under the board for back-side parts. the
75.4 falls out of 70 board + 2×0.3 fit clearance + 2×2.4 wall so it moves if any
of those do

```sh
./export.sh
OPENSCAD="/c/Program Files/OpenSCAD (Nightly)/openscad.com" ./export.sh   # not on PATH
```

variants without exporting:

```sh
openscad -D 'part="assembly"' morphcpu_case.scad
openscad -D 'part="frame"'    morphcpu_case.scad
openscad -D 'part="pcb"'      morphcpu_case.scad
```

## every board number in here is a guess

the PCB doesnt exist yet so

| param | assumed | comes from |
|---|---|---|
| `pcb_dia` | 70.0 mm | final board outline |
| `pcb_thickness` | 1.6 mm | JLCPCB default stackup |
| `mount_hole_r` | 29.0 mm | bolt circle |
| `mount_hole_count` | 4 | layout |
| `mount_hole_angle_offset` | 45 deg | layout |
| `usb_angle` | 0 deg (+X edge) | where the connector ends up |
| `usb_z_centre` | 1.2 mm above board top | connector datasheet + placement |

update those seven after routing and re-run export.sh

## STEP

OpenSCAD wont do it. the CLI does `stl, off, wrl, amf, 3mf, csg, dxf, svg, pdf,
png` and thats the lot, its a mesh modeller and STEP is B-rep

`morphcpu_case.step` is the 3MF pushed thru FreeCAD 1.1.3, `Mesh.insert` then
`makeShapeFromMesh` with sewing then `Part.export`. it comes out a closed solid,
75.4 x 75.4 x 7.8mm, 11627.5mm3, 2621 faces. tessellated though, those faces are
mesh triangles welded up and not real cylinders. fine for a fit check, rebuild it
in Part Design or CadQuery if you need a proper one

## printing

no supports, flat on its back, 0.2mm layers, 3 perimeters. PLA unless it lives
somewhere warm

export prints genus 12 every time, four screw holes and eight vents. a
different number after a param change means two features started intersecting

`fit_clearance` is 0.3mm. print a test ring first, mine came out tight
