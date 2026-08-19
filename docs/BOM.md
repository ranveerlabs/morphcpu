# MorphCPU — bill of materials

**Quantity basis: 5 units.** Prices from LCSC, looked up **18 Aug 2026**.

Two things to read before using these numbers:

- **Prices and stock move.** Everything below is a snapshot on the date above.
  Re-check on the day you order, especially the FPGA.
- **Rows marked "to confirm" have no price.** Those parts have not been pinned
  to a specific LCSC part number yet, so there is no real price to quote and
  none has been invented. The totals below are totals *of the verified rows
  only*, and they are labelled as such.

---

## Verified — real part numbers, real prices

| # | Part | MPN | LCSC | Pkg | Qty/unit | Qty for 5 | Unit price | Line total |
|---|---|---|---|---|---|---|---|---|
| 1 | FPGA | ICE40UP5K-SG48I | [C2678152](https://www.lcsc.com/product-detail/C2678152.html) | QFN-48-EP (7×7) | 1 | 5 | $8.564 | **$42.82** |
| 2 | USB–UART bridge | FT231XS-R | [C132160](https://www.lcsc.com/product-detail/C132160.html) | SSOP-20-150mil | 1 | 5 | $5.9542 | **$29.77** |
| 3 | SPI config flash, 32 Mbit | W25Q32JVSSIQ | [C179173](https://www.lcsc.com/product-detail/C179173.html) | SOIC-8-208mil | 1 | 5 | $1.6846 | **$8.42** |
| 4 | USB-C receptacle, 16-pin | TYPE-C-31-M-12 | [C165948](https://www.lcsc.com/product-detail/C165948.html) | SMD right-angle | 1 | 5 | $0.1716 | **$0.86** |
| 5 | 3.3 V LDO, 1 A | AMS1117-3.3 | [C6186](https://www.lcsc.com/product-detail/C6186.html) | SOT-223 | 1 | 5 | $0.2032 | **$1.02** |
| 6 | LED, red, grid | KT-0603R | [C2286](https://www.lcsc.com/product-detail/C2286.html) | 0603 | 16 | 80 | $0.0075 | **$0.60** |
| | | | | | | | **Verified subtotal** | **$83.49** |

### Stock at time of lookup

| Part | LCSC stock | Comment |
|---|---|---|
| ICE40UP5K-SG48I | 546 | **Lowest-stock part in the design.** Order early |
| FT231XS-R | 1,657 | Fine for 5 units |
| W25Q32JVSSIQ | 39,664 | Ample |
| TYPE-C-31-M-12 | 407,730 | Ample |
| AMS1117-3.3 | 805,905 | Ample |
| KT-0603R | 3,752,200 | Ample |

---

## To confirm — no price quoted

These are real requirements with candidate parts, but no LCSC part number has
been fixed, so no price is claimed.

| # | Part | Requirement | Candidates | Qty for 5 |
|---|---|---|---|---|
| 7 | 12 MHz oscillator | **Active XO**, 3.3 V, SMD 3225 4-pad, ±50 ppm. *Not* a passive crystal — see [hardware/DESIGN.md](../hardware/DESIGN.md#2-a-bare-crystal-will-not-work-on-an-ice40) | Search JLCPCB for SMD3225-4P 12 MHz XO | 5 |
| 8 | 1.2 V LDO | ≥100 mA, fed from 3.3 V, low-ESR ceramic stable | XC6206P122MR, AP2112K-1.2TRG1 | 5 |
| 9 | Tactile switch | SMD, reset button | Any JLCPCB Basic 4-pad tactile | 5 |
| 10 | Resistors 0402/0603 | 270 Ω ×16, 5.1 kΩ ×2, 10 kΩ ×4, 100 Ω ×1 | JLCPCB Basic | ~115 |
| 11 | Ceramic caps 0402/0603 | 100 nF ×~18, 4.7 µF ×3, 10 µF ×2, 22 µF ×1 | JLCPCB Basic | ~120 |
| 12 | Ferrite bead | 0603, ~600 Ω @ 100 MHz | JLCPCB Basic | 10 |
| 13 | Polyfuse | 500 mA hold, 6 V | JLCPCB Basic | 5 |
| 14 | ESD array | USB D+/D− protection | JLCPCB Basic/Extended | 5 |

Passives are cents each; the realistic addition from rows 10–14 is a few
dollars across all five boards. Rows 7 and 8 are the two that need a real
decision before the total means anything.

---

## Costs that are not components

For a 5-unit run these dominate, and they are easy to forget when costing
against the **Complex ($210)** tier.

| Item | Notes |
|---|---|
| PCB fabrication | 5 × round 2-layer 60 mm boards. Cheap; the round outline is a routed profile, not a premium |
| SMT assembly setup | Charged per order |
| **Extended-part setup fees** | Charged **per distinct extended part**. Five parts in this design are Extended (FPGA, FT231X, flash, USB-C, and likely the XO). This is a fixed cost, so across only 5 boards it lands hard per unit |
| Stencil | Usually included with assembly |
| Shipping + duty | Varies |
| Case | ~15 g of filament per frame, negligible |

**The extended-part fees are the thing to watch.** Component cost is under $20
per board, but fixed per-order fees spread across a 5-unit run can rival it.
If the budget gets tight, building 10 rather than 5 barely changes the fixed
costs and roughly halves their per-unit share.

---

## Sources

- [ICE40UP5K-SG48I — LCSC C2678152](https://www.lcsc.com/product-detail/C2678152.html)
- [FT231XS-R — LCSC C132160](https://www.lcsc.com/product-detail/C132160.html)
- [FT231XS-U — LCSC C89607](https://www.lcsc.com/product-detail/C89607.html) (out of stock — do not use)
- [W25Q32JVSSIQ — LCSC C179173](https://www.lcsc.com/product-detail/C179173.html)
- [TYPE-C-31-M-12 — LCSC C165948](https://www.lcsc.com/product-detail/C165948.html)
- [AMS1117-3.3 — LCSC C6186](https://www.lcsc.com/product-detail/C6186.html)
- [KT-0603R — LCSC C2286](https://www.lcsc.com/product-detail/C2286.html)
- [iCE40 UltraPlus Family Data Sheet FPGA-DS-02008](https://www.latticesemi.com/-/media/LatticeSemi/Documents/DataSheets/iCE/iCE40-UltraPlus-Family-Data-Sheet.ashx)
- [iCE40 Oscillator Usage Guide FPGA-TN-02008](https://www.latticesemi.com/-/media/LatticeSemi/Documents/ApplicationNotes/IK2/FPGA-TN-02008-1-8-iCE40-Oscillator-User-Guide.ashx?document_id=50670)
