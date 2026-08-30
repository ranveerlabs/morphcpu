"""writes hardware/fab_output/: gerbers, drill, JLCPCB BOM and CPL.

everything a JLC quote needs, all of it out of the KiCad sources so it can be
regenerated after any board change. nothing here is hand-edited.

coordinate origin is absolute, the KiCad page origin. the board has no aux axis
origin set so the drill-file origin and the absolute origin are the same point,
which means gerbers, drill and CPL all share one coordinate system. thats the
thing JLC's uploader actually cares about.

the LCSC column comes from LCSC_BY_VALUE below, transcribed from
../../docs/BOM.md. parts BOM.md hasnt pinned to an LCSC number get an empty
LCSC field rather than a guess, and get listed on stderr at the end.

Run:
  <kicad>/bin/python.exe hardware/scripts/gen_fab.py
"""
import csv
import os
import shutil
import subprocess
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
HW = os.path.normpath(os.path.join(HERE, ".."))
ROOT = os.path.normpath(os.path.join(HW, ".."))
OUTDIR = os.path.join(HW, "fab_output")
GERBERDIR = os.path.join(OUTDIR, "gerbers")
PCB = os.path.join(HW, "morphcpu.kicad_pcb")
SCH = os.path.join(HW, "morphcpu.kicad_sch")
CLI = r"C:/Users/ranve/AppData/Local/Programs/KiCad/10.0/bin/kicad-cli.exe"

PROJECT = "morphcpu"

# Layers JLC needs. Silkscreen and mask both sides, copper both sides, outline.
# 4 layers since routing. In1/In2 are signal, missing them off here plots a
# board that quotes fine and arrives dead
GERBER_LAYERS = "F.Cu,In1.Cu,In2.Cu,B.Cu,F.Mask,B.Mask,F.SilkS,B.SilkS,Edge.Cuts"

# Value -> LCSC part number, transcribed from docs/BOM.md. Every row the
# schematic produces is pinned; if this map ever goes stale the run reports the
# gap on stderr rather than shipping a blank field.
LCSC_BY_VALUE = {
    # Actives
    "ICE40UP5K-SG48I": "C2678152",
    "FT231XS-R": "C132160",
    "W25Q32JVSSIQ": "C179173",
    "TYPE-C-31-M-12": "C165948",
    "1532H4-16000JWPDTSNL": "C5383161",
    "AP2112K-3.3TRG1": "C51118",
    "ME6211C12M5G-N": "C236672",
    "KT-0603R": "C2286",
    "USBLC6-2SC6": "C7519",
    # Passives and electromechanical
    "TS-1187A-B-A-B": "C318884",
    "100n": "C1525",
    "1u": "C52923",
    "4u7": "C23733",
    "10u": "C15525",
    "100": "C25076",
    "270": "C163474",
    "1k": "C11702",
    "5k1": "C25905",
    "10k": "C25744",
    "100k": "C25741",
    "1M": "C26083",
    "500mA": "C883122",
    "600R@100M": "C136491",
}


def run(*args):
    print("+ " + " ".join(args[1:]), file=sys.stderr)
    r = subprocess.run(args, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit("FAILED: %s\n%s%s" % (" ".join(args), r.stdout, r.stderr))
    return r.stdout


# Gerbers + drill
def export_gerbers():
    os.makedirs(GERBERDIR, exist_ok=True)
    run(CLI, "pcb", "export", "gerbers",
        "--output", GERBERDIR + os.sep,
        "--layers", GERBER_LAYERS,
        "--no-x2",              # JLC reads plain RS-274X most reliably
        "--subtract-soldermask",
        PCB)
    run(CLI, "pcb", "export", "drill",
        "--output", GERBERDIR + os.sep,
        "--format", "excellon",
        "--drill-origin", "absolute",
        "--excellon-units", "mm",
        "--excellon-zeros-format", "decimal",
        "--excellon-separate-th",   # separate PTH / NPTH files
        "--generate-map",
        PCB)


def zip_gerbers():
    zpath = os.path.join(OUTDIR, "%s-gerbers.zip" % PROJECT)
    names = sorted(n for n in os.listdir(GERBERDIR)
                   if not n.lower().endswith(".pdf"))
    with zipfile.ZipFile(zpath, "w", zipfile.ZIP_DEFLATED) as z:
        for n in names:
            z.write(os.path.join(GERBERDIR, n), n)
    return zpath, names


# BOM
def export_bom():
    raw = os.path.join(OUTDIR, "_raw_bom.csv")
    run(CLI, "sch", "export", "bom",
        "--output", raw,
        "--fields", "Reference,Value,Footprint,${QUANTITY}",
        "--labels", "Designator,Comment,Footprint,Qty",
        "--group-by", "Value,Footprint",
        "--ref-range-delimiter", "",   # JLC wants every refdes listed
        "--exclude-dnp",
        SCH)

    out = os.path.join(OUTDIR, "%s-bom.csv" % PROJECT)
    missing = []
    with open(raw, newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    with open(out, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["Designator", "Comment", "Footprint", "LCSC Part #"])
        for r in rows:
            value = r["Comment"]
            lcsc = LCSC_BY_VALUE.get(value, "")
            if not lcsc:
                missing.append((r["Designator"], value, r["Qty"]))
            w.writerow([r["Designator"], value, r["Footprint"], lcsc])
    os.remove(raw)
    return out, len(rows), missing


# CPL
def export_cpl():
    raw = os.path.join(OUTDIR, "_raw_pos.csv")
    run(CLI, "pcb", "export", "pos",
        "--output", raw,
        "--format", "csv",
        "--units", "mm",
        "--side", "both",
        "--exclude-dnp",
        PCB)

    out = os.path.join(OUTDIR, "%s-cpl.csv" % PROJECT)
    with open(raw, newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    with open(out, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["Designator", "Mid X", "Mid Y", "Layer", "Rotation"])
        for r in rows:
            w.writerow([
                r["Ref"],
                "%.4f" % float(r["PosX"]),
                "%.4f" % float(r["PosY"]),
                "Top" if r["Side"].strip().lower() == "top" else "Bottom",
                "%.4f" % (float(r["Rot"]) % 360.0),
            ])
    os.remove(raw)
    return out, len(rows), sum(1 for r in rows if r["Side"].strip().lower() == "top")


def main():
    if os.path.isdir(GERBERDIR):
        shutil.rmtree(GERBERDIR)
    os.makedirs(OUTDIR, exist_ok=True)

    export_gerbers()
    zpath, names = zip_gerbers()
    bom, nbom, missing = export_bom()
    cpl, ncpl, ntop = export_cpl()

    print("\n--- fab_output ---", file=sys.stderr)
    print("gerber+drill files: %d -> %s" % (len(names), os.path.basename(zpath)),
          file=sys.stderr)
    for n in names:
        print("    " + n, file=sys.stderr)
    print("BOM rows: %d -> %s" % (nbom, os.path.basename(bom)), file=sys.stderr)
    print("CPL rows: %d (%d top, %d bottom) -> %s"
          % (ncpl, ntop, ncpl - ntop, os.path.basename(cpl)), file=sys.stderr)

    if missing:
        print("\n!! %d BOM rows have NO LCSC part number in docs/BOM.md."
              % len(missing), file=sys.stderr)
        print("   They are emitted with an empty LCSC field, not a guess:",
              file=sys.stderr)
        for des, val, qty in missing:
            print("     %-4s x%-3s %s" % (val, qty, des), file=sys.stderr)


if __name__ == "__main__":
    main()
