# BOM

5 units of everything on the board, 1 unit for the case (it's off-PCB). every row
is pinned to an LCSC part number and priced. rows 1-8 checked 20 aug 2026, rows
9-22 checked 23 aug 2026 when the schematic got reconciled against this file.

- prices and stock move. re-check the day you order, especially the FPGA.
- price basis is LCSC unit price at the lowest qty break, which is what a 5-board
  build actually pays. for most passives that break is 50 or 100 pcs, way above
  the 5-85 we need. JLCPCB's own component prices differ and aren't used here.
- quantities come from the schematic, not from this file. regen
  [../hardware/fab_output/morphcpu-bom.csv](../hardware/fab_output/morphcpu-bom.csv)
  with `gen_fab.py` and the counts below have to match it.

## the parts

| # | Part | MPN | LCSC | Pkg | Qty/unit | Qty for 5 | Unit price | Line total |
|---|---|---|---|---|---|---|---|---|
| 1 | FPGA | ICE40UP5K-SG48I | [C2678152](https://www.lcsc.com/product-detail/C2678152.html) | QFN-48-EP (7×7) | 1 | 5 | $8.564 | **$42.82** |
| 2 | USB-UART bridge | FT231XS-R | [C132160](https://www.lcsc.com/product-detail/C132160.html) | SSOP-20-150mil | 1 | 5 | $5.9542 | **$29.77** |
| 3 | SPI config flash, 32 Mbit | W25Q32JVSSIQ | [C179173](https://www.lcsc.com/product-detail/C179173.html) | SOIC-8-208mil | 1 | 5 | $1.6846 | **$8.42** |
| 4 | USB-C receptacle, 16-pin | TYPE-C-31-M-12 | [C165948](https://www.lcsc.com/product-detail/C165948.html) | SMD right-angle | 1 | 5 | $0.1716 | **$0.86** |
| 5 | 16 MHz oscillator (XO) | 1532H4-16000JWPDTSNL | [C5383161](https://www.lcsc.com/product-detail/C5383161.html) | SMD3225-4P | 1 | 5 | $0.3609 | **$1.80** |
| 6 | 3.3 V LDO (with enable) | ME6211C33M5G-N | [C82942](https://www.lcsc.com/product-detail/C82942.html) | SOT-23-5 | 1 | 5 | $0.053 | **$0.27** |
| 7 | 1.2 V LDO (with enable) | ME6211C12M5G-N | [C236672](https://www.lcsc.com/product-detail/C236672.html) | SOT-23-5 | 1 | 5 | $0.0606 | **$0.30** |
| 8 | LED, red, 16 grid + 1 CDONE | KT-0603R | [C2286](https://www.lcsc.com/product-detail/C2286.html) | 0603 | 17 | 85 | $0.0075 | **$0.64** |
| 9 | ESD array, USB D+/D- | USBLC6-2SC6 | [C7519](https://www.lcsc.com/product-detail/C7519.html) | SOT-23-6 | 1 | 5 | $0.1858 | **$0.93** |
| 10 | Tactile switch, reset | TS-1187A-B-A-B | [C318884](https://www.lcsc.com/product-detail/C318884.html) | SMD-4P 5.1×5.1 | 1 | 5 | $0.0186 | **$0.09** |
| 11 | Cap 100 nF 16 V X7R | CL05B104KO5NNNC | [C1525](https://www.lcsc.com/product-detail/C1525.html) | 0402 | 12 | 60 | $0.0055 | **$0.33** |
| 12 | Cap 1 µF 25 V | CL05A105KA5NQNC | [C52923](https://www.lcsc.com/product-detail/C52923.html) | 0402 | 3 | 15 | $0.0122 | **$0.18** |
| 13 | Cap 4.7 µF 10 V | CL05A475MP5NRNC | [C23733](https://www.lcsc.com/product-detail/C23733.html) | 0402 | 4 | 20 | $0.0234 | **$0.47** |
| 14 | Cap 10 µF 6.3 V X5R | CL05A106MQ5NUNC | [C15525](https://www.lcsc.com/product-detail/C15525.html) | 0402 | 2 | 10 | $0.0258 | **$0.26** |
| 15 | Res 100 Ω 1% | 0402WGF1000TCE | [C25076](https://www.lcsc.com/product-detail/C25076.html) | 0402 | 1 | 5 | $0.0079 | **$0.04** |
| 16 | Res 270 Ω 1%, LED series | RC0402FR-07270RL | [C163474](https://www.lcsc.com/product-detail/C163474.html) | 0402 | 16 | 80 | $0.0041 | **$0.33** |
| 17 | Res 1 kΩ 1%, CDONE LED | 0402WGF1001TCE | [C11702](https://www.lcsc.com/product-detail/C11702.html) | 0402 | 1 | 5 | $0.0067 | **$0.03** |
| 18 | Res 5.1 kΩ 1%, CC pull-down | 0402WGF5101TCE | [C25905](https://www.lcsc.com/product-detail/C25905.html) | 0402 | 2 | 10 | $0.0044 | **$0.04** |
| 19 | Res 10 kΩ 1% | 0402WGF1002TCE | [C25744](https://www.lcsc.com/product-detail/C25744.html) | 0402 | 9 | 45 | $0.0019 | **$0.09** |
| 20 | Res 100 kΩ 1% | 0402WGF1003TCE | [C25741](https://www.lcsc.com/product-detail/C25741.html) | 0402 | 1 | 5 | $0.0054 | **$0.03** |
| 21 | Polyfuse, 500 mA hold, 6 V | BSMD1206-050-6V | [C883122](https://www.lcsc.com/product-detail/C883122.html) | 1206 | 1 | 5 | $0.0466 | **$0.23** |
| 22 | Ferrite bead, 600 Ω @ 100 MHz | MMZ1608Y601BTA00 | [C136491](https://www.lcsc.com/product-detail/Ferrite-Beads_TDK_C136491.html) | 0603 | 2 | 10 | $0.0126 | **$0.13** |
| | | | | | **80** | **400** | **parts subtotal** | **$88.06** |

$17.61 of parts per board. rounding each line to the cent and summing gives the
same $88.06 as summing unrounded, so it's not a rounding artefact.

## what it actually costs

careful here. the $88.06 above is **not** a separate line item. it's already
inside the JLC PCBA quote, which bundles fab + parts + assembly into one number.
adding both would double-count the parts.

| Item | Basis | Cost |
|---|---|---|
| parts subtotal, rows 1-22 (informational, already inside the JLC quote) | 5 units | *$88.06* |
| JLCPCB PCBA order: fab + parts + assembly | 5 units | $198.15 |
| case filament | 1 unit, off-PCB | $0.26 |
| | | **$198.41** |

so **$198.41** all-in, $39.63/unit across 5 boards. that's under the Complex
($210) tier with $11.59 of headroom, which is not much, so don't add parts
casually.

the $110.09 gap between the parts subtotal and the JLC quote is fab + assembly
setup + extended-part feeder fees. JLC quotes it bundled and doesn't split it out
line by line, so treat that gap as one number.

still not in the $198.41: shipping and duty. those only get quoted at checkout
with a real address, so they aren't here yet, and they eat into the $11.59.

### R and C counts

from the schematic, which is the authority:

| Value | Qty/unit | Where |
|---|---|---|
| 100 nF | 12 | 11 supply-pin decouplers + the 3V3 enable RC |
| 1 µF | 3 | LDO bulk |
| 4.7 µF | 4 | LDO bulk and FT231X |
| 10 µF | 2 | rail bulk |
| 270 Ω | 16 | LED grid series |
| 10 kΩ | 9 | CRESET_B, CDONE, SPI_SS, FT231X RESET#, XO enable, EN_3V3 bleed, reset button, two on the flash |
| 1 kΩ | 1 | CDONE indicator series |
| 5.1 kΩ | 2 | USB-C CC1/CC2 pull-downs, never shared |
| 100 kΩ | 1 | 3V3 enable RC |
| 100 Ω | 1 | VCCPLL filter |

an older version of this table said 100 nF ×11, 10 kΩ ×5, no 1 kΩ row at all,
and 16 LEDs instead of 17. schematic was right every time.

### stock at lookup time

| Part | LCSC stock | Comment |
|---|---|---|
| ICE40UP5K-SG48I | 546 | **lowest-stock part in the design.** order early |
| FT231XS-R | 1,657 | fine for 5 |
| W25Q32JVSSIQ | 39,664 | ample |
| TYPE-C-31-M-12 | 407,730 | ample |
| 1532H4-16000JWPDTSNL | 147 | ok but thin, see note below |
| ME6211C33M5G-N | 272,820 | ample |
| ME6211C12M5G-N | 28,080 | ample |
| KT-0603R | 3,752,200 | ample |
| USBLC6-2SC6 | 35,370 | ample |
| TS-1187A-B-A-B | 792,020 | ample |
| MMZ1608Y601BTA00 | 11,200 | **second thinnest.** fine for 10 pcs, not deep |
| BSMD1206-050-6V | 36,710 | ample |
| RC0402FR-07270RL | 281,900 | ample |
| all other 0402 passives | 330 k to 8.5 M | ample |

## JLC parts tier

tier drives the per-part feeder fee, so it matters way more than cent-level part
price. Basic parts are already loaded on the machines.

| Tier | Parts |
|---|---|
| **Basic**, confirmed | C1525, C52923, C23733, C15525 (all four caps); C25076, C11702, C25905, C25744, C25741 (five of six resistor values); C318884 (switch) |
| **Extended**, confirmed | C163474 (270 Ω), C883122 (polyfuse) |
| **Extended**, assumed, not confirmed | C2678152, C132160, C179173, C165948, C5383161 (the five actives, costed as Extended from the start); C7519 (ESD); C136491 (ferrite) |

two notes on the unconfirmed rows. JLC's part-detail pages render the tier badge
in JS so it can't be read directly, the tiers above come from JLC's category
listings, which do print it. C7519 and C136491 show up in neither the Basic
listings nor a published Basic-parts export, hence Extended, but that's an
inference, not a quote. **confirm both in the PCBA quote before ordering**, each
distinct Extended part carries its own feeder fee.

**270 Ω 0402 is the one value with no Basic option.** every 270 Ω 0402 in JLC's
library is Extended. options were dropping to 300 Ω or 330 Ω (Basic in 0402, but
LED current goes 5 mA to 4.3 or 3.9 mA), or moving to 0603 (Basic at 270 Ω, but
16 footprints change). neither trade is worth one feeder fee, so we keep 270 Ω
and pay for it.

## parts that changed since the first costing

| Was | Now | Why |
|---|---|---|
| FT231XS-U (C89607) | **FT231XS-R (C132160)** | C89607 is out of stock and `-U` is tube packaging. `-R` is tape-and-reel, which an assembly line wants. same SSOP-20-150mil footprint, no pin changes |
| AMS1117-3.3 (C6186) | **ME6211C33M5G-N (C82942)** | power-up sequence needs 3.3 V held off until 1.2 V is up. AMS1117 is SOT-223 with **no enable pin**. ME6211 has CE, is Basic tier, cheaper, and shares a footprint with the 1.2 V part |
| 12 MHz crystal + 2 load caps | **16 MHz XO (C5383161)** + 1 × 100 nF | iCE40 has no crystal amp. 12 MHz active XOs at LCSC had 9 and 1 in stock, the 16 MHz part has 147. costs a gateware param change, and UART divisor error improves from 0.16% to 0.08% |
| no ESD protection | **USBLC6-2SC6 (C7519)** | this doc listed an ESD array from day one and the schematic never had one. now U6, in the D+/D- path between J1 and U2, placed next to the connector |
| reset switch on `SW_SPST_TL3342` | **TS-1187A-B-A-B (C318884)** on `SW_Push_1P1T_XKB_TS-1187A` | the part JLC stocks Basic is the XKB TS-1187A, pads at 6.0 × 3.75 mm. TL3342's are 6.3 × 3.8 mm. close enough to look fine on screen, not close enough to solder. footprint follows the part now |

### osc stock note

147 is fine for 5 units but not deep. both 12 MHz alternatives were worse,
[C7503622](https://www.lcsc.com/product-detail/C7503622.html) had 9 units and
[C2451123](https://www.lcsc.com/product-detail/C2451123.html) had 1 at $5.94. if
C5383161 dries up, any 3.3 V HCMOS XO in SMD3225-4P drops straight in, only
`CLK_HZ` in the gateware and `--freq` in `build.sh` follow the frequency.

### ferrite current rating

MMZ1608Y601BTA00 is 500 mA with 400 mΩ DCR. FB2 feeds FT231X VCC (tens of mA),
FB1 feeds VPP_2V5 on the FPGA (config only), both sit way inside that. a 0603
600 Ω bead rated 200 mA would've worked too, 500 mA was picked for margin on FB2.

## the case filament number

**1 unit, not 5.** the Gadget Market rule is that off-PCB parts only have to
cover one assembled demo unit, and the case is off-PCB. five frames would be
64.5 g and $1.29 if anyone ever wants them.

**$0.26 (12.9 g PLA @ 20% infill, $19.99/kg)**

how we got there:

| Step | Value | Source |
|---|---|---|
| solid volume of the exported frame | **11,627.47 mm³** | [../case/morphcpu_case.stl](../case/morphcpu_case.stl), re-exported from the `.scad` and byte-identical to the committed file. volume by signed-tetrahedron sum over all 9,586 facets |
| floor slab (z 0-2.0 mm) | 8,707.51 mm³ | same mesh, intersected with the floor slab |
| wall ring (z 2.0-7.8 mm) | 2,711.66 mm³ | same, less the post footprints |
| four standoff posts | 208.30 mm³ | same, intersected with the post cylinders |
| extruded volume after infill | **10,410.40 mm³** | see the infill note |
| filament mass | **12.91 g** | × 1.24 g/cm³, standard PLA density |
| filament price | **$19.99/kg** | median 1 kg spool across ten manufacturers' own stores, 11 jun 2026. Overture's own store agrees: $20.99-22.99 list, $13.99-14.99 on sale |
| **cost** | **$0.2580, so $0.26** | |

**the 20% infill assumption barely applies to this part, and saying so matters
more than the number.** at the print settings in
[../case/README.md](../case/README.md), 0.4 mm nozzle, 0.2 mm layers, 3
perimeters, three perimeters are 1.2 mm per side, so anything thinner than
2.4 mm prints as solid perimeter with no infill region at all:

- wall, 2.4 mm: exactly two perimeter stacks. 100% solid.
- standoff posts, 5.0 mm OD with a 1.7 mm pilot hole: outer and pilot shells overlap. 100% solid.
- floor, 2.0 mm: 4 top + 4 bottom solid layers are 1.6 mm of the 2.0, leaving 0.4 mm at 20%, so the floor is 84% dense. the 1,100.81 mm³ annulus right under the wall is solid too.

printed 100% solid the frame is 14.42 g and $0.29, three cents more. any infill
between 0% and 100% lands in that band, so the case cost doesn't care about the
assumption. the old "~15 g, negligible" estimate was close and its conclusion
held.

not counted: skirt, purge line, failed prints. usual rule of thumb adds about
25%, which would push this line to $0.32.

## why the fixed fees hurt

parts are $17.61/board but the fixed per-order fees are $110.09 across the whole
run, so they cost more than the entire BOM. moving both regulators to Basic
helped, and pinning the passives to Basic kept nine values off the feeder-fee
list. what's left Extended is the fixed cost. building 10 instead of 5 barely
moves those fees and roughly halves their per-unit share, worth considering if
the budget allows.

gerbers, BOM and CPL live in
[../hardware/fab_output/](../hardware/fab_output/) and are what the $198.15 quote
was generated from. re-quote if any of them change.

## sources

- [ICE40UP5K-SG48I, LCSC C2678152](https://www.lcsc.com/product-detail/C2678152.html)
- [FT231XS-R, LCSC C132160](https://www.lcsc.com/product-detail/C132160.html)
- [FT231XS-U, LCSC C89607](https://www.lcsc.com/product-detail/C89607.html) (out of stock, don't use)
- [W25Q32JVSSIQ, LCSC C179173](https://www.lcsc.com/product-detail/C179173.html)
- [TYPE-C-31-M-12, LCSC C165948](https://www.lcsc.com/product-detail/C165948.html)
- [1532H4-16000JWPDTSNL, LCSC C5383161](https://www.lcsc.com/product-detail/C5383161.html)
- [ME6211C33M5G-N, LCSC C82942](https://www.lcsc.com/product-detail/C82942.html)
- [ME6211C12M5G-N, LCSC C236672](https://www.lcsc.com/product-detail/C236672.html)
- [KT-0603R, LCSC C2286](https://www.lcsc.com/product-detail/C2286.html)
- [USBLC6-2SC6, LCSC C7519](https://www.lcsc.com/product-detail/C7519.html)
- [TS-1187A-B-A-B, LCSC C318884](https://www.lcsc.com/product-detail/C318884.html)
- [CL05B104KO5NNNC, LCSC C1525](https://www.lcsc.com/product-detail/C1525.html)
- [CL05A105KA5NQNC, LCSC C52923](https://www.lcsc.com/product-detail/C52923.html)
- [CL05A475MP5NRNC, LCSC C23733](https://www.lcsc.com/product-detail/C23733.html)
- [CL05A106MQ5NUNC, LCSC C15525](https://www.lcsc.com/product-detail/C15525.html)
- [0402WGF1000TCE, LCSC C25076](https://www.lcsc.com/product-detail/C25076.html)
- [RC0402FR-07270RL, LCSC C163474](https://www.lcsc.com/product-detail/C163474.html)
- [0402WGF1001TCE, LCSC C11702](https://www.lcsc.com/product-detail/C11702.html)
- [0402WGF5101TCE, LCSC C25905](https://www.lcsc.com/product-detail/C25905.html)
- [0402WGF1002TCE, LCSC C25744](https://www.lcsc.com/product-detail/C25744.html)
- [0402WGF1003TCE, LCSC C25741](https://www.lcsc.com/product-detail/C25741.html)
- [BSMD1206-050-6V, LCSC C883122](https://www.lcsc.com/product-detail/C883122.html)
- [MMZ1608Y601BTA00, LCSC C136491](https://www.lcsc.com/product-detail/Ferrite-Beads_TDK_C136491.html)
- [PLA filament price per gram and per kg, 11 jun 2026, 3DPCC](https://3dprintingcostcalculator.com/news/filament-price-per-gram)
- [Overture PLA filament store listing](https://www.overture3d.com/collections/pla-filament)
- [JLCPCB parts library, tier and category listings](https://jlcpcb.com/parts)
- [JLCPCB PCBA price breakdown](https://jlcpcb.com/help/article/pcb-assembly-price)
- [iCE40 UltraPlus Family Data Sheet FPGA-DS-02008](https://www.latticesemi.com/-/media/LatticeSemi/Documents/DataSheets/iCE/iCE40-UltraPlus-Family-Data-Sheet.ashx)
