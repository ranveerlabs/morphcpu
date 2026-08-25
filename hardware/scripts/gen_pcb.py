"""Generate hardware/morphcpu.kicad_pcb: board outline + first-pass placement.

PLACEMENT ONLY. No tracks are routed and none should be added here - routing is
a spatial judgment call made by looking at the board, and guessing trace paths
produces a file that looks finished and is not.

Everything is done through the pcbnew API rather than by writing board
s-expressions, so footprint geometry, flipping to the back side, and net
assignment all use KiCad's own code. The netlist is read from the schematic's
exported netlist, which makes this the same operation as "Update PCB from
Schematic".

Run:
  <kicad>/bin/kicad-cli.exe sch export netlist --output hardware/morphcpu.net \
      hardware/morphcpu.kicad_sch
  <kicad>/bin/python.exe hardware/scripts/gen_pcb.py
"""
import collections
import io
import json
import math
import os
import sys

import pcbnew

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ksym

HERE = os.path.dirname(os.path.abspath(__file__))
HW = os.path.normpath(os.path.join(HERE, ".."))
NET_FILE = os.path.join(HW, "morphcpu.net")
OUT = os.path.join(HW, "morphcpu.kicad_pcb")
PRO = os.path.join(HW, "morphcpu.kicad_pro")
FPDIR = r"C:/Users/ranve/AppData/Local/Programs/KiCad/10.0/share/kicad/footprints"

# Board geometry, shared with case/morphcpu_case.scad
CX, CY = 150.0, 100.0      # board centre in KiCad page coordinates
BOARD_R = 35.0             # 70 mm diameter
MOUNT_R = 29.0             # bolt circle radius
MOUNT_ANGLES = [45, 135, 225, 315]
LED_PITCH = 9.0            # matches led_pitch in the case source

FRONT, BACK = "F", "B"


def mm(v):
    return pcbnew.FromMM(float(v))


def pt(x, y):
    return pcbnew.VECTOR2I(mm(x), mm(y))


def board_pt(dx, dy):
    """Offset in mm from board centre -> absolute board point."""
    return pt(CX + dx, CY + dy)


# ---------------------------------------------------------------------------
# Netlist
# ---------------------------------------------------------------------------
def read_netlist(path):
    tree = ksym.parse(open(path, encoding="utf-8").read())
    root = tree[0]

    comps = {}
    for c in ksym.find_all(ksym.find_one(root, "components"), "comp"):
        ref = ksym.unquote(ksym.find_one(c, "ref")[1])
        val = ksym.find_one(c, "value")
        fp = ksym.find_one(c, "footprint")
        comps[ref] = {
            "value": ksym.unquote(val[1]) if val else "",
            "fp": ksym.unquote(fp[1]) if fp else "",
        }

    pinnet = {}
    netnames = []
    for n in ksym.find_all(ksym.find_one(root, "nets"), "net"):
        name = ksym.unquote(ksym.find_one(n, "name")[1])
        netnames.append(name)
        for nd in ksym.find_all(n, "node"):
            ref = ksym.unquote(ksym.find_one(nd, "ref")[1])
            pin = ksym.unquote(ksym.find_one(nd, "pin")[1])
            pinnet[(ref, pin)] = name
    return comps, pinnet, netnames


# ---------------------------------------------------------------------------
# Placement table.  (dx, dy) are mm from board centre; rot in degrees.
# The LED grid is the product, so it owns the centre of the front face and
# everything else works around it on the back.
# ---------------------------------------------------------------------------
def led_xy(i):
    row, col = divmod(i, 4)
    return (col - 1.5) * LED_PITCH, (row - 1.5) * LED_PITCH


PLACEMENT = {}

# Front face: the 4x4 grid owns the centre, cell 0 top-left, row-major - the
# same order as the fabric map, so the ripple reads correctly.
for i in range(16):
    x, y = led_xy(i)
    PLACEMENT["D%d" % (i + 1)] = (x, y, 0, FRONT)

