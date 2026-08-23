// ---------------------------------------------------------------------------
// morphcpu_case.scad - slim open-face frame for the MorphCPU board
//
// The face is fully open on purpose. The 16-LED grid is the whole point of the
// board, so nothing sits between it and the viewer - the frame only wraps the
// edge, lifts the board off the desk, and takes the USB-C strain.
//
// !! DIMENSIONS ARE ASSUMPTIONS, NOT MEASUREMENTS !!
//
// The PCB does not exist yet, so every board-derived number below is a stated
// assumption. When the layout is finished, set pcb_dia, pcb_thickness,
// mount_hole_r, mount_hole_count, mount_hole_angle_offset, usb_angle and
// usb_z_centre from the actual board and re-export. Nothing else should need
// touching - that is what the parameters are for.
//
// Print notes: no supports needed, the whole thing is a single extrusion with
// a flat bottom. 0.2 mm layers, 3 perimeters. PETG or ABS if it will sit in a
// warm room, PLA is fine otherwise.
// ---------------------------------------------------------------------------

/* [Board - set these from the finished PCB] */

// Diameter of the round PCB (mm).
pcb_dia = 70.0;
// PCB thickness (mm). 1.6 is the JLCPCB default.
pcb_thickness = 1.6;
// Radius of the mounting hole bolt circle, from board centre (mm).
mount_hole_r = 29.0;
// How many mounting holes.
mount_hole_count = 4;
// Rotation of the first mounting hole (degrees).
mount_hole_angle_offset = 45;
// Where the USB-C connector sits on the board edge (degrees, 0 = +X).
usb_angle = 0;

/* [Fit and wall] */

// Gap between PCB edge and inner wall. 0.3 suits a well-calibrated FDM printer.
fit_clearance = 0.3;
// Side wall thickness (mm).
wall = 2.4;
// Floor thickness (mm).
floor_thickness = 2.0;
// Clear space under the PCB for back-side parts and screw heads (mm).
standoff_height = 3.0;
// How far the wall rises above the top face of the PCB (mm).
rim_height = 1.2;

/* [Fasteners] */

// Pilot hole for a self-tapping M2 screw into plastic. Use 2.2 for a
// clearance hole if you would rather use heat-set inserts.
screw_pilot_dia = 1.7;
// Outer diameter of each standoff post.
standoff_dia = 5.0;
// How deep the pilot hole goes into the post.
screw_depth = 5.0;

/* [Cutouts] */

// USB-C receptacle opening. A vertical-mount USB-C is about 8.94 x 3.26 mm;
// these are that plus clearance for the shell and a plug boot.
usb_cutout_w = 10.0;
usb_cutout_h = 4.6;
// Height of the USB-C opening centre above the top face of the PCB (mm).
// Negative means the connector body sits below the board surface.
usb_z_centre = 1.2;

// Cable-side relief so a chunky USB-C plug boot does not foul the rim.
usb_relief_w = 14.0;

/* [Cosmetic] */

// Chamfer on the top outer edge (mm).
top_chamfer = 0.8;
// Lightening/vent holes in the floor.
vent_holes = true;
vent_hole_dia = 4.0;
vent_ring_r = 18.0;
vent_count = 8;

/* [Render] */

// "frame"    - the printable part, this is what gets exported
// "assembly" - frame plus a mock PCB, for checking fit visually
// "pcb"      - the mock board on its own
part = "frame";

$fn = 128;

// ---------------------------------------------------------------------------
// Derived
// ---------------------------------------------------------------------------
pocket_dia   = pcb_dia + 2 * fit_clearance;
outer_dia    = pocket_dia + 2 * wall;
pcb_z        = floor_thickness + standoff_height;      // underside of the PCB
total_h      = pcb_z + pcb_thickness + rim_height;
eps          = 0.01;

// ---------------------------------------------------------------------------
// Modules
// ---------------------------------------------------------------------------

