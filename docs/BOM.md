# MorphCPU — bill of materials

**Quantity basis: 5 units** for everything on the PCB; **1 unit** for the case,
which is off-PCB. Every row is pinned to an LCSC part number and
priced. Rows 1–8 were checked **20 Aug 2026**; rows 9–22, added when the
schematic was reconciled against this document, were checked **23 Aug 2026**.

- **Prices and stock move.** Re-check on the day you order, especially the FPGA.
- **Price basis is the LCSC unit price at the lowest quantity break**, which is
  what a 5-board build actually pays — for most passives that break is 50 or
  100 pieces, well above the 5–85 the build needs. JLCPCB's own component
  prices differ and are not used here.
- **Quantities come from the schematic, not from this document.** Regenerate
  [../hardware/fab_output/morphcpu-bom.csv](../hardware/fab_output/morphcpu-bom.csv)
  with `gen_fab.py` and the counts below must match it.

---

## Full bill of materials

| # | Part | MPN | LCSC | Pkg | Qty/unit | Qty for 5 | Unit price | Line total |
|---|---|---|---|---|---|---|---|---|
| 1 | FPGA | ICE40UP5K-SG48I | [C2678152](https://www.lcsc.com/product-detail/C2678152.html) | QFN-48-EP (7×7) | 1 | 5 | $8.564 | **$42.82** |
| 2 | USB–UART bridge | FT231XS-R | [C132160](https://www.lcsc.com/product-detail/C132160.html) | SSOP-20-150mil | 1 | 5 | $5.9542 | **$29.77** |
| 3 | SPI config flash, 32 Mbit | W25Q32JVSSIQ | [C179173](https://www.lcsc.com/product-detail/C179173.html) | SOIC-8-208mil | 1 | 5 | $1.6846 | **$8.42** |
| 4 | USB-C receptacle, 16-pin | TYPE-C-31-M-12 | [C165948](https://www.lcsc.com/product-detail/C165948.html) | SMD right-angle | 1 | 5 | $0.1716 | **$0.86** |
| 5 | 16 MHz oscillator (XO) | 1532H4-16000JWPDTSNL | [C5383161](https://www.lcsc.com/product-detail/C5383161.html) | SMD3225-4P | 1 | 5 | $0.3609 | **$1.80** |
| 6 | 3.3 V LDO (with enable) | ME6211C33M5G-N | [C82942](https://www.lcsc.com/product-detail/C82942.html) | SOT-23-5 | 1 | 5 | $0.053 | **$0.27** |
| 7 | 1.2 V LDO (with enable) | ME6211C12M5G-N | [C236672](https://www.lcsc.com/product-detail/C236672.html) | SOT-23-5 | 1 | 5 | $0.0606 | **$0.30** |
| 8 | LED, red — 16 grid + 1 CDONE | KT-0603R | [C2286](https://www.lcsc.com/product-detail/C2286.html) | 0603 | 17 | 85 | $0.0075 | **$0.64** |
| 9 | ESD array, USB D+/D− | USBLC6-2SC6 | [C7519](https://www.lcsc.com/product-detail/C7519.html) | SOT-23-6 | 1 | 5 | $0.1858 | **$0.93** |
| 10 | Tactile switch, reset | TS-1187A-B-A-B | [C318884](https://www.lcsc.com/product-detail/C318884.html) | SMD-4P 5.1×5.1 | 1 | 5 | $0.0186 | **$0.09** |
| 11 | Cap 100 nF 16 V X7R | CL05B104KO5NNNC | [C1525](https://www.lcsc.com/product-detail/C1525.html) | 0402 | 12 | 60 | $0.0055 | **$0.33** |
| 12 | Cap 1 µF 25 V | CL05A105KA5NQNC | [C52923](https://www.lcsc.com/product-detail/C52923.html) | 0402 | 3 | 15 | $0.0122 | **$0.18** |
| 13 | Cap 4.7 µF 10 V | CL05A475MP5NRNC | [C23733](https://www.lcsc.com/product-detail/C23733.html) | 0402 | 4 | 20 | $0.0234 | **$0.47** |
| 14 | Cap 10 µF 6.3 V X5R | CL05A106MQ5NUNC | [C15525](https://www.lcsc.com/product-detail/C15525.html) | 0402 | 2 | 10 | $0.0258 | **$0.26** |
| 15 | Res 100 Ω 1% | 0402WGF1000TCE | [C25076](https://www.lcsc.com/product-detail/C25076.html) | 0402 | 1 | 5 | $0.0079 | **$0.04** |
| 16 | Res 270 Ω 1% — LED series | RC0402FR-07270RL | [C163474](https://www.lcsc.com/product-detail/C163474.html) | 0402 | 16 | 80 | $0.0041 | **$0.33** |
| 17 | Res 1 kΩ 1% — CDONE LED | 0402WGF1001TCE | [C11702](https://www.lcsc.com/product-detail/C11702.html) | 0402 | 1 | 5 | $0.0067 | **$0.03** |
| 18 | Res 5.1 kΩ 1% — CC pull-down | 0402WGF5101TCE | [C25905](https://www.lcsc.com/product-detail/C25905.html) | 0402 | 2 | 10 | $0.0044 | **$0.04** |
| 19 | Res 10 kΩ 1% | 0402WGF1002TCE | [C25744](https://www.lcsc.com/product-detail/C25744.html) | 0402 | 9 | 45 | $0.0019 | **$0.09** |
| 20 | Res 100 kΩ 1% | 0402WGF1003TCE | [C25741](https://www.lcsc.com/product-detail/C25741.html) | 0402 | 1 | 5 | $0.0054 | **$0.03** |
| 21 | Polyfuse, 500 mA hold, 6 V | BSMD1206-050-6V | [C883122](https://www.lcsc.com/product-detail/C883122.html) | 1206 | 1 | 5 | $0.0466 | **$0.23** |
| 22 | Ferrite bead, 600 Ω @ 100 MHz | MMZ1608Y601BTA00 | [C136491](https://www.lcsc.com/product-detail/Ferrite-Beads_TDK_C136491.html) | 0603 | 2 | 10 | $0.0126 | **$0.13** |
| | | | | | **80** | **400** | **Component total** | **$88.06** |

**$17.61 of components per board.** Rounding each line to the cent and summing
gives the same $88.06 as summing the unrounded lines, so the figure is not a
rounding artefact.

### Grand total

| Item | Basis | Cost |
|---|---|---|
| Components, rows 1–22 | 5 units | $88.06 |
| Case filament | 1 unit (off-PCB) | $0.26 |
| | | **$88.32** |

**$88.32** is the total for everything with a real price attached. PCB
fabrication, SMT assembly setup, Extended-part feeder fees, and shipping are
still unquoted — see [Costs that are not components](#costs-that-are-not-components)
— and for a 5-unit run they are expected to exceed this figure.

### Resistor and capacitor counts

Taken from the schematic, which is the authority:

| Value | Qty/unit | Where |
|---|---|---|
| 100 nF | 12 | 11 supply-pin decouplers + the 3V3 enable RC |
| 1 µF | 3 | LDO bulk |
| 4.7 µF | 4 | LDO bulk and FT231X |
| 10 µF | 2 | rail bulk |
| 270 Ω | 16 | LED grid series |
| 10 kΩ | 9 | CRESET_B, CDONE, SPI_SS, FT231X RESET#, XO enable, EN_3V3 bleed, reset button, and two on the flash |
| 1 kΩ | 1 | CDONE indicator series |
| 5.1 kΩ | 2 | USB-C CC1/CC2 pull-downs, never shared |
| 100 kΩ | 1 | 3V3 enable RC |
| 100 Ω | 1 | VCCPLL filter |

An earlier version of this table said 100 nF ×11, 10 kΩ ×5 and had no 1 kΩ row
at all, and counted 16 LEDs rather than 17. The schematic was right in every
case.

### Stock at time of lookup

| Part | LCSC stock | Comment |
|---|---|---|
| ICE40UP5K-SG48I | 546 | **Lowest-stock part in the design.** Order early |
| FT231XS-R | 1,657 | Fine for 5 units |
| W25Q32JVSSIQ | 39,664 | Ample |
| TYPE-C-31-M-12 | 407,730 | Ample |
| 1532H4-16000JWPDTSNL | 147 | Adequate, but thin — see the note below |
| ME6211C33M5G-N | 272,820 | Ample |
| ME6211C12M5G-N | 28,080 | Ample |
| KT-0603R | 3,752,200 | Ample |
| USBLC6-2SC6 | 35,370 | Ample |
| TS-1187A-B-A-B | 792,020 | Ample |
| MMZ1608Y601BTA00 | 11,200 | **Second-thinnest row.** Ample for 10 pieces, but not deep |
| BSMD1206-050-6V | 36,710 | Ample |
| RC0402FR-07270RL | 281,900 | Ample |
| All other 0402 passives | 330 k – 8.5 M | Ample |

---

## JLCPCB parts-library tier

Tier drives the per-part feeder fee, so it matters more than the cent-level
component price. **Basic** parts are already loaded on the machines.

| Tier | Parts |
|---|---|
| **Basic** — confirmed on JLC's parts library | C1525, C52923, C23733, C15525 (all four caps); C25076, C11702, C25905, C25744, C25741 (five of the six resistor values); C318884 (switch) |
| **Extended** — confirmed | C163474 (270 Ω), C883122 (polyfuse) |
| **Extended** — assumed, not confirmed | C2678152, C132160, C179173, C165948, C5383161 (the five actives costed as Extended from the start); C7519 (ESD); C136491 (ferrite) |

Two notes on the unconfirmed rows. JLC's part-detail pages render their tier
badge in JavaScript, so it could not be read directly; the tier above comes
from JLC's category listings, which do print it. C7519 and C136491 appear in
neither the Basic listings nor a published Basic-parts export, which is why
they are listed as Extended — that is an inference, not a quote. **Confirm both
in the PCBA quote before ordering**, because each distinct Extended part
carries its own feeder fee.

**270 Ω 0402 is the one value with no Basic option.** Every 270 Ω 0402 in JLC's
library is Extended. The alternatives were to drop to 300 Ω or 330 Ω, which are
Basic in 0402 but change LED current from 5 mA to 4.3 or 3.9 mA, or to move to
0603, which is Basic at 270 Ω but changes 16 footprints. Neither trade was
worth one feeder fee, so the design keeps 270 Ω and pays for it.

---

## Parts changed since the first costing

| Was | Now | Why |
|---|---|---|
| FT231XS-U (C89607) | **FT231XS-R (C132160)** | C89607 is out of stock, and `-U` is tube packaging. `-R` is tape-and-reel, which an assembly line wants. Identical SSOP-20-150mil footprint, no pin changes |
| AMS1117-3.3 (C6186) | **ME6211C33M5G-N (C82942)** | The power-up sequence needs the 3.3 V rail held off until 1.2 V is up. AMS1117 is SOT-223 with **no enable pin**. ME6211 has CE, is Basic tier, cheaper, and shares a footprint with the 1.2 V part |
| 12 MHz crystal + 2 load caps | **16 MHz XO (C5383161)** + 1 × 100 nF | The iCE40 has no crystal amplifier. 12 MHz active XOs at LCSC had 9 and 1 units in stock; the 16 MHz part has 147. Costs a gateware parameter change and improves UART divisor error from 0.16% to 0.08% |
| No ESD protection | **USBLC6-2SC6 (C7519)** | This document listed an ESD array from the start and the schematic never had one. Now U6, wired into the D+/D− path between J1 and U2, and placed beside the connector |
| Reset switch on the `SW_SPST_TL3342` land pattern | **TS-1187A-B-A-B (C318884)** on `SW_Push_1P1T_XKB_TS-1187A` | The part JLC stocks Basic is the XKB TS-1187A, whose pads sit at 6.0 × 3.75 mm. TL3342's are 6.3 × 3.8 mm — near enough to look right on screen, not near enough to solder. The footprint now follows the part |

### Oscillator stock note

147 units is adequate for a 5-unit build but is not deep. The two 12 MHz
alternatives were worse — [C7503622](https://www.lcsc.com/product-detail/C7503622.html)
had 9 units and [C2451123](https://www.lcsc.com/product-detail/C2451123.html)
had 1 at $5.94. If C5383161 dries up, any 3.3 V-capable HCMOS XO in SMD3225-4P
drops straight in; only `CLK_HZ` in the gateware and `--freq` in `build.sh`
follow the frequency.

### Ferrite current rating

MMZ1608Y601BTA00 is rated 500 mA with 400 mΩ DCR. FB2 feeds FT231X VCC (tens of
mA) and FB1 feeds VPP_2V5 on the FPGA (configuration only), so both sit far
inside that. A 0603 600 Ω bead rated 200 mA would also have worked; the 500 mA
part was picked for margin on FB2.

---

## Costs that are not components

For a 5-unit run these dominate, and they are easy to miss when costing against
the **Complex ($210)** tier.

| Item | Notes |
|---|---|
| PCB fabrication | 5 × round 2-layer 70 mm boards. Cheap; a round outline is a routed profile, not a premium |
| SMT assembly setup | Charged per order. **Both sides are populated** — 18 footprints on top, 62 on bottom — so this is the double-sided rate, not the single-sided one |
| **Extended-part feeder fees** | Charged **per distinct extended part**. Between 7 and 9 parts here are Extended depending on how C7519 and C136491 resolve. Fixed cost, so across 5 boards it lands hard per unit |
| Stencil | Usually included with assembly |
| Shipping + duty | Varies |
| Case | **Case material: $0.26 (12.9 g PLA @ 20% infill, $19.99/kg)** — 1 unit. See below |

### Case filament cost

**Quantity basis: 1 unit**, not 5. The Gadget Market rule is that off-PCB parts
only have to cover one assembled demo unit, and the case is off-PCB. Five
frames would be 64.5 g and $1.29 if they are ever wanted.

**Case material: $0.26 (12.9 g PLA @ 20% infill, $19.99/kg)**

How that number was reached:

| Step | Value | Source |
|---|---|---|
| Solid volume of the exported frame | **11,627.47 mm³** | [../case/morphcpu_case.stl](../case/morphcpu_case.stl), re-exported from the `.scad` and byte-identical to the committed file. Volume by signed-tetrahedron sum over all 9,586 facets |
| — floor slab (z 0–2.0 mm) | 8,707.51 mm³ | Same mesh, intersected with the floor slab |
| — wall ring (z 2.0–7.8 mm) | 2,711.66 mm³ | Same, less the post footprints |
| — four standoff posts | 208.30 mm³ | Same, intersected with the post cylinders |
| Extruded volume after infill | **10,410.40 mm³** | See the infill note below |
| Filament mass | **12.91 g** | × 1.24 g/cm³, the standard PLA density |
| Filament price | **$19.99/kg** | Median 1 kg spool across ten manufacturers' own stores, 11 Jun 2026. Overture's own store corroborates: $20.99–22.99 list, $13.99–14.99 on sale |
| **Cost** | **$0.2580 → $0.26** | |

**The 20% infill assumption barely applies to this part, and saying so matters
more than the number.** At the print settings in
[../case/README.md](../case/README.md) — 0.4 mm nozzle, 0.2 mm layers, 3
perimeters — three perimeters are 1.2 mm per side, so every feature thinner
than 2.4 mm prints as solid perimeter with no infill region at all:

- **Wall, 2.4 mm** — exactly two perimeter stacks. 100% solid.
- **Standoff posts, 5.0 mm OD with a 1.7 mm pilot hole** — the outer and pilot
  perimeter shells overlap. 100% solid.
- **Floor, 2.0 mm** — 4 top + 4 bottom solid layers are 1.6 mm of the 2.0 mm,
  leaving 0.4 mm at 20%, so the floor is 84% dense. The 1,100.81 mm³ annulus of
  floor directly under the wall is solid too.

Printed 100% solid the frame is 14.42 g and **$0.29** — three cents more. Any
infill setting between 0% and 100% lands in that three-cent band, so the case
cost is insensitive to the assumption. The earlier "~15 g, negligible" estimate
in this document was close and its conclusion was right.

Not included: skirt, purge line, and failed prints. A common rule of thumb adds
about 25% for those, which would take the line to $0.32.

Component cost is **$17.61 per board**, but fixed per-order fees across a
5-unit run can rival the whole BOM. Moving the two regulators to Basic-tier
parts helped, and pinning the passives to Basic parts kept nine values off the
feeder-fee list. The remaining Extended parts are the fixed cost. Building 10
instead of 5 barely changes those fees and roughly halves their per-unit share.

**No fabrication or assembly quote is included above.** Neither has a real
number yet: JLCPCB's calculator prices nothing until Gerbers, BOM and CPL are
uploaded. Those files now exist in
[../hardware/fab_output/](../hardware/fab_output/) and are ready to upload.

---

## Sources

- [ICE40UP5K-SG48I — LCSC C2678152](https://www.lcsc.com/product-detail/C2678152.html)
- [FT231XS-R — LCSC C132160](https://www.lcsc.com/product-detail/C132160.html)
- [FT231XS-U — LCSC C89607](https://www.lcsc.com/product-detail/C89607.html) (out of stock — do not use)
- [W25Q32JVSSIQ — LCSC C179173](https://www.lcsc.com/product-detail/C179173.html)
- [TYPE-C-31-M-12 — LCSC C165948](https://www.lcsc.com/product-detail/C165948.html)
- [1532H4-16000JWPDTSNL — LCSC C5383161](https://www.lcsc.com/product-detail/C5383161.html)
- [ME6211C33M5G-N — LCSC C82942](https://www.lcsc.com/product-detail/C82942.html)
- [ME6211C12M5G-N — LCSC C236672](https://www.lcsc.com/product-detail/C236672.html)
- [KT-0603R — LCSC C2286](https://www.lcsc.com/product-detail/C2286.html)
- [USBLC6-2SC6 — LCSC C7519](https://www.lcsc.com/product-detail/C7519.html)
- [TS-1187A-B-A-B — LCSC C318884](https://www.lcsc.com/product-detail/C318884.html)
- [CL05B104KO5NNNC — LCSC C1525](https://www.lcsc.com/product-detail/C1525.html)
- [CL05A105KA5NQNC — LCSC C52923](https://www.lcsc.com/product-detail/C52923.html)
- [CL05A475MP5NRNC — LCSC C23733](https://www.lcsc.com/product-detail/C23733.html)
- [CL05A106MQ5NUNC — LCSC C15525](https://www.lcsc.com/product-detail/C15525.html)
- [0402WGF1000TCE — LCSC C25076](https://www.lcsc.com/product-detail/C25076.html)
- [RC0402FR-07270RL — LCSC C163474](https://www.lcsc.com/product-detail/C163474.html)
- [0402WGF1001TCE — LCSC C11702](https://www.lcsc.com/product-detail/C11702.html)
- [0402WGF5101TCE — LCSC C25905](https://www.lcsc.com/product-detail/C25905.html)
- [0402WGF1002TCE — LCSC C25744](https://www.lcsc.com/product-detail/C25744.html)
- [0402WGF1003TCE — LCSC C25741](https://www.lcsc.com/product-detail/C25741.html)
- [BSMD1206-050-6V — LCSC C883122](https://www.lcsc.com/product-detail/C883122.html)
- [MMZ1608Y601BTA00 — LCSC C136491](https://www.lcsc.com/product-detail/Ferrite-Beads_TDK_C136491.html)
- [PLA filament price per gram and per kg, 11 Jun 2026 — 3DPCC](https://3dprintingcostcalculator.com/news/filament-price-per-gram)
- [Overture PLA filament store listing](https://www.overture3d.com/collections/pla-filament)
- [JLCPCB parts library — tier and category listings](https://jlcpcb.com/parts)
- [JLCPCB PCBA price breakdown](https://jlcpcb.com/help/article/pcb-assembly-price)
- [iCE40 UltraPlus Family Data Sheet FPGA-DS-02008](https://www.latticesemi.com/-/media/LatticeSemi/Documents/DataSheets/iCE/iCE40-UltraPlus-Family-Data-Sheet.ashx)