# Front: the two things a person touches or watches, clear of the grid.
PLACEMENT["SW1"] = (0, -21.0, 0, FRONT)
PLACEMENT["D17"] = (0, 21.0, 0, FRONT)

# The back is organised as concentric rings around the FPGA. Radii are chosen
# so each ring clears the next: the QFN courtyard reaches r=4.2, an 0402
# courtyard is about 0.75 either side, and the mounting holes occupy r=22..26
# on the diagonals, so nothing structural goes there.
#
#   r = 0      FPGA
#   r = 6.5    one decoupling cap per supply pin
#   r = 9.0    bulk caps, pull-ups, the VCCPLL and VPP filters
#   r = 11.5   12 of the LED series resistors, each on its own LED's ray
#   r = 14.5   the other 4, the corner LEDs' resistors
#   r >= 17    everything with a real body, on the four cardinal directions
PLACEMENT["U1"] = (0, 0, 0, BACK)


def ring(refs, radius, start_deg=0.0, rotate=True):
    """Space refs evenly around a circle on the back."""
    n = len(refs)
    for k, ref in enumerate(refs):
        ang = start_deg + k * (360.0 / n)
        r = math.radians(ang)
        PLACEMENT[ref] = (radius * math.cos(r), radius * math.sin(r),
                          ang if rotate else 0, BACK)


# One 100 nF per supply pin - seven of them (DESIGN.md decoupling table).
ring(["C1", "C2", "C3", "C4", "C5", "C20", "C21"], 6.5, 10.0)

# The VCCPLL filter and the VPP ferrite sit just outboard of their own caps.
PLACEMENT["R27"] = (9.0 * math.cos(math.radians(267.1)),
                    9.0 * math.sin(math.radians(267.1)), 267.1, BACK)
PLACEMENT["FB1"] = (9.0 * math.cos(math.radians(318.6)),
                    9.0 * math.sin(math.radians(318.6)), 318.6, BACK)

# LED series resistors. Each one sits on the ray from board centre through its
# own LED, so the anode hop is radial and short.
#
# This used to be a uniform 16-slot ring: sort the LEDs by angle, hand out slots
# at k*22.5 starting from 0. The sort was fine, the handout wasn't. The sorted
# list starts at -161.6 deg and slot 0 is at 0 deg, so every resistor landed
# 157-180 deg around the ring from its own LED and all 16 anodes became chords
# straight under the QFN paddle. 405 mm of ratsnest.
#
# A single ring can't be fixed by rotating it either. The 4x4 grid puts the four
# inner LEDs and the four corner LEDs on the *same* four diagonals, so eight
# parts want four rays. The corners go one ring further out to break the tie.
RES_R = 11.5          # inner and middle LEDs
RES_R_CORNER = 14.5   # the four corners, r=19.09, sharing a ray with the inners
for i in range(16):
    x, y = led_xy(i)
    ang = math.degrees(math.atan2(y, x))
    radius = RES_R_CORNER if math.hypot(x, y) > 17.0 else RES_R
    r = math.radians(ang)
    # pad 1 is the FPGA side, pad 2 the LED side. Point pad 2 at the LED, which
    # for the four inner LEDs means facing back inward.
    rot = ang + 180.0 if math.hypot(x, y) < radius else ang
    PLACEMENT["R%d" % (i + 1)] = (radius * math.cos(r), radius * math.sin(r),
                                  rot, BACK)

# Outer region. Cardinal directions only, so the diagonals stay clear for the
# mounting holes at r=29. Bulk caps and pull-ups live beside their loads rather
# than in a ring, which keeps the middle of the board open for routing.

