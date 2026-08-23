"""Generate hardware/morphcpu.kicad_sch from netlist.py.

Connectivity is expressed with global labels rather than drawn wires. A global
label joins nets by NAME, not by position, so every pin carrying the same net
name is connected no matter where its symbol sits on the sheet. That removes
the whole class of "wire looks connected but is 0.01 mm short" faults that make
hand-generated schematics untrustworthy, and it is a legitimate schematic style
for a dense board.

Run:  <kicad>/bin/python.exe hardware/scripts/gen_schematic.py
"""
import os
import sys
import uuid

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ksym
import netlist

KICAD = r"C:/Users/ranve/AppData/Local/Programs/KiCad/10.0/share/kicad/symbols/"
NS = uuid.UUID("6f1b2c3d-4e5f-4a6b-8c9d-0e1f2a3b4c5d")
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..",
                   "morphcpu.kicad_sch")
PROJECT = "morphcpu"

Q = chr(34)


def uid(*parts):
    return str(uuid.uuid5(NS, "|".join(str(p) for p in parts)))


def q(s):
    return Q + str(s) + Q


# ---------------------------------------------------------------------------
# Sheet layout. Positions are readability only - connectivity is by net name.
# ---------------------------------------------------------------------------
PLACE = {
    ("U1", 1): (70, 55),
    ("U1", 2): (70, 150),
    ("U1", 3): (70, 245),
    ("U1", 4): (185, 250),
    "U2": (285, 60),
    "U3": (285, 175),
    "U4": (185, 60),
    "U5": (185, 120),
    "X1": (185, 175),
    "J1": (400, 60),
    "SW1": (400, 175),
}

LED_ORIGIN = (470, 45)
LED_DX, LED_DY = 30, 40
MISC_ORIGIN = (60, 330)
MISC_DX, MISC_DY = 26, 26
MISC_COLS = 18


GRID = 1.27


def snap(v):
    """Round to the 1.27 mm connection grid.

    Symbol pin offsets are multiples of 1.27, so origins on that grid put
    every pin on it too. Off-grid pins are an ERC warning and, worse, make
    the sheet painful to edit by hand afterwards.
    """
    return round(v / GRID) * GRID


def resolve_positions():
    pos = {}
    misc = []
    for idx, comp in enumerate(netlist.components):
        key = (comp["ref"], comp["unit"]) if comp["ref"] == "U1" else comp["ref"]
        if key in PLACE:
            pos[idx] = PLACE[key]
        elif comp["ref"].startswith(("R", "D")) and comp["ref"][1:].isdigit() \
                and int(comp["ref"][1:]) <= 16:
            n = int(comp["ref"][1:]) - 1
            col, row = n % 4, n // 4
            x = LED_ORIGIN[0] + col * LED_DX
            y = LED_ORIGIN[1] + row * LED_DY
            pos[idx] = (x, y if comp["ref"][0] == "R" else y + 15)
        else:
            misc.append(idx)
    for k, idx in enumerate(misc):
        col, row = k % MISC_COLS, k // MISC_COLS
        pos[idx] = (MISC_ORIGIN[0] + col * MISC_DX,
                    MISC_ORIGIN[1] + row * MISC_DY)
    return {k: (snap(x), snap(y)) for k, (x, y) in pos.items()}


# ---------------------------------------------------------------------------
# Library symbols
# ---------------------------------------------------------------------------
def lib_path(lib):
    return KICAD + lib + ".kicad_sym"


def base_of(lib, sym):
    """Follow (extends "Parent") so derived symbols inherit their pins.

    Some KiCad symbols (the ME6211 voltage variants, for one) carry no
    geometry and only extend a sibling. Graphic and pinout are identical;
    only the default Value differs, and the instance overrides that.
    """
    s = ksym.load_lib(lib_path(lib))[sym]
    ext = ksym.find_one(s, "extends")
    if ext:
        return ksym.unquote(ext[1])
    return sym


def lib_symbol_node(lib, sym):
    """Build the lib_symbols entry for one symbol.

    A derived symbol has to be embedded FLATTENED: the parent's graphics
    and pins, its own property overrides, and nested sub-symbols renamed
    to the child. Emitting the parent body under the child name loads but
    then trips ERC lib_symbol_mismatch, because the properties still say
    the parent.
    """
    lb = ksym.load_lib(lib_path(lib))
    s = lb[sym]
    ext = ksym.find_one(s, "extends")
    if not ext:
        node = list(s)
        node[1] = q(lib + ":" + sym)
        return node
    parent = ksym.unquote(ext[1])
    base = lb[parent]
    child_props = {}
    for pr in ksym.find_all(s, "property"):
        child_props[ksym.unquote(pr[1])] = pr
    node = ["symbol", q(lib + ":" + sym)]
    for c in base[2:]:
        if isinstance(c, list) and c[0] == "property":
            name = ksym.unquote(c[1])
            node.append(child_props.pop(name, c))
        elif isinstance(c, list) and c[0] == "symbol":
            sub = list(c)
            subname = ksym.unquote(c[1])
            sub[1] = q(sym + subname[len(parent):])
            node.append(sub)
        else:
            node.append(c)
    for leftover in child_props.values():
        node.append(leftover)
    return node


def build_lib_symbols(used):
    out = []
    for lib, sym in sorted(used):
        out.append(ksym.dump(lib_symbol_node(lib, sym), 2))
    return chr(10).join(out)


