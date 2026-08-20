# MorphCPU board — electrical design specification

**Status: all eight blocking items resolved except one sourcing choice (item 7,
the oscillator), which needs a decision before schematic capture.** Every value
below is taken from a datasheet, a symbol library, or a distributor page, and
each is cited. No placeholder values remain.

Datasheet references throughout are to **FPGA-DS-02008-2.0, iCE40 UltraPlus
Family Data Sheet** (Lattice, 2018–2021). Distributor prices and stock were
checked on **20 Aug 2026**.

---

## Resolution summary

| # | Item | Resolved value | Source |
|---|---|---|---|
| 1 | VCC / VCCIO / GND pin numbers and cap count | VCC = 5, 30 · VCCIO_0 = 33 · SPI_VCCIO1 = 22 · VCCIO_2 = 1 · VCCPLL = 29 · VPP_2V5 = 24 · **no dedicated GND pin — paddle only**. 7 supply pins → 7 × 100 nF minimum | FPGA-DS-02008 §5.2 Pin Information Summary (p.45); pin numbers from KiCad 10 `FPGA_Lattice.kicad_sym`, symbol `ICE40UP5K-SG48ITR` |
| 2 | VPP_2V5 tied to 3V3 | **Confirmed.** Master SPI configuration requires 2.30–3.46 V. 3.3 V is inside that window | FPGA-DS-02008 Table 4.2 Recommended Operating Conditions (p.29) |
| 3 | GBIN (global clock) pins | **Pins 20 (G3), 35 (G0), 37 (G1), 44 (G6)**. Clock goes on **pin 35** | KiCad symbol pin names `IOT_46b_G0`, `IOT_45a_G1`, `IOB_25b_G3`, `IOB_3b_G6` |
| 4 | Dedicated SPI config pins | **14 = SPI_SO · 15 = SPI_SCK · 16 = SPI_SS · 17 = SPI_SI**, plus **8 = CRESET_B** and **7 = CDONE** | FPGA-DS-02008 §5.1 Signal Descriptions (IOB_32a/34a/35b/33b); pin numbers from the KiCad symbol |
| 5 | I/O current limit for the LEDs | **LVCMOS 3.3: IOL 8 mA / IOH −8 mA max.** 5 mA per LED is inside spec | FPGA-DS-02008 Table 4.13 sysI/O Single-Ended DC Electrical Characteristics (p.34) |
| 6 | VCCPLL treatment | **VCCPLL is a 1.2 V rail, not 3.3 V.** 1.14–1.26 V, same as VCC. Tie to VCC through an RC noise filter | FPGA-DS-02008 Table 4.2 (p.29) and Note 1: "VCC and VCCPLL are recommended to be tied together to the same supply with an RC-based noise filter between them" |
| 7 | 12 MHz oscillator | **Decision outstanding — three verified candidates below.** All are real, priced and stock-checked; the choice is a sourcing/frequency trade-off | LCSC C7503622 / C5383161 / C2451123 |
| 8 | 1.2 V LDO | **ME6211C12M5G-N, LCSC C236672**, SOT-23-5, 1.2 V, 300 mA, has CE. $0.0606, 28,080 in stock | [LCSC C236672](https://www.lcsc.com/product-detail/C236672.html) |

### Bonus finding: the power-up sequence was wrong

Resolving item 6 turned up a **power sequencing requirement that the original
power tree violated**. It is written up as problem 3 below and it changes the
3.3 V regulator part.

---

## Three problems with the original parts list

### 1. There was no power supply

USB-C delivers 5 V. The iCE40UP5K needs **1.2 V core (VCC, pins 5 and 30) and
3.3 V I/O (VCCIO_0/1/2)** and cannot run from 5 V. Two regulators are added.

### 2. A bare crystal will not work on an iCE40

A passive crystal needs an oscillator amplifier to start it and the iCE40 does
not have one. The family provides only `SB_HFOSC` (48 MHz, ÷1/2/4/8) and
`SB_LFOSC` (10 kHz), and the SG48 pinout has no XIN/XOUT pair — every one of the
48 pins is accounted for as I/O, supply, or configuration.

The internal oscillator is not a substitute: it is roughly ±10% untrimmed, and
115200 baud tolerates about ±2–3% total error.

**So the part must be an active oscillator (XO) module.** This is confirmed by
the pin table in the [FPGA pinout](#fpga-pinout-ice40up5k-sg48i) section below.

### 3. The power-up sequence was violated

FPGA-DS-02008 §4.5 Power-up Supply Sequence (p.31) requires:

> 1. VCC and VCCPLL should be the first two supplies to be applied.
> 2. SPI_VCCIO1 should be the next supply, and can be applied any time after
>    the previous supplies (VCC and VCCPLL) have reached a level of 0.5 V or higher.
> 3. VPP_2V5 should be the next supply […]
> 4. Other Supplies (VCCIO0 and VCCIO2) […] can be applied any time after the
>    initial power supplies (VCC and VCCPLL) have reached a level of 0.5 V or greater.

§4.4 adds that only **VCC, SPI_VCCIO1 and VPP_2V5** are monitored by the on-chip
power-on-reset.

The original tree was `5 V → 3.3 V → 1.2 V`, a cascade. That brings **3.3 V up
first and 1.2 V last** — exactly backwards. SPI_VCCIO1 and VPP_2V5 would both be
applied before VCC reached 0.5 V.

Since SPI_VCCIO1, VPP_2V5, VCCIO_0 and VCCIO_2 all sit on the same 3.3 V rail,
the requirement collapses to a single rule:

> **1.2 V must reach 0.5 V before 3.3 V is applied.**

**Fix:** both regulators are fed from 5 V in parallel, and the 3.3 V regulator
is held off by an RC delay on its enable pin until the 1.2 V rail is up. This
means the 3.3 V regulator **must have an enable pin** — so **AMS1117-3.3 is out**
(SOT-223, no enable). It is replaced by ME6211C33M5G-N.

Running 1.2 V directly from 5 V costs (5 − 1.2) × 30 mA ≈ 114 mW in a SOT-23-5,
about a 28 °C rise — acceptable, and it removes the ordering problem entirely
rather than papering over it.

---

## Item 7: the oscillator decision

The 12 MHz active-XO supply at LCSC is genuinely thin. Three parts were
verified — all real, all priced, all stock-checked on 20 Aug 2026:

| Option | MPN | LCSC | Freq | Pkg | Price @1 | **Stock** | Verdict |
|---|---|---|---|---|---|---|---|
| **A** | 1575H-12.000G33DTSTL | [C7503622](https://www.lcsc.com/product-detail/C7503622.html) | **12 MHz** | SMD**7050**-4P | $0.87 | **9** | Design unchanged, but 9 units is no margin at all |
| **B** | 1532H4-16000JWPDTSNL | [C5383161](https://www.lcsc.com/product-detail/C5383161.html) | **16 MHz** | SMD3225-4P | $0.36 | **147** | Healthy stock, cheaper, smaller. Needs a clock change |
| **C** | ECS-TXO-3225-120-TR | [C2451123](https://www.lcsc.com/product-detail/C2451123.html) | 12 MHz TCXO | SMD3225-4P | $5.94 | **1** | Ruled out — one unit, and 16× the price for ±2.5 ppm nobody needs |

Both A and B are confirmed active oscillators, not crystals: each specifies a
supply voltage (A: 2.5–3.3 V, B: 1.8–3.3 V), a supply current, an **HCMOS
output**, and a **tri-state enable on pad 1**. None of those exist on a passive
crystal. Several 4-pad 3225 parts at 12 MHz *are* crystals and were rejected —
`X322512MSB4SI` (C9002), for instance, quotes a 20 pF load capacitance, which
only a passive resonator has.

### Option B costs one parameter

The system clock is not load-bearing at 12 MHz specifically. Moving to 16 MHz
touches:

| Where | Change |
|---|---|
| `gateware/rtl/morphcpu_top.v` | `CLK_HZ = 16_000_000` |
| `gateware/morphcpu.pcf` | comment only |
| `gateware/build.sh` | `--freq 16` |
| UART divisor | 16e6 / 115200 = 138.89 → **139, error 0.08%** (12 MHz gives 104 → 0.16%, so 16 MHz is actually *better*) |
| Fabric tick divider | `DEFAULT_TICKDIV` 3,000,000 → 4,000,000 to keep 4 Hz |

**Recommendation: option B.** Stock of 9 on a hard-deadline build is the kind of
thing that turns into a redesign the week before submission, and the frequency
change is genuinely a parameter edit that also improves UART accuracy.

This is a sourcing/risk trade-off with a design consequence, so it is flagged
for a decision rather than taken unilaterally.

---

## Power tree

```
USB-C VBUS 5V
   |
   +-- polyfuse 500 mA -- ESD array
   |
   +--> ME6211C12M5G-N (SOT-23-5)  CE tied to VIN, always on
   |         |
   |         +--> +1V2 --> FPGA VCC       (pins 5, 30)
   |         |         --> FPGA VCCPLL    (pin 29) via RC filter
   |         |
   |         +--> (rail is up within ~200 us of VBUS)
   |
   +--> ME6211C33M5G-N (SOT-23-5)  CE via RC delay from 5V  <-- holds 3V3 off
   |         |                                                  until 1V2 is up
   |         +--> +3V3 --> FPGA VCCIO_0    (pin 33)
   |                   --> FPGA SPI_VCCIO1 (pin 22)
   |                   --> FPGA VCCIO_2    (pin 1)
   |                   --> FPGA VPP_2V5    (pin 24) via ferrite
   |                   --> SPI config flash
   |                   --> 12 MHz XO
   |                   --> 16 LEDs via resistors
   |
   +--> FT231XS-R VCC (5 V part with its own internal 3V3 LDO)
```

### Rails

| Rail | Voltage | Regulator | Feeds | Est. current |
|---|---|---|---|---|
| VBUS | 5.0 V | — | Both regulators, FT231X | ~250 mA worst case |
| +1V2 | 1.2 V | ME6211C12M5G-N, [C236672](https://www.lcsc.com/product-detail/C236672.html) | VCC ×2, VCCPLL | 10–30 mA |
| +3V3 | 3.3 V | ME6211C33M5G-N, [C82942](https://www.lcsc.com/product-detail/C82942.html) | VCCIO ×3, VPP_2V5, flash, XO, LEDs | ~110 mA (80 mA of it LEDs) |

Both regulators are SOT-23-5 from the same family, so they share a footprint.

| Part | Vout | Iout | Vin | CE | Price @1 | Stock |
|---|---|---|---|---|---|---|
| ME6211C33M5G-N | 3.3 V | 500 mA | 2.0–6.0 V | yes | $0.053 | 272,820 |
| ME6211C12M5G-N | 1.2 V | 300 mA | 1.2–6.0 V | yes | $0.0606 | 28,080 |

### Sequencing RC

The 3.3 V regulator's CE is pulled to VBUS through **100 kΩ** with **100 nF** to
GND, giving τ = 10 ms. The 1.2 V regulator starts as soon as VBUS rises
(hundreds of microseconds), so VCC is comfortably past 0.5 V long before 3.3 V
is enabled. Add a **10 kΩ** bleed to GND so CE discharges on power-down and the
sequence repeats correctly on a fast power cycle — §4.5 notes the sequence must
be re-followed whenever supplies are re-powered.

### VPP_2V5

Table 4.2 gives VPP_2V5 as **2.30–3.46 V for Master SPI configuration**, which is
the mode this board uses (external SPI flash). Tying it to 3.3 V is inside that
window with margin at both ends.

Note 4 of the same table allows 1.8 V *only* in Slave SPI mode and *only* if the
HFOSC/LFOSC and RGB LED driver are unused — not applicable here.

Connect through a ferrite bead with its own 100 nF, so it can be lifted during
bring-up if configuration misbehaves.

### VCCPLL — corrected

The previous revision of this document implied VCCPLL sat on the 3.3 V rail.
**That was wrong.** Table 4.2 gives VCCPLL as **1.14–1.26 V** — it is a core-voltage
rail. Note 1 says VCC and VCCPLL should be tied to the same supply through an
RC noise filter.

Implementation: **100 Ω series from +1V2 into pin 29, with 100 nF to GND at the
pin** (τ = 10 µs). The design does not currently instantiate a PLL, but the pin
must still be powered — §4.2 states all supply pins must be connected for normal
operation including configuration.

---

## FPGA pinout (iCE40UP5K-SG48I)

Complete SG48 pin assignment. Pin numbers are from the KiCad 10 symbol
`ICE40UP5K-SG48ITR` in `FPGA_Lattice.kicad_sym`; the counts cross-check exactly
against FPGA-DS-02008 §5.2 Pin Information Summary (2 × VCC, 3 × VCCIO,
1 × VCCPLL, 1 × VPP_2V5, 2 dedicated config, 39 GPIO, 0 dedicated GND = 48).

### Supply and configuration pins

| Pin | Name | Net | Notes |
|---|---|---|---|
| 5 | VCC | +1V2 | Core |
| 30 | VCC | +1V2 | Core |
| 29 | VCCPLL | +1V2 | Via 100 Ω RC filter |
| 33 | VCCIO_0 | +3V3 | Bank 0 |
| 22 | SPI_VCCIO1 | +3V3 | Bank 1 — powers the SPI config pins, POR-monitored |
| 1 | VCCIO_2 | +3V3 | Bank 2 |
| 24 | VPP_2V5 | +3V3 | Via ferrite |
| 49 | GND (paddle) | GND | **The only ground connection — see below** |
| 8 | CRESET_B | — | 10 kΩ to +3V3, test point |
| 7 | CDONE | — | 10 kΩ to +3V3, plus an LED |
| 14 | SPI_SO (IOB_32a) | FLASH_DO | Dedicated config |
| 15 | SPI_SCK (IOB_34a) | FLASH_CLK | Dedicated config |
| 16 | SPI_SS (IOB_35b) | FLASH_CS | Dedicated config, 10 kΩ pull-up |
| 17 | SPI_SI (IOB_33b) | FLASH_DI | Dedicated config |
| 39 | RGB0 | no connect | Constant-current LED driver, **not ordinary I/O** |
| 40 | RGB1 | no connect | " |
| 41 | RGB2 | no connect | " |

> **There is no dedicated ground pin on SG48.** Ground reaches the die *only*
> through the exposed paddle. FPGA-DS-02008 p.45 note: "48-pin QFN package
> (SG48) requires the package paddle to be connected to GND." This makes the
> paddle a hard electrical requirement, not a thermal nicety — a poorly
> soldered paddle is an open ground and a dead board.

Pins **39, 40, 41** are the `SB_RGBA_DRV` open-drain constant-current driver
outputs. They are deliberately left unused: the 16-LED grid needs plain LVCMOS
I/O, and these behave differently.

### Global-clock-capable pins

| Pin | Name | Buffer |
|---|---|---|
| 35 | IOT_46b_G0 | GBUF0 |
| 37 | IOT_45a_G1 | GBUF1 |
| 20 | IOB_25b_G3 | GBUF3 |
| 44 | IOB_3b_G6 | GBUF6 |

**The oscillator output goes to pin 35.** Routing a 12/16 MHz clock through
general fabric instead of a global buffer makes timing closure needlessly hard.

### User I/O assignment

| Pin | Symbol name | Net |
|---|---|---|
| 35 | IOT_46b_G0 | CLK (from XO) |
| 10 | IOB_18a | RST_N (button) |
| 6 | IOB_13b | UART_RX_I (from FT231X TXD) |
| 9 | IOB_16a | UART_TX_O (to FT231X RXD) |
| 2 | IOB_6a | LED0 |
| 3 | IOB_9b | LED1 |
| 4 | IOB_8a | LED2 |
| 11 | IOB_20a | LED3 |
| 12 | IOB_22a | LED4 |
| 13 | IOB_24a | LED5 |
| 18 | IOB_31b | LED6 |
| 19 | IOB_29b | LED7 |
| 21 | IOB_23b | LED8 |
| 23 | IOT_37a | LED9 |
| 25 | IOT_36b | LED10 |
| 26 | IOT_39a | LED11 |
| 27 | IOT_38b | LED12 |
| 28 | IOT_41a | LED13 |
| 31 | IOT_42b | LED14 |
| 32 | IOT_43a | LED15 |

Checks this assignment passes:

- No LED lands on a dedicated config pin (14–17), on CRESET_B (8) or CDONE (7).
- No LED lands on an RGB driver pin (39–41).
- The clock is on a GBIN pin (35).
- Pin 20 (G3) is left free rather than spent on an LED, so a second global
  clock is still available later.
- LEDs are split across banks — 2, 3, 4, 11, 12, 13, 18, 19, 21 in bank 1/2 and
  23, 25, 26, 27, 28, 31, 32 in bank 0 — so 80 mA is not drawn through one
  VCCIO pin.

This table supersedes the candidate assignment in `gateware/morphcpu.pcf`, which
must be updated to match before a bitstream is built.

### Decoupling — exact count

Seven supply pins, therefore **seven 100 nF**, one per pin, on the same side as
the pin with vias straight to the plane:

| Pin | Rail | Ceramic | Bulk |
|---|---|---|---|
| 5 | +1V2 VCC | 100 nF | share 10 µF |
| 30 | +1V2 VCC | 100 nF | share 10 µF |
| 29 | +1V2 VCCPLL | 100 nF | behind 100 Ω |
| 33 | +3V3 VCCIO_0 | 100 nF | share 4.7 µF |
| 22 | +3V3 SPI_VCCIO1 | 100 nF | 4.7 µF — keep this bank clean, it is POR-monitored |
| 1 | +3V3 VCCIO_2 | 100 nF | share 4.7 µF |
| 24 | +3V3 VPP_2V5 | 100 nF | behind ferrite |

Plus, off the FPGA: 100 nF at the flash, 100 nF at the XO, 100 nF + 4.7 µF at
FT231X VCC, 100 nF + 4.7 µF at FT231X 3V3OUT, and 1 µF in / 1 µF out on each
ME6211 (datasheet minimum; 10 µF on the 1.2 V output is comfortable).

**Total 100 nF count: 11.** The earlier estimate of "roughly 10–14" is now exact.

---

## Connections

### FT231XS-R — confirmed no pinout change

The swap from **FT231XS-U to FT231XS-R** was checked against every pin already
used in this document. **No pin assignment changes.**

| | FT231XS-U | FT231XS-R |
|---|---|---|
| LCSC | [C89607](https://www.lcsc.com/product-detail/C89607.html) | [C132160](https://www.lcsc.com/product-detail/C132160.html) |
| Package (per LCSC) | SSOP-20-150mil | SSOP-20-150mil |
| Stock | **0 — out of stock** | 1,657 |
| Price @1 | $4.47 | $5.9542 |

The `FT231XS` base part number denotes the SSOP-20 die and package; the trailing
`-U` / `-R` is FTDI's **packaging** suffix — `-U` is tube, `-R` is tape-and-reel.
Both LCSC entries independently report the same SSOP-20-150mil footprint. The
QFN variant is a different base part number (`FT231XQ`) and is not in play.

Tape-and-reel is also the correct packaging for an SMT assembly line, so the
swap is an improvement on two counts. Cost is about $1.50/unit more.

| FT231X pin | Net | Notes |
|---|---|---|
| VCC | VBUS (5 V) | Via ferrite from VBUS |
| 3V3OUT | FT_3V3 | Internal LDO output — 100 nF + 4.7 µF, do not load externally |
| VCCIO | FT_3V3 | Sets UART levels to 3.3 V |
| USBDP | USB_DP | |
| USBDM | USB_DM | |
| TXD | FPGA pin 6 (UART_RX_I) | Bridge transmits, FPGA receives |
| RXD | FPGA pin 9 (UART_TX_O) | |
| RESET# | 10 kΩ to VCC | |
| GND / AGND | GND | |
| CBUS0 / CBUS1 | optional LEDs | Default TXLED# / RXLED#, useful during bring-up |

Direction is the classic trap: **TXD on the bridge goes to the FPGA's RX.**

### USB-C receptacle (16-pin, sink only)

| Pin | Net | Notes |
|---|---|---|
| VBUS (A4/A9/B4/B9) | VBUS | Tie all four together |
| GND (A1/A12/B1/B12) | GND | Tie all four together |
| D+ (A6/B6) | USB_DP | Tie both together — USB 2.0 device |
| D− (A7/B7) | USB_DM | Tie both together |
| CC1 (A5) | **5.1 kΩ to GND** | Required — advertises a sink |
| CC2 (B5) | **5.1 kΩ to GND** | **Separate resistor**, not shared with CC1 |
| SBU1 / SBU2 | no connect | |

Two independent 5.1 kΩ resistors. Sharing one, or using 10 kΩ, means some hosts
and chargers will not deliver power at all.

### SPI configuration flash — W25Q32JVSSIQ ([C179173](https://www.lcsc.com/product-detail/C179173.html))

| Flash pin | FPGA pin | Net |
|---|---|---|
| CS# | 16 (SPI_SS) | FLASH_CS — **10 kΩ pull-up to +3V3** |
| CLK | 15 (SPI_SCK) | FLASH_CLK |
| DI (IO0) | 17 (SPI_SI) | FLASH_DI |
| DO (IO1) | 14 (SPI_SO) | FLASH_DO |
| WP# (IO2) | — | Tie to +3V3, quad mode unused |
| HOLD# (IO3) | — | Tie to +3V3 |
| VCC | — | +3V3, 100 nF local |
| GND | — | GND |

### Oscillator (SMD 4-pad, either candidate)

| XO pad | Net | Notes |
|---|---|---|
| 1 | OE / tri-state enable | Tie to +3V3 through 10 kΩ to keep the output enabled |
| 2 | GND | |
| 3 | OUT | To FPGA **pin 35** (IOT_46b_G0) |
| 4 | VDD | +3V3, 100 nF right at the pad |

Both candidates use the same 4-pad arrangement; only the body size differs
(3225 vs 7050), so this is a footprint choice, not a wiring one.

### Configuration control

| Net | Treatment |
|---|---|
| CRESET_B (pin 8) | 10 kΩ pull-up to +3V3, plus a test point |
| CDONE (pin 7) | 10 kΩ pull-up to +3V3, plus an LED — lit means configured |
| Reset button | To FPGA **pin 10**, a user I/O — *not* CRESET_B |

The button drives a logic reset that preserves the loaded fabric topology.
CRESET_B reloads the entire bitstream, which is a much bigger hammer; it gets a
test point for when that is actually wanted.

### LED grid

16 red LEDs, KT-0603R ([C2286](https://www.lcsc.com/product-detail/C2286.html)),
Vf 1.8–2.4 V, laid out as a physical 4×4 matching the fabric map.

```
R = (3.3 V − 2.0 V) / 5 mA = 260 Ω  ->  270 Ω (E24)
```

5 mA against the **8 mA IOL/IOH ceiling** from Table 4.13 leaves comfortable
margin, gives ~75 mcd from a 300 mcd @ 20 mA part, and holds the whole grid to
80 mA rather than 320 mA. If the sinking arrangement is chosen, subtract the
0.4 V max VOL and use 200 Ω for the same current.

Polarity is a schematic choice and the gateware follows it via `LED_ACTIVE_LOW`
on `morphcpu_top`:

| Wiring | Parameter |
|---|---|
| Pin → resistor → anode, cathode to GND (pin sources) | `LED_ACTIVE_LOW = 0` (default) |
| +3V3 → resistor → anode, cathode → pin (pin sinks) | `LED_ACTIVE_LOW = 1` |

---

## PCB brief

| Item | Value |
|---|---|
| Shape | Round, 60 mm diameter (matches `pcb_dia` in [case/morphcpu_case.scad](../case/morphcpu_case.scad)) |
| Layers | 2, 1.6 mm, 1 oz — JLCPCB default stackup |
| Mounting | 4 × M2 on a 48 mm bolt circle (24 mm radius) at 45°/135°/225°/315° |
| Min track / clearance | 6 mil / 6 mil |
| Min via | 0.3 mm hole / 0.6 mm pad |

**The LED grid is the product.** 4×4 dead centre on the front face, 9 mm pitch
(36 mm across), matching `led_pitch` in the case source. Cell 0 top-left,
row-major, so the physical grid reads the same as the fabric map in
[gateware/README.md](../gateware/README.md). Everything else goes on the back.

Silkscreen artwork space is reserved on the front annulus between roughly
r = 22 mm and r = 29 mm — keep parts and reference designators out of it.

USB-C at the 0° (+X) edge; the case cutout follows `usb_angle`.

**Paddle grounding is critical** — it is the only ground path to the die. Give
it a 3×3 or 4×4 field of 0.3 mm vias to the ground pour, and window the paste
stencil into four or five squares rather than one large aperture so the part
does not float during reflow.

Pour ground on both layers, stitch it, leave no isolated islands.

---

## JLCPCB assembly notes

| Part | LCSC | Tier | Stock (20 Aug 2026) |
|---|---|---|---|
| ICE40UP5K-SG48I | C2678152 | Extended | 546 — **lowest in the design, order early** |
| FT231XS-R | C132160 | Extended | 1,657 |
| W25Q32JVSSIQ | C179173 | Extended | 39,664 |
| TYPE-C-31-M-12 | C165948 | Extended | 407,730 |
| ME6211C33M5G-N | C82942 | Basic | 272,820 |
| ME6211C12M5G-N | C236672 | Basic | 28,080 |
| KT-0603R | C2286 | Basic | 3,752,200 |
| Oscillator | see item 7 | Extended | **9 or 147 depending on choice** |

Both regulators are **Basic** parts, so replacing AMS1117-3.3 with ME6211C33M5G-N
costs nothing in extended-part fees and actually removes one (AMS1117 was Basic
too, so this is neutral — but the ME6211 pair share a footprint, which helps
placement).

1. **Extended parts carry a per-part setup fee**, charged once per distinct
   extended part per order. Five parts here are Extended. On a 5-unit run this
   is the dominant cost.
2. **Check every footprint against JLCPCB's own land pattern**, not the generic
   KiCad library. The USB-C receptacle and the QFN-48 paddle are where
   mismatches bite.
3. **Confirm stock the day you order.** 546 FPGAs is not many.

---

## Post-routing checklist

**Do this after manual routing is complete** — it is the next session's work,
not this one's.

- [ ] **DRC.** Run KiCad DRC with the JLCPCB constraints (6 mil track/clearance,
      0.3 mm via hole). Zero errors; review and justify every warning.
- [ ] **Check the paddle.** Confirm the via field is present and connected, and
      that the paste aperture is windowed rather than one large square.
- [ ] **Verify the 4×4 grid.** Measure LED positions — 9 mm pitch, centred,
      cell 0 top-left. Confirm silkscreen order matches the fabric map.
- [ ] **Confirm the artwork annulus** (r = 22–29 mm) is still clear.
- [ ] **Update the case.** Set `pcb_dia`, `pcb_thickness`, `mount_hole_r`,
      `mount_hole_count`, `mount_hole_angle_offset`, `usb_angle`, `usb_z_centre`
      in `case/morphcpu_case.scad` from the finished board, then `./export.sh`.
- [ ] **Update the PCF.** Copy the [user I/O assignment](#user-io-assignment)
      into `gateware/morphcpu.pcf` and delete its "candidate" header.
- [ ] **Build a bitstream.** Install the OSS CAD Suite, run `gateware/build.sh`,
      record real LUT/BRAM utilisation and Fmax in `JOURNAL.md`.
- [ ] **Export fabrication output** to `hardware/fab_output/`:
      `kicad-cli pcb export gerbers` and `kicad-cli pcb export drill`.
      Zip for a tagged release rather than committing the gerbers.
- [ ] **3D view screenshot** for the README:
      `kicad-cli pcb render` (or KiCad's 3D viewer) → `docs/img/pcb-3d.png`.
- [ ] **Composite render** of case + PCB together for the README hero image.
- [ ] **Re-cost the BOM** in `docs/BOM.md` with final quantities and the
      oscillator choice resolved.

---

## What is not here

There is no PCB **routing** in this repository, and no gerbers. Placement is
done; routing is not, and is deliberately left for a human.

Placement is a solvable layout problem — parts go in logical groups at known
coordinates. Routing is a spatial judgment call made by looking at the board,
and KiCad has no autorouter. Emitting trace coordinates without that feedback
loop produces a file that opens, looks plausible, and is not manufacturable.
With a funding tier of $210 and a hard deadline, a board that looks finished and
is not is the worst available outcome.

So the board is taken to the point where it can be opened and routed by hand,
and no further.