# East - USB-C at the edge, bridge directly behind it.
PLACEMENT["J1"] = (30.0, 0, 90, BACK)
PLACEMENT["U2"] = (20.0, 0, 0, BACK)
# ESD array, as close to J1's D+/D- pads as the first-pass placement allows.
# The direct line between U2 and J1 is a 1.2 mm gap - too narrow for SOT-23-6 -
# and the front face is the LED display, so the part tucks in beside the
# connector instead. Roughly 5 mm of stub; if routing proves that too long,
# the fix is to shift U2 west and reopen the centre channel, not to move the
# clamp further away.
PLACEMENT["U6"] = (29.5, 8.0, 0, BACK)
PLACEMENT["C8"] = (20.0, -7.0, 0, BACK)
PLACEMENT["R20"] = (20.0, 7.0, 0, BACK)
PLACEMENT["FB2"] = (25.5, -7.0, 0, BACK)
PLACEMENT["C14"] = (25.5, -11.0, 0, BACK)
PLACEMENT["C9"] = (25.5, 7.0, 0, BACK)
PLACEMENT["R23"] = (25.5, 11.0, 0, BACK)
PLACEMENT["R24"] = (25.5, 14.0, 0, BACK)
PLACEMENT["C12"] = (16.0, -10.5, 0, BACK)
PLACEMENT["R28"] = (16.0, 10.5, 0, BACK)

# West - configuration flash and oscillator, both close to the FPGA.
PLACEMENT["U3"] = (-20.0, 0, 0, BACK)
PLACEMENT["C6"] = (-20.0, -6.5, 0, BACK)
PLACEMENT["R19"] = (-20.0, 6.5, 0, BACK)
PLACEMENT["X1"] = (-26.0, -6.5, 0, BACK)
PLACEMENT["C7"] = (-26.0, -1.5, 0, BACK)
PLACEMENT["R21"] = (-26.0, 2.5, 0, BACK)
PLACEMENT["R29"] = (-25.5, 6.5, 0, BACK)
PLACEMENT["R30"] = (-25.5, 9.5, 0, BACK)
PLACEMENT["C13"] = (-16.0, -10.5, 0, BACK)
PLACEMENT["R22"] = (-16.0, 10.5, 0, BACK)
PLACEMENT["R17"] = (-13.0, 14.5, 0, BACK)
PLACEMENT["R18"] = (-16.5, 14.5, 0, BACK)

# North - 3V3 regulator and the enable delay that sequences it after 1V2.
PLACEMENT["U4"] = (0, -20.0, 0, BACK)
PLACEMENT["R25"] = (6.0, -18.5, 0, BACK)
PLACEMENT["R26"] = (6.0, -21.5, 0, BACK)
PLACEMENT["C19"] = (6.0, -24.5, 0, BACK)
PLACEMENT["C15"] = (-6.0, -18.5, 0, BACK)
PLACEMENT["C16"] = (-6.0, -21.5, 0, BACK)
PLACEMENT["C11"] = (-6.0, -24.5, 0, BACK)
PLACEMENT["F1"] = (0, -25.5, 90, BACK)

# South - 1V2 regulator, always on, feeding the core.
PLACEMENT["U5"] = (0, 20.0, 0, BACK)
PLACEMENT["C17"] = (-6.0, 18.5, 0, BACK)
PLACEMENT["C10"] = (6.0, 18.5, 0, BACK)
PLACEMENT["C18"] = (6.0, 21.5, 0, BACK)


# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# SaveBoard writes a fresh morphcpu.kicad_pro from the board object's defaults,
# which silently wipes Board Setup: every net class, every DRC minimum, the
# track and via presets. Found it the hard way, one regen ate the whole netclass
# pass. Lift those two blocks out before the save and put them back after.
# ---------------------------------------------------------------------------
KEEP_KEYS = ("design_settings",)


def read_project_settings():
    if not os.path.exists(PRO):
        return None
    with io.open(PRO, encoding="utf-8") as f:
        d = json.load(f, object_pairs_hook=collections.OrderedDict)
    return {
        "board": {k: d.get("board", {}).get(k) for k in KEEP_KEYS
                  if k in d.get("board", {})},
        "net_settings": d.get("net_settings"),
    }