def pin_index(lib, sym):
    cache_key = (lib, sym)
    if cache_key not in pin_index.cache:
        s = ksym.load_lib(lib_path(lib))[base_of(lib, sym)]
        pins = {}
        for p in ksym.pins_of(s):
            pins[(p["unit"], p["number"])] = p
        pin_index.cache[cache_key] = pins
    return pin_index.cache[cache_key]


pin_index.cache = {}


EFFECTS = ("(effects (font (size 1.27 1.27)))")


def emit_symbol(comp, x, y, root_uuid):
    ref = comp["ref"]
    unit = comp["unit"]
    su = uid("sym", ref, unit)
    hide_ref = " (hide yes)" if ref.startswith("#") else ""
    lines = []
    a = lines.append
    a("\t(symbol")
    a("\t\t(lib_id %s)" % q(comp["lib"] + ":" + comp["sym"]))
    a("\t\t(at %g %g 0)" % (x, y))
    a("\t\t(unit %d)" % unit)
    a("\t\t(exclude_from_sim no)")
    a("\t\t(in_bom %s)" % ("no" if ref.startswith("#") else "yes"))
    a("\t\t(on_board %s)" % ("no" if ref.startswith("#") else "yes"))
    a("\t\t(dnp no)")
    a("\t\t(uuid %s)" % q(su))
    a("\t\t(property \"Reference\" %s (at %g %g 0)%s %s)"
      % (q(ref), x, y - 12, hide_ref, EFFECTS))
    a("\t\t(property \"Value\" %s (at %g %g 0) %s)"
      % (q(comp["value"]), x, y + 12, EFFECTS))
    if comp["fp"]:
        a("\t\t(property \"Footprint\" %s (at %g %g 0) (hide yes) %s)"
          % (q(comp["fp"]), x, y, EFFECTS))
    a("\t\t(instances")
    a("\t\t\t(project %s" % q(PROJECT))
    a("\t\t\t\t(path %s" % q("/" + root_uuid))
    a("\t\t\t\t\t(reference %s)" % q(ref))
    a("\t\t\t\t\t(unit %d)" % unit)
    a("\t\t\t\t)")
    a("\t\t\t)")
    a("\t\t)")
    a("\t)")
    return "\n".join(lines)


def emit_label(net, x, y, angle, key):
    return "\n".join([
        "\t(global_label %s" % q(net),
        "\t\t(shape bidirectional)",
        "\t\t(at %g %g %g)" % (x, y, angle),
        "\t\t(effects (font (size 1.27 1.27)) (justify %s))"
        % ("right" if angle == 180 else "left"),
        "\t\t(uuid %s)" % q(uid("lbl", key)),
        "\t)",
    ])


def emit_nc(x, y, key):
    return "\t(no_connect (at %g %g) (uuid %s))" % (x, y, q(uid("nc", key)))


def main():
    root_uuid = uid("root")
    pos = resolve_positions()
    used = {(c["lib"], c["sym"]) for c in netlist.components}

    body = []
    labels = []
    ncs = []
    stats = {"pins": 0, "labels": 0, "nc": 0}

    for idx, comp in enumerate(netlist.components):
        x, y = pos[idx]
        body.append(emit_symbol(comp, x, y, root_uuid))
        pins = pin_index(comp["lib"], comp["sym"])

        for num, net in comp["nets"].items():
            p = pins.get((comp["unit"], str(num))) or pins.get((0, str(num)))
            if p is None:
                raise KeyError("no pin %s unit %s on %s:%s"
                               % (num, comp["unit"], comp["lib"], comp["sym"]))
            px, py = x + p["x"], y - p["y"]
            ang = (p["angle"] + 180) % 360
            labels.append(emit_label(net, px, py, ang,
                                     (comp["ref"], comp["unit"], num)))
            stats["labels"] += 1

        for num in comp["nc"]:
            p = pins.get((comp["unit"], str(num))) or pins.get((0, str(num)))
            if p is None:
                raise KeyError("no nc pin %s on %s" % (num, comp["ref"]))
            ncs.append(emit_nc(x + p["x"], y - p["y"],
                               (comp["ref"], comp["unit"], num)))
            stats["nc"] += 1
        stats["pins"] += len(comp["nets"]) + len(comp["nc"])

    out = []
    out.append("(kicad_sch")
    out.append("\t(version 20250610)")
    out.append("\t(generator \"morphcpu-gen\")")
    out.append("\t(generator_version \"9.99\")")
    out.append("\t(uuid %s)" % q(root_uuid))
    out.append("\t(paper \"A2\")")
    out.append("\t(title_block")
    out.append("\t\t(title \"MorphCPU\")")
    out.append("\t\t(rev \"A\")")
    out.append("\t\t(comment 1 \"Generated from hardware/scripts/netlist.py\")")
    out.append("\t\t(comment 2 \"Connectivity is by global label name\")")
    out.append("\t)")
    out.append("\t(lib_symbols")
    out.append(build_lib_symbols(used))
    out.append("\t)")
    out.extend(body)
    out.extend(labels)
    out.extend(ncs)
    out.append("\t(sheet_instances")
    out.append("\t\t(path \"/\" (page \"1\"))")
    out.append("\t)")
    out.append(")")

    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")

    print("wrote %s" % os.path.normpath(OUT))
    print("components %d  pins wired %d  labels %d  no-connects %d"
          % (len(netlist.components), stats["pins"], stats["labels"],
             stats["nc"]))


if __name__ == "__main__":
    main()
