/* [Board - set these from the finished PCB] */

pcb_dia = 70.0;
pcb_thickness = 1.6;
mount_hole_r = 29.0;
mount_hole_count = 4;
mount_hole_angle_offset = 45;
usb_angle = 0;

/* [Fit and wall] */

fit_clearance = 0.3;
wall = 2.4;
floor_thickness = 2.0;
standoff_height = 3.0;
rim_height = 1.2;

/* [Fasteners] */

screw_pilot_dia = 1.7;
standoff_dia = 5.0;
screw_depth = 5.0;

/* [Cutouts] */

usb_cutout_w = 10.0;
usb_cutout_h = 4.6;
usb_z_centre = 1.2;

usb_relief_w = 14.0;

/* [Cosmetic] */

top_chamfer = 0.8;
vent_holes = true;
vent_hole_dia = 4.0;
vent_ring_r = 18.0;
vent_count = 8;

/* [Render] */

part = "frame";

$fn = 128;

pocket_dia   = pcb_dia + 2 * fit_clearance;
outer_dia    = pocket_dia + 2 * wall;
pcb_z        = floor_thickness + standoff_height;
total_h      = pcb_z + pcb_thickness + rim_height;
eps          = 0.01;

module at_mount_holes() {
    for (i = [0 : mount_hole_count - 1]) {
        a = mount_hole_angle_offset + i * (360 / mount_hole_count);
        rotate([0, 0, a])
            translate([mount_hole_r, 0, 0])
                children();
    }
}

module body() {
    difference() {
        cylinder(h = total_h, d = outer_dia);

        translate([0, 0, total_h - top_chamfer])
            cylinder(h = top_chamfer + eps,
                     d1 = outer_dia - 2 * top_chamfer,
                     d2 = outer_dia + 2 * eps);
    }
}

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

module usb_cutout() {
    z = pcb_z + pcb_thickness + usb_z_centre;
    rotate([0, 0, usb_angle]) {
        translate([outer_dia / 2, 0, z])
            rotate([0, 90, 0])
                translate([0, 0, -wall * 2])
                    linear_extrude(height = wall * 4)
                        offset(r = 0.8, $fn = 32)
                            square([usb_cutout_h - 1.6, usb_cutout_w - 1.6],
                                   center = true);

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

module mock_pcb() {
    color("#1b6b3a")
        difference() {
            translate([0, 0, pcb_z])
                cylinder(h = pcb_thickness, d = pcb_dia);
            at_mount_holes()
                translate([0, 0, pcb_z - eps])
                    cylinder(h = pcb_thickness + 2 * eps, d = 2.2);
        }

    led_pitch = 9.0;
    color("#d94f2b")
        for (r = [0 : 3], c = [0 : 3])
            translate([(c - 1.5) * led_pitch,
                       (1.5 - r) * led_pitch,
                       pcb_z + pcb_thickness])
                cube([1.6, 0.8, 0.6], center = true);
}

if (part == "frame")         frame();
else if (part == "assembly") { frame(); mock_pcb(); }
else if (part == "pcb")      mock_pcb();
else                         frame();