def restore_project_settings(keep):
    if not keep:
        return
    with io.open(PRO, encoding="utf-8") as f:
        d = json.load(f, object_pairs_hook=collections.OrderedDict)
    for k, v in keep["board"].items():
        d["board"][k] = v
    if keep["net_settings"] is not None:
        d["net_settings"] = keep["net_settings"]
    with io.open(PRO, "w", encoding="utf-8", newline="\n") as f:
        json.dump(d, f, indent=2)
        f.write("\n")
    n = len(keep["net_settings"]["classes"]) if keep["net_settings"] else 0
    print("restored Board Setup: %d net classes + DRC rules" % n)


def add_edge_circle(board):
    shape = pcbnew.PCB_SHAPE(board)
    shape.SetShape(pcbnew.SHAPE_T_CIRCLE)
    shape.SetCenter(board_pt(0, 0))
    shape.SetEnd(board_pt(BOARD_R, 0))
    shape.SetLayer(pcbnew.Edge_Cuts)
    shape.SetWidth(mm(0.1))
    board.Add(shape)


def add_mounting_holes(board):
    import math
    for i, ang in enumerate(MOUNT_ANGLES):
        fp = pcbnew.FootprintLoad(FPDIR + "/MountingHole.pretty",
                                  "MountingHole_2.2mm_M2")
        if fp is None:
            raise RuntimeError("mounting hole footprint not found")
        r = math.radians(ang)
        fp.SetPosition(board_pt(MOUNT_R * math.cos(r), MOUNT_R * math.sin(r)))
        fp.SetReference("H%d" % (i + 1))
        fp.SetValue("M2")
        board.Add(fp)


def main():
    comps, pinnet, netnames = read_netlist(NET_FILE)
    board = pcbnew.CreateEmptyBoard()

    # Board stackup / rules
    board.SetCopperLayerCount(2)
    settings = board.GetDesignSettings()
    settings.SetBoardThickness(mm(1.6))

    # Nets first - pads reference them by name.
    nets = {}
    for name in netnames:
        if not name:
            continue
        ni = pcbnew.NETINFO_ITEM(board, name)
        board.Add(ni)
        nets[name] = ni

    placed, missing_place, missing_fp = 0, [], []

    for ref in sorted(comps):
        info = comps[ref]
        fpid = info["fp"]
        if not fpid or ":" not in fpid:
            continue                      # power flags and the like
        lib, name = fpid.split(":", 1)
        fp = pcbnew.FootprintLoad(FPDIR + "/" + lib + ".pretty", name)
        if fp is None:
            missing_fp.append((ref, fpid))
            continue

        if ref in PLACEMENT:
            dx, dy, rot, side = PLACEMENT[ref]
        else:
            missing_place.append(ref)
            dx, dy, rot, side = 0, 34, 0, BACK   # park outside the outline

        fp.SetReference(ref)
        fp.SetValue(info["value"])
        fp.Value().SetVisible(False)
        fp.SetPosition(board_pt(dx, dy))
        if rot:
            fp.SetOrientationDegrees(float(rot))
        # The footprint must belong to the board before Flip() is called;
        # flipping an unowned footprint segfaults the pcbnew bindings.
        board.Add(fp)
        if side == BACK:
            # KiCad own flip: mirrors geometry and swaps every F.* layer.
            fp.Flip(fp.GetPosition(), pcbnew.FLIP_DIRECTION_TOP_BOTTOM)

        for pad in fp.Pads():
            key = (ref, pad.GetNumber())
            net = pinnet.get(key)
            if net and net in nets:
                pad.SetNet(nets[net])
        placed += 1

    add_edge_circle(board)
    add_mounting_holes(board)

    board.BuildListOfNets()
    keep = read_project_settings()
    pcbnew.SaveBoard(OUT, board)
    restore_project_settings(keep)

    print("wrote %s" % OUT)
    print("footprints placed: %d   nets: %d" % (placed, len(nets)))
    if missing_place:
        print("NO PLACEMENT (parked off-board): %s" % ", ".join(missing_place))
    if missing_fp:
        print("FOOTPRINT NOT FOUND: %s" % missing_fp)
    tracks = board.GetTracks()
    print("tracks: %d (must be 0 - this script places, it does not route)"
          % len(tracks))


if __name__ == "__main__":
    main()
