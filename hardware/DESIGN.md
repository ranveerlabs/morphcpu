# MorphCPU board — electrical design specification

**Status: specification only. No KiCad project exists yet.** See
[What is not here](#what-is-not-here) for exactly where the line is and why.

This document is the engineering content that has to be settled before a
schematic is worth drawing: the power tree, the net-by-net connections, the
decoupling plan, and real JLCPCB-orderable parts. Prices and stock quoted here
were looked up on LCSC on **18 Aug 2026** and are cited per line in
[docs/BOM.md](../docs/BOM.md).

---

## Two problems with the original parts list

Both were found while costing the design, and both change the schematic.

### 1. There was no power supply

The brief specified USB-C as the only power input, and USB-C delivers 5 V. The
iCE40UP5K needs **1.2 V for its core and 3.3 V for its I/O banks** — it cannot
run from 5 V. Nothing in the original list produced either rail.

Two regulators are therefore added below. This is not optional.

### 2. A bare crystal will not work on an iCE40

The brief specified "12 MHz crystal + load caps per datasheet". A passive
crystal is not a clock — it needs an oscillator amplifier to start it, and
**the iCE40 does not have one**. The family provides only two on-chip
oscillators, `SB_HFOSC` (48 MHz, dividable by 1/2/4/8) and `SB_LFOSC` (10 kHz),
and exposes no XIN/XOUT crystal pins for an external resonator.

So there are two real options:

| Option | Cost | Accuracy | Verdict |
|---|---|---|---|
| Internal `SB_HFOSC` ÷4 = 12 MHz | free, zero parts | poor, roughly ±10% untrimmed | **Not usable.** 115200 baud UART tolerates about ±2–3% total error. ±10% will not enumerate reliably. |
| External **active oscillator (XO)**, 3.3 V, SMD 3225 4-pad | ~$0.50–1.00 | ±50 ppm typical | **Use this.** Drives a clock straight into a GBIN pin. |

The part changes from a 2-pad crystal to a 4-pad oscillator module, and the
two load capacitors disappear (an XO needs one 100 nF decoupling cap instead).

> The internal oscillator is still worth bringing out in gateware as a fallback
> so the board can blink even if the XO is unpopulated. That is a gateware
> change, not a schematic one.

---

## Power tree

```
USB-C VBUS 5V
   |
   +-- polyfuse 500mA -- ESD array
   |
   +--> AMS1117-3.3 (SOT-223) --> +3V3 rail
   |                                 |
   |                                 +--> FPGA VCCIO_0/1/2
   |                                 +--> FPGA VPP_2V5      (see note)
   |                                 +--> SPI config flash
   |                                 +--> 16 LEDs via resistors
   |                                 +--> XO 12 MHz
   |                                 |
   |                                 +--> XC6206P122 / AP2112K-1.2 --> +1V2
   |                                                                     |
   |                                                                     +--> FPGA VCC (core)
   |
   +--> FT231XS-R VCC (5 V part, has its own internal 3V3 LDO)
```

### Rails

| Rail | Voltage | Feeds | Est. current |
|---|---|---|---|
| VBUS | 5.0 V | Regulators, FT231X | ~250 mA worst case |
| +3V3 | 3.3 V | VCCIO banks, flash, XO, LEDs | ~110 mA (80 mA of it LEDs) |
| +1V2 | 1.2 V | FPGA core | ~10–30 mA for a design this small |

The 1.2 V regulator is fed from **3.3 V, not 5 V** — dropping 5→1.2 in a linear
regulator wastes 3.8 V across the pass device, and 3.3→1.2 keeps the dissipation
trivial at these currents.

### VPP_2V5

Despite the name, VPP_2V5 does not need a dedicated 2.5 V rail here. The
UltraPlus datasheet gives its range as **2.30–3.47 V when configuring from
NVCM**, and **1.30–3.47 V for release from power-on reset**. This board
configures from external SPI flash, not NVCM, so tying VPP_2V5 to the 3.3 V
rail sits comfortably inside both windows.

Connect it through a ferrite bead or 0 Ω link with its own 100 nF local cap, so
it can be isolated during bring-up if configuration misbehaves.

> **Confirm before layout:** VPP_2V5 handling is the one power decision here
> taken from datasheet summaries rather than a page I read directly. Check it
> against the iCE40 UltraPlus Family Data Sheet (FPGA-DS-02008) and the iCE40
> Hardware Checklist (FPGA-TN-02006) before committing the schematic.

---

## Decoupling

The rule the checklist enforces: **one 100 nF per power pin, placed on the same
side as the pin and vias straight to the plane**, plus bulk per rail. Group by
the pin's own rail, not by whichever cap is nearest.

| Rail / pin group | Ceramic | Bulk | Notes |
|---|---|---|---|
| VCC (core, 1.2 V) | 1 × 100 nF per VCC pin | 1 × 10 µF | Shortest possible loop to the exposed pad |
| VCCIO_0 | 1 × 100 nF per pin | share 4.7 µF | |
| VCCIO_1 | 1 × 100 nF per pin | share 4.7 µF | |
| VCCIO_2 | 1 × 100 nF per pin | 1 × 4.7 µF | This bank powers the SPI config pins — keep it clean |
| VPP_2V5 | 1 × 100 nF | — | Behind its own ferrite/0 Ω link |
| VCCPLL | 1 × 100 nF | — | Lattice reference designs feed VCCPLL through a ~100 Ω series resistor from VCC |
| SPI flash VCC | 1 × 100 nF | — | Right at the flash |
| FT231X VCC (5 V) | 1 × 100 nF | 1 × 4.7 µF | Ferrite from VBUS is good practice |
| FT231X 3V3OUT | 1 × 100 nF | 1 × 4.7 µF | Datasheet asks for this on the internal LDO output |
| AMS1117 in/out | — | 10 µF in, 22 µF out | AMS1117 needs output bulk for stability |
| 1.2 V LDO in/out | 1 × 100 nF each | 1 × 10 µF out | Low-ESR ceramic |
| 12 MHz XO | 1 × 100 nF | — | At the XO's own VDD pad |

> **Exact VCC/VCCIO pin count for SG48 is not confirmed here.** The number of
> 100 nF caps follows directly from it, so read the SG48 pinout table in
> FPGA-DS-02008 and fix the count before laying out. Budget for roughly 10–14
> 100 nF caps on the FPGA alone.

### Exposed pad

The QFN-48 has a **thermal/ground exposed pad that must be soldered to ground** —
it is the device's ground return, not just a heatsink. Give it a via field
(3×3 or 4×4 of 0.3 mm vias) down to the ground pour, and window the stencil
into four or five squares rather than one big aperture so the part does not
float on a ball of solder during reflow. JLCPCB's stencil will follow the paste
layer you give them, so this is your responsibility, not theirs.

---

## Connections

### USB-C receptacle (16-pin, sink only)

| Pin | Net | Notes |
|---|---|---|
| VBUS (A4/A9/B4/B9) | VBUS | Tie all together |
| GND (A1/A12/B1/B12) | GND | Tie all together |
| D+ (A6/B6) | USB_DP | Tie the two D+ pins together — this is a USB 2.0 device |
| D− (A7/B7) | USB_DM | Tie the two D− pins together |
| CC1 (A5) | via **5.1 kΩ** to GND | Required. Advertises "I am a sink" |
| CC2 (B5) | via **5.1 kΩ** to GND | Separate resistor, **not** shared with CC1 |
| SBU1/SBU2 | no connect | |

Two separate 5.1 kΩ resistors is the part people get wrong. Sharing one, or
using 10 kΩ, means some chargers and hosts will not supply power at all.

### FT231XS-R

| FT231X pin | Net | Notes |
|---|---|---|
| VCC | VBUS (5 V) | Through a ferrite from VBUS |
| 3V3OUT | FT_3V3 | Internal LDO output — 100 nF + 4.7 µF, do not load externally |
| VCCIO | FT_3V3 | Ties UART levels to 3.3 V |
| USBDP | USB_DP | |
| USBDM | USB_DM | |
| TXD | FPGA `uart_rx_i` | FT231X transmits, FPGA receives |
| RXD | FPGA `uart_tx_o` | |
| RESET# | pull-up 10 kΩ to VCC | |
| GND / AGND | GND | |
| CBUS0..3 | optional LEDs | CBUS0/1 default to TXLED#/RXLED# — nice for debug |

Signal direction is the classic trap: **TXD on the bridge goes to RX on the
FPGA.** The gateware port names are written from the FPGA's point of view.

### SPI configuration flash (W25Q32JVSSIQ)

| Flash pin | FPGA pin | Notes |
|---|---|---|
| CS# | SPI_SS | **10 kΩ pull-up to 3V3** |
| CLK | SPI_SCK | |
| DI (IO0) | SPI_SI | |
| DO (IO1) | SPI_SO | |
| WP# (IO2) | 3V3 | Tie high — not using quad mode |
| HOLD# (IO3) | 3V3 | Tie high |
| VCC | 3V3 | 100 nF local |
| GND | GND | |

These are the FPGA's **dedicated** configuration pins. They must not be reused
as user I/O for LEDs or UART, and the constraint file must leave them alone.

### Configuration control

| Net | Treatment |
|---|---|
| CRESET_B | 10 kΩ pull-up to 3V3, plus a test point. Pulling it low forces a reconfigure from flash |
| CDONE | 10 kΩ pull-up to 3V3, plus an LED (lit = configured). Worth having during bring-up |
| Reset button | To a **user I/O pin**, not CRESET_B — the gateware's `rst_n` is a logic reset that keeps the loaded topology |

Keeping the button off CRESET_B is deliberate: a CRESET_B press reloads the
whole bitstream, which is a much bigger hammer than the fabric reset the
gateware wants. Provide a test point on CRESET_B for when the big hammer is
genuinely needed.

### LED grid

16 LEDs, one per cell, laid out as a physical 4×4 matching the fabric map.

Current-limiting resistor, driving from 3.3 V into a red 0603 (KT-0603R,
Vf ≈ 2.0 V typical):

```
R = (3.3 V − 2.0 V) / 5 mA = 260 Ω  ->  use 270 Ω (E24)
```

5 mA per LED gives roughly 75 mcd from a 300 mcd @ 20 mA part — plenty indoors,
and it keeps the whole grid at 80 mA rather than 320 mA.

**Check the per-pin and per-bank current against the datasheet.** LVCMOS33 on
iCE40 supports 4 mA / 8 mA drive settings, so 5 mA needs the 8 mA setting. All
16 LEDs lit at once is 80 mA through VCCIO — spread them across banks rather
than hanging all 16 off one.

Polarity is a schematic choice, and the gateware follows it via the
`LED_ACTIVE_LOW` parameter on `morphcpu_top`:

| Wiring | Parameter |
|---|---|
| Pin → resistor → LED anode, cathode to GND (pin sources) | `LED_ACTIVE_LOW = 0` (default) |
| 3V3 → resistor → LED anode, cathode → pin (pin sinks) | `LED_ACTIVE_LOW = 1` |

Sinking is usually the kinder option for the I/O. Decide it in the schematic
and set the parameter to match — that is why it is a parameter and not a
hard-coded polarity.

---

## PCB brief

For whoever routes this — a small round 2-layer board.

| Item | Value |
|---|---|
| Shape | Round, 60 mm diameter (matches `pcb_dia` in [case/morphcpu_case.scad](../case/morphcpu_case.scad)) |
| Layers | 2, 1.6 mm, 1 oz copper — JLCPCB default stackup |
| Mounting | 4 × M2 on a 48 mm bolt circle (24 mm radius), at 45°/135°/225°/315° |
| Min track / clearance | 6 mil / 6 mil — comfortably inside JLCPCB's capability |
| Min via | 0.3 mm hole / 0.6 mm pad |

**The LED grid is the product.** Put the 4×4 dead centre on the front face, on
a 9 mm pitch (36 mm across), matching `led_pitch` in the case source. Cell 0
top-left, row-major, so the physical grid reads the same way as the fabric map
in [gateware/README.md](../gateware/README.md). Everything else — FPGA, bridge,
flash, regulators — goes on the back.

Silkscreen space is reserved on the front ring outside the LED grid: the
annulus between roughly r=22 mm and r=29 mm is kept clear of parts and
component silkscreen for artwork.

USB-C sits at the 0° (+X) edge; the case cutout is placed from `usb_angle`, so
if it moves, update that parameter and re-export the case.

Layout order that tends to go smoothest: USB-C and the FPGA first (they fix
everything else), then the flash and XO tight to the FPGA, then regulators,
then fan the 16 LED nets out to the front.

Pour ground on both layers, stitch it, and do not leave isolated copper islands.

---

## JLCPCB assembly notes

Assembly is **JLCPCB SMT, no hand soldering** — the QFN-48 rules that out anyway.

| Part | LCSC | Library tier | Note |
|---|---|---|---|
| ICE40UP5K-SG48I | C2678152 | Extended | 546 in stock. **Low.** Check before ordering |
| FT231XS-R | C132160 | Extended | 1,657 in stock. Use the `-R` reel part, see below |
| W25Q32JVSSIQ | C179173 | Extended | 39,664 in stock, comfortable |
| TYPE-C-31-M-12 | C165948 | Extended | 407,730 in stock |
| AMS1117-3.3 | C6186 | Basic | 805,905 in stock |
| KT-0603R | C2286 | Basic | 3,752,200 in stock |

Things to get right before uploading:

1. **Use FT231XS-R, not FT231XS-U.** The `-U` variant (C89607) is **out of
   stock at LCSC**, and `-U` is tube packaging while `-R` is tape-and-reel,
   which is what an assembly line wants. Same silicon, same SSOP-20-150mil
   footprint.
2. **Extended parts carry a per-part setup fee**, charged once per distinct
   extended part per order. Five of the parts above are extended. Factor that
   into the build cost — it is a fixed cost, so it hurts a 5-unit run far more
   per board than a 50-unit one.
3. **Check every footprint against JLCPCB's own land pattern**, not just the
   generic KiCad library. The USB-C receptacle and the QFN-48 exposed pad are
   where mismatches actually bite.
4. **Confirm stock the day you order.** 546 FPGAs is not a lot; that number can
   move before the order is placed.

---

## Open items

Everything below needs a datasheet page read before the schematic is final.
None of it is guesswork that can safely be left until after fabrication.

| # | Item | Source to check |
|---|---|---|
| 1 | Exact VCC / VCCIO / GND pin numbers for SG48, and how many 100 nF caps that implies | FPGA-DS-02008, SG48 pinout table |
| 2 | VPP_2V5 tied to 3V3 — confirm | FPGA-DS-02008 §Recommended Operating Conditions, FPGA-TN-02006 |
| 3 | Which SG48 pins are GBIN (global clock capable), for the XO | FPGA-DS-02008 pinout |
| 4 | Dedicated SPI config pin numbers, to reserve them in the PCF | FPGA-TN-02001 |
| 5 | Per-pin and per-bank I/O current limits for 16 LEDs at 5 mA | FPGA-DS-02008 DC characteristics |
| 6 | VCCPLL series resistor value, if the PLL is used at all | Lattice reference schematics |
| 7 | A specific 12 MHz XO with confirmed JLCPCB stock and price | JLCPCB parts library |
| 8 | A specific 1.2 V LDO with confirmed JLCPCB stock and price | JLCPCB parts library |

Items 1–5 block the schematic. Items 7 and 8 block the BOM total.

---

## What is not here

**There is no KiCad schematic and no PCB layout in this repository, and no
gerbers.** That is a deliberate stop, not an oversight.

A schematic can be generated as a netlist. A *routed board* cannot: placement
and routing are spatial problems solved by looking at the board, and KiCad has
no autorouter. Emitting `.kicad_pcb` coordinates without that feedback loop
produces a file that opens, looks plausible, and is not manufacturable — and
gerbers exported from it would be actively dangerous, because they would be
indistinguishable from real ones right up until a fab run came back dead.

With a funding tier of $210 and a hard deadline, a board that looks finished
and is not is the worst possible outcome. So the hardware deliverable here is
the part that is genuinely useful ahead of drawing it: the power tree, the
net-by-net connections, the decoupling plan, verified orderable parts, and a
list of exactly which datasheet pages still have to be read.

The schematic and layout are a KiCad session. This document is what makes that
session short.