// Positions of the mounting posts, shared by the frame and the mock PCB so the
// two can never drift apart.
module at_mount_holes() {
    for (i = [0 : mount_hole_count - 1]) {
        a = mount_hole_angle_offset + i * (360 / mount_hole_count);
        rotate([0, 0, a])
            translate([mount_hole_r, 0, 0])
                children();
    }
}

// Solid outer body, with the top outer edge chamfered.
module body() {
    difference() {
        cylinder(h = total_h, d = outer_dia);

        // Chamfer: subtract a cone that widens as it goes up past the rim.
        translate([0, 0, total_h - top_chamfer])
            cylinder(h = top_chamfer + eps,
                     d1 = outer_dia - 2 * top_chamfer,
                     d2 = outer_dia + 2 * eps);
    }
}

// The pocket the board drops into, open all the way to the top so the LED grid
// is unobstructed and the board can be lowered straight in.
module board_pocket() {
    translate([0, 0, floor_thickness])
        cylinder(h = total_h, d = pocket_dia);
}

module standoffs() {
    at_mount_holes()
        cylinder(h = pcb_z, d = standoff_dia);
}

module standoff_holes() {
    at_mount_holes()
        translate([0, 0, pcb_z - screw_depth])
            cylinder(h = screw_depth + eps, d = screw_pilot_dia);
}

// USB-C opening through the wall, plus a wider shallow relief on the outside
// so a moulded plug boot clears the rim.
module usb_cutout() {
    z = pcb_z + pcb_thickness + usb_z_centre;
    rotate([0, 0, usb_angle]) {
        // Through the wall.
        translate([outer_dia / 2, 0, z])
            rotate([0, 90, 0])
                translate([0, 0, -wall * 2])
                    linear_extrude(height = wall * 4)
                        offset(r = 0.8, $fn = 32)
                            square([usb_cutout_h - 1.6, usb_cutout_w - 1.6],
                                   center = true);

        // Outer relief, cut back to the pocket wall.
        translate([outer_dia / 2 - wall / 2, 0, z])
            rotate([0, 90, 0])
                translate([0, 0, -wall])
                    linear_extrude(height = wall * 2)
                        offset(r = 1.2, $fn = 32)
                            square([usb_cutout_h + 1.2, usb_relief_w - 2.4],
                                   center = true);
    }
}

module vents() {
    if (vent_holes) {
        for (i = [0 : vent_count - 1]) {
            a = i * (360 / vent_count) + (360 / vent_count) / 2;
            rotate([0, 0, a])
                translate([vent_ring_r, 0, -eps])
                    cylinder(h = floor_thickness + 2 * eps, d = vent_hole_dia);
        }
    }
}

module frame() {
    difference() {
        union() {
            difference() {
                body();
                board_pocket();
            }
            standoffs();
        }
        standoff_holes();
        usb_cutout();
        vents();
    }
}

// Mock board, for eyeballing fit only. Never exported.
module mock_pcb() {
    color("#1b6b3a")
        difference() {
            translate([0, 0, pcb_z])
                cylinder(h = pcb_thickness, d = pcb_dia);
            at_mount_holes()
                translate([0, 0, pcb_z - eps])
                    cylinder(h = pcb_thickness + 2 * eps, d = 2.2);
        }

    // The 4x4 LED grid, drawn where the layout should put it: centred, and
    // large enough to read as the fabric map from arm's length.
    led_pitch = 9.0;
    color("#d94f2b")
        for (r = [0 : 3], c = [0 : 3])
            translate([(c - 1.5) * led_pitch,
                       (1.5 - r) * led_pitch,
                       pcb_z + pcb_thickness])
                cube([1.6, 0.8, 0.6], center = true);
}

// ---------------------------------------------------------------------------
if (part == "frame")         frame();
else if (part == "assembly") { frame(); mock_pcb(); }
else if (part == "pcb")      mock_pcb();
else                         frame();
