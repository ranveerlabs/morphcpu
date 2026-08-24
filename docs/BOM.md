# MorphCPU — bill of materials

**Quantity basis: 5 units.** Prices from LCSC, checked **20 Aug 2026**.

- **Prices and stock move.** Re-check on the day you order, especially the FPGA.
- **Rows marked "to confirm" have no price.** No price has been invented for a
  part that has not been pinned to an LCSC part number. Totals below cover the
  verified rows only and are labelled as such.

---

## Verified — real part numbers, real prices

| # | Part | MPN | LCSC | Pkg | Qty/unit | Qty for 5 | Unit price | Line total |
|---|---|---|---|---|---|---|---|---|
| 1 | FPGA | ICE40UP5K-SG48I | [C2678152](https://www.lcsc.com/product-detail/C2678152.html) | QFN-48-EP (7×7) | 1 | 5 | $8.564 | **$42.82** |
| 2 | USB–UART bridge | FT231XS-R | [C132160](https://www.lcsc.com/product-detail/C132160.html) | SSOP-20-150mil | 1 | 5 | $5.9542 | **$29.77** |
| 3 | SPI config flash, 32 Mbit | W25Q32JVSSIQ | [C179173](https://www.lcsc.com/product-detail/C179173.html) | SOIC-8-208mil | 1 | 5 | $1.6846 | **$8.42** |
| 4 | USB-C receptacle, 16-pin | TYPE-C-31-M-12 | [C165948](https://www.lcsc.com/product-detail/C165948.html) | SMD right-angle | 1 | 5 | $0.1716 | **$0.86** |
| 5 | 16 MHz oscillator (XO) | 1532H4-16000JWPDTSNL | [C5383161](https://www.lcsc.com/product-detail/C5383161.html) | SMD3225-4P | 1 | 5 | $0.3609 | **$1.80** |
| 6 | 3.3 V LDO (with enable) | ME6211C33M5G-N | [C82942](https://www.lcsc.com/product-detail/C82942.html) | SOT-23-5 | 1 | 5 | $0.053 | **$0.27** |
| 7 | 1.2 V LDO (with enable) | ME6211C12M5G-N | [C236672](https://www.lcsc.com/product-detail/C236672.html) | SOT-23-5 | 1 | 5 | $0.0606 | **$0.30** |
| 8 | LED, red, grid | KT-0603R | [C2286](https://www.lcsc.com/product-detail/C2286.html) | 0603 | 16 | 80 | $0.0075 | **$0.60** |
| | | | | | | | **Verified subtotal** | **$84.84** |

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

---

## Parts changed since the first costing

| Was | Now | Why |
|---|---|---|
| FT231XS-U (C89607) | **FT231XS-R (C132160)** | C89607 is out of stock, and `-U` is tube packaging. `-R` is tape-and-reel, which an assembly line wants. Identical SSOP-20-150mil footprint, no pin changes |
| AMS1117-3.3 (C6186) | **ME6211C33M5G-N (C82942)** | The power-up sequence needs the 3.3 V rail held off until 1.2 V is up. AMS1117 is SOT-223 with **no enable pin**. ME6211 has CE, is Basic tier, cheaper, and shares a footprint with the 1.2 V part |
| 12 MHz crystal + 2 load caps | **16 MHz XO (C5383161)** + 1 × 100 nF | The iCE40 has no crystal amplifier. 12 MHz active XOs at LCSC had 9 and 1 units in stock; the 16 MHz part has 147. Costs a gateware parameter change and improves UART divisor error from 0.16% to 0.08% |

### Oscillator stock note

147 units is adequate for a 5-unit build but is not deep. The two 12 MHz
alternatives were worse — [C7503622](https://www.lcsc.com/product-detail/C7503622.html)
had 9 units and [C2451123](https://www.lcsc.com/product-detail/C2451123.html)
had 1 at $5.94. If C5383161 dries up, any 3.3 V-capable HCMOS XO in SMD3225-4P
drops straight in; only `CLK_HZ` in the gateware and `--freq` in `build.sh`
follow the frequency.

---

## To confirm — no price quoted

Passives and protection parts. All are JLCPCB Basic-tier commodities costing
cents; the realistic addition across all five boards is a few dollars. Exact
LCSC numbers get pinned when the schematic BOM is exported.

| # | Part | Requirement | Qty for 5 |
|---|---|---|---|
| 9 | Tactile switch | SMD, reset button | 5 |
| 10 | Resistors 0402/0603 | 270 Ω ×16, 5.1 kΩ ×2, 10 kΩ ×5, 100 kΩ ×1, 100 Ω ×1 | ~125 |
| 11 | Ceramic caps 0402/0603 | 100 nF ×11, 4.7 µF ×3, 10 µF ×2, 1 µF ×2 | ~90 |
| 12 | Ferrite beads | 0603, ~600 Ω @ 100 MHz — VPP_2V5 and FT231X VCC | 10 |
| 13 | Polyfuse | 500 mA hold, 6 V | 5 |
| 14 | ESD array | USB D+/D− protection | 5 |

Resistor count breakdown: 16 LED series, 2 × CC pull-down (5.1 kΩ), 10 kΩ for
CRESET_B / CDONE / SPI_SS / FT231X RESET# / XO enable, 100 kΩ + 100 nF for the
3.3 V enable RC delay, and 100 Ω for the VCCPLL filter.

---

## Costs that are not components

For a 5-unit run these dominate, and they are easy to miss when costing against
the **Complex ($210)** tier.

| Item | Notes |
|---|---|
| PCB fabrication | 5 × round 2-layer 70 mm boards. Cheap; a round outline is a routed profile, not a premium |
| SMT assembly setup | Charged per order |
| **Extended-part setup fees** | Charged **per distinct extended part**. Five parts here are Extended (FPGA, FT231X, flash, USB-C, oscillator). Fixed cost, so across 5 boards it lands hard per unit |
| Stencil | Usually included with assembly |
| Shipping + duty | Varies |
| Case | ~15 g of filament per frame, negligible |

Component cost is under **$17 per board**, but fixed per-order fees across a
5-unit run can rival the whole BOM. Moving the two regulators to Basic-tier
parts helped; the five Extended parts are the remaining fixed cost. Building 10
instead of 5 barely changes those fees and roughly halves their per-unit share.

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
- [iCE40 UltraPlus Family Data Sheet FPGA-DS-02008](https://www.latticesemi.com/-/media/LatticeSemi/Documents/DataSheets/iCE/iCE40-UltraPlus-Family-Data-Sheet.ashx)
