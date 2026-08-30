# MorphCPU board, electrical design spec

Schematic is captured and ERC clean, placement is done, routing isnt

datasheet references are all to **FPGA-DS-02008-2.0, iCE40 UltraPlus Family Data
Sheet** (Lattice, 2018-2021). prices and stock checked **20 Aug 2026**, with the
passive rows added **23 Aug 2026**.

None of this has been on a bench. every number below is out of a datasheet or
arithmetic on top of one. the 28 C rise is calculated, the ~200 us rail-up is
inferred and not scoped, LED brightness is extrapolated off a curve at a
different current, and the RC sequencing delay has never been watched. no
bitstream either so theres no real Fmax anywhere in here. i think its all right,
none of it is verified

---

## what the parts list was missing

### no power supply

USB-C gives you 5 V. the iCE40UP5K needs **1.2 V core (VCC, pins 5 and 30) and
3.3 V I/O (VCCIO_0/1/2)** and runs on neither. so, two regulators.

### a bare crystal will not work on an iCE40

a passive crystal needs an amplifier to start it and the iCE40 doesnt have one.
the family gives you `SB_HFOSC` (48 MHz, ÷1/2/4/8) and `SB_LFOSC` (10 kHz) and
thats all. the SG48 pinout has no XIN/XOUT pair either. all 48 pins are
accounted for as I/O, supply or configuration, so theres nowhere to put one.

the internal oscillator wont do: its roughly ±10% untrimmed and 115200 baud
tolerates about ±2-3% total.

so the part has to be an active oscillator module. the pin table in the
[FPGA pinout](#fpga-pinout-ice40up5k-sg48i) section below confirms it.

### the power-up sequence was backwards

this one only turned up while chasing the VCCPLL rail voltage, and it changes
the 3.3 V regulator part, so its not cosmetic.

FPGA-DS-02008 §4.5 Power-up Supply Sequence (p.31) requires:

> 1. VCC and VCCPLL should be the first two supplies to be applied.
> 2. SPI_VCCIO1 should be the next supply, and can be applied any time after
>    the previous supplies (VCC and VCCPLL) have reached a level of 0.5 V or higher.
> 3. VPP_2V5 should be the next supply […]
> 4. Other Supplies (VCCIO0 and VCCIO2) […] can be applied any time after the
>    initial power supplies (VCC and VCCPLL) have reached a level of 0.5 V or greater.

§4.4 adds that only **VCC, SPI_VCCIO1 and VPP_2V5** are monitored by the on-chip
power-on-reset.

the original tree was `5 V -> 3.3 V -> 1.2 V`, a cascade. that brings **3.3 V up
first and 1.2 V last**, which is exactly backwards. SPI_VCCIO1 and VPP_2V5 would
both be applied before VCC ever reached 0.5 V.

since SPI_VCCIO1, VPP_2V5, VCCIO_0 and VCCIO_2 all sit on the same 3.3 V rail,
the whole requirement collapses to one rule:

> **1.2 V must reach 0.5 V before 3.3 V is applied.**

so feed both regulators from 5 V in parallel and hold the 3.3 V one off
with an RC delay on its enable until 1.2 V is up. which means the 3.3 V
regulator **needs an enable pin**, so **AMS1117-3.3 is out** (SOT-223, no
enable). ME6211C33M5G-N replaces it.

running 1.2 V straight off 5 V costs (5 - 1.2) × 30 mA ~ 114 mW in a SOT-23-5,
about a 28 °C rise. fine, and it kills the ordering problem outright instead of
papering over it.

---

## the oscillator

went with **1532H4-16000JWPDTSNL, C5383161**, a 16 MHz part, cuz the 12 MHz
active-XO supply at LCSC is thin enough to be a real risk. three parts checked,
all priced and stock-checked 20 Aug 2026:

| MPN | LCSC | Freq | Pkg | Price @1 | Stock |
|---|---|---|---|---|---|
| 1575H-12.000G33DTSTL | [C7503622](https://www.lcsc.com/product-detail/C7503622.html) | 12 MHz | SMD7050-4P | $0.87 | **9** |
| 1532H4-16000JWPDTSNL | [C5383161](https://www.lcsc.com/product-detail/C5383161.html) | 16 MHz | SMD3225-4P | $0.36 | **147** |
| ECS-TXO-3225-120-TR | [C2451123](https://www.lcsc.com/product-detail/C2451123.html) | 12 MHz TCXO | SMD3225-4P | $5.94 | **1** |

the TCXO is out on stock alone, and 16x the price for ±2.5 ppm nobody needs.
the 12 MHz one would have left the design alone but 9 units in stock is how you
end up having to redesign partway through. the 16 MHz part is also cheaper
and smaller, so the only cost is a clock change.

the first two are both confirmed active oscillators, not crystals. each one specifies a
supply voltage (A: 2.5-3.3 V, B: 1.8-3.3 V), a supply current, an **HCMOS
output** and a **tri-state enable on pad 1**. a passive crystal has none of
those. plenty of 4-pad 3225 parts at 12 MHz are crystals and got rejected.
`X322512MSB4SI` (C9002) quotes a 20 pF load capacitance, which only a passive
resonator has, so check the load capacitance field.

nothing depended on 12 MHz specifically. the change is `CLK_HZ = 16_000_000` in
`morphcpu_top.v`, `--freq 16` in `build.sh`, `DEFAULT_TICKDIV` 3,000,000 ->
4,000,000 to hold the tick at 4 Hz, and a comment in the pcf. all applied, both
testbenches still pass 18/18.

UART divisor goes 16e6 / 115200 = 138.89 -> 139, so error drops from 0.16% at
12 MHz to 0.08%, which i did not plan and only noticed afterwards.

---

## power tree

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
   |                   --> 16 MHz XO
   |                   --> 16 LEDs via resistors
   |
   +--> FT231XS-R VCC (5 V part with its own internal 3V3 LDO)
```

### rails

| Rail | Voltage | Regulator | Feeds | Est. current |
|---|---|---|---|---|
| VBUS | 5.0 V | - | Both regulators, FT231X | ~250 mA worst case |
| +1V2 | 1.2 V | ME6211C12M5G-N, [C236672](https://www.lcsc.com/product-detail/C236672.html) | VCC ×2, VCCPLL | 10-30 mA |
| +3V3 | 3.3 V | ME6211C33M5G-N, [C82942](https://www.lcsc.com/product-detail/C82942.html) | VCCIO ×3, VPP_2V5, flash, XO, LEDs | ~110 mA (80 mA of it LEDs) |

both regulators are SOT-23-5 from the same family, so they share a footprint.

| Part | Vout | Iout | Vin | CE | Price @1 | Stock |
|---|---|---|---|---|---|---|
| ME6211C33M5G-N | 3.3 V | 500 mA | 2.0-6.0 V | yes | $0.053 | 272,820 |
| ME6211C12M5G-N | 1.2 V | 300 mA | 1.2-6.0 V | yes | $0.0606 | 28,080 |

### sequencing RC

the 3.3 V regulator's CE is pulled to VBUS through **100 kΩ** with **100 nF** to
GND, so τ = 10 ms. the 1.2 V regulator starts the moment VBUS rises (hundreds of
microseconds), so VCC is well past 0.5 V long before 3.3 V is enabled.

the **10 kΩ** bleed to GND is not optional. without it CE doesnt discharge on
power-down and a fast power cycle skips the sequence. §4.5 says the sequence has
to be re-followed every time supplies are re-powered.

### VPP_2V5

Table 4.2 gives VPP_2V5 as **2.30-3.46 V for Master SPI configuration**, which is
the mode this board uses (external SPI flash). tying it to 3.3 V sits inside that
window with margin both ends.

note 4 of the same table allows 1.8 V only in Slave SPI mode and only if
HFOSC/LFOSC and the RGB driver are unused. neither applies here.

goes through a ferrite with its own 100 nF, so it can be lifted during bring-up
if configuration starts misbehaving.

### VCCPLL

an earlier revision of this doc implied VCCPLL sat on the 3.3 V rail. **that was
wrong.** Table 4.2 gives VCCPLL as **1.14-1.26 V**. its a core-voltage rail.
note 1 says VCC and VCCPLL should be tied to the same supply through an RC noise
filter.

so: **100 Ω series from +1V2 into pin 29, 100 nF to GND at the pin** (τ = 10 µs).
theres no PLL instantiated in the design, but the pin still has to be powered,
§4.2 says every supply pin must be connected for normal operation including
configuration.

---

## FPGA pinout (iCE40UP5K-SG48I)

complete SG48 pin assignment. Pin numbers are from the KiCad 10 symbol
`ICE40UP5K-SG48ITR` in `FPGA_Lattice.kicad_sym`. the counts cross-check exactly
against FPGA-DS-02008 §5.2 Pin Information Summary (2 × VCC, 3 × VCCIO,
1 × VCCPLL, 1 × VPP_2V5, 2 dedicated config, 39 GPIO, 0 dedicated GND = 48).

### supply and configuration pins

| Pin | Name | Net | Notes |
|---|---|---|---|
| 5 | VCC | +1V2 | Core |
| 30 | VCC | +1V2 | Core |
| 29 | VCCPLL | +1V2 | Via 100 Ω RC filter |
| 33 | VCCIO_0 | +3V3 | Bank 0 |
| 22 | SPI_VCCIO1 | +3V3 | Bank 1, powers the SPI config pins, POR-monitored |
| 1 | VCCIO_2 | +3V3 | Bank 2 |
| 24 | VPP_2V5 | +3V3 | Via ferrite |
| 49 | GND (paddle) | GND | **The only ground connection, see below** |
| 8 | CRESET_B | - | 10 kΩ to +3V3, test point |
| 7 | CDONE | - | 10 kΩ to +3V3, plus an LED |
| 14 | SPI_SO (IOB_32a) | FLASH_DO | Dedicated config |
| 15 | SPI_SCK (IOB_34a) | FLASH_CLK | Dedicated config |
| 16 | SPI_SS (IOB_35b) | FLASH_CS | Dedicated config, 10 kΩ pull-up |
| 17 | SPI_SI (IOB_33b) | FLASH_DI | Dedicated config |
| 39 | RGB0 | no connect | Constant-current LED driver, **not ordinary I/O** |
| 40 | RGB1 | no connect | " |
| 41 | RGB2 | no connect | " |

> **There is no dedicated ground pin on SG48.** Ground reaches the die only
> through the exposed paddle. FPGA-DS-02008 p.45 note: "48-pin QFN package
> (SG48) requires the package paddle to be connected to GND." that makes the
> paddle a hard electrical requirement rather than a thermal one. a badly
> soldered paddle leaves the die with no ground connection at all.

pins **39, 40, 41** are the `SB_RGBA_DRV` open-drain constant-current driver
outputs, left unused on purpose. the 16-LED grid needs plain LVCMOS I/O and
these behave differently.

### global-clock-capable pins

| Pin | Name | Buffer |
|---|---|---|
| 35 | IOT_46b_G0 | GBUF0 |
| 37 | IOT_45a_G1 | GBUF1 |
| 20 | IOB_25b_G3 | GBUF3 |
| 44 | IOB_3b_G6 | GBUF6 |

**The oscillator output goes to pin 35.** Routing a 12/16 MHz clock through
general fabric instead of a global buffer makes timing closure needlessly hard.

### user I/O assignment

| Pin | Symbol name | Net |
|---|---|---|
| 35 | IOT_46b_G0 | CLK (from XO) |
| 10 | IOB_18a | RST_N (button) |
| 34 | IOT_44b | UART_TX_O (to FT231X RXD) |
| 36 | IOT_48b | UART_RX_I (from FT231X TXD) |
| 2 | IOB_6a | LED0 |
| 3 | IOB_9b | LED1 |
| 23 | IOT_37a | LED2 |
| 27 | IOT_38b | LED3 |
| 12 | IOB_22a | LED4 |
| 13 | IOB_24a | LED5 |
| 18 | IOB_31b | LED6 |
| 19 | IOB_29b | LED7 |
| 21 | IOB_23b | LED8 |
| 9 | IOB_16a | LED9 |
| 25 | IOT_36b | LED10 |
| 26 | IOT_39a | LED11 |
| 48 | IOB_4a | LED12 |
| 46 | IOB_0a | LED13 |
| 38 | IOT_50b | LED14 |
| 32 | IOT_43a | LED15 |

checks this assignment passes:

- No LED lands on a dedicated config pin (14-17), on CRESET_B (8) or CDONE (7).
- No LED lands on an RGB driver pin (39-41).
- The clock is on a GBIN pin (35).
- Pin 20 (G3) is left free rather than spent on an LED, so a second global
  clock is still available later.
- LEDs are split across banks, 2, 3, 46, 48 on VCCIO_2 (pin 1), 9, 12, 13, 18,
  19, 21 on VCCIO_1 (pin 22) and 23, 25, 26, 27, 32, 38 on VCCIO_0 (pin 33), so
  80 mA is not drawn through one VCCIO pin, 25 / 25 / 30 mA. All three VCCIO
  pins are +3V3.
- Six LEDs moved off their first-pass pins during routing: LED12 -> 48,
  LED13 -> 46, LED14 -> 38 and LED9 -> 9, LED2 -> 23, LED3 -> 27. All six were
  crossing the package to reach a resistor on the far side, and U1's east column
  was running twelve nets out of twelve 0.5 mm channels, which left +3V3 (22, 33),
  +1V2 (5, 30) and LED12 with no escape at all. The south row, pads 37-48, was
  entirely unused. Bank assignments and the reasoning are in
  [ROUTING.md](ROUTING.md#the-fanout-ran-out-of-room-so-six-pins-moved).
- The UART sits on 34/36 in bank 0, not 6/9 in the config bank. Same +3V3
  VCCIO either way, and it costs no LED pin and no GBIN pin, but it puts both
  nets on the face that looks at the FT231X instead of the face opposite it.
  See [ROUTING.md](ROUTING.md#10-uart_tx_o-and-uart_rx_i-fixed) for the measurement.

`gateware/morphcpu.pcf` matches this table pin for pin. if you change one,
change the other, this one wins.

### decoupling, exact count

seven supply pins means **seven 100 nF**, one per pin, same side as the pin, vias
straight to the plane:

| Pin | Rail | Ceramic | Bulk |
|---|---|---|---|
| 5 | +1V2 VCC | 100 nF | share 10 µF |
| 30 | +1V2 VCC | 100 nF | share 10 µF |
| 29 | +1V2 VCCPLL | 100 nF | behind 100 Ω |
| 33 | +3V3 VCCIO_0 | 100 nF | share 4.7 µF |
| 22 | +3V3 SPI_VCCIO1 | 100 nF | 4.7 µF, keep this bank clean, it is POR-monitored |
| 1 | +3V3 VCCIO_2 | 100 nF | share 4.7 µF |
| 24 | +3V3 VPP_2V5 | 100 nF | behind ferrite |

then off the FPGA: 100 nF at the flash, 100 nF at the XO, 100 nF + 4.7 µF at
FT231X VCC, 100 nF + 4.7 µF at FT231X 3V3OUT, 1 µF in / 1 µF out on each ME6211
(datasheet minimum, and 10 µF on the 1.2 V output is comfortable).

**total 100 nF count: 11.** the old "roughly 10-14" guess is now an actual
number, and the BOM matches it.

---

## connections

### FT231XS-R, confirmed no pinout change

the swap from **FT231XS-U to FT231XS-R** got checked against every pin already
used in this doc. **no pin assignment changes.**

| | FT231XS-U | FT231XS-R |
|---|---|---|
| LCSC | [C89607](https://www.lcsc.com/product-detail/C89607.html) | [C132160](https://www.lcsc.com/product-detail/C132160.html) |
| Package (per LCSC) | SSOP-20-150mil | SSOP-20-150mil |
| Stock | **0, out of stock** | 1,657 |
| Price @1 | $4.47 | $5.9542 |

`FT231XS` is the SSOP-20 die and package. the trailing `-U` / `-R` is FTDI's
**packaging** suffix, `-U` is tube and `-R` is tape-and-reel. both LCSC entries
independently report the same SSOP-20-150mil footprint. the QFN variant is a
different base part number (`FT231XQ`) and isnt in play.

tape-and-reel is also what an SMT line wants. costs
about $1.50/unit more.

| FT231X pin | Net | Notes |
|---|---|---|
| VCC | VBUS (5 V) | Via ferrite from VBUS |
| 3V3OUT | FT_3V3 | Internal LDO output, 100 nF + 4.7 µF, do not load externally |
| VCCIO | FT_3V3 | Sets UART levels to 3.3 V |
| USBDP | USB_DP_F | Downstream side of the ESD array, see below |
| USBDM | USB_DM_F | Downstream side of the ESD array, see below |
| TXD | FPGA pin 36 (UART_RX_I) | Bridge transmits, FPGA receives |
| RXD | FPGA pin 34 (UART_TX_O) | |
| RESET# | 10 kΩ to VCC | |
| GND / AGND | GND | |
| CBUS0 / CBUS1 | optional LEDs | Default TXLED# / RXLED#, useful during bring-up |

direction is the classic trap: **TXD on the bridge goes to the FPGA's RX.**

### USB-C receptacle (16-pin, sink only)

| Pin | Net | Notes |
|---|---|---|
| VBUS (A4/A9/B4/B9) | VBUS | Tie all four together |
| GND (A1/A12/B1/B12) | GND | Tie all four together |
| D+ (A6/B6) | USB_DP | Tie both together, USB 2.0 device |
| D- (A7/B7) | USB_DM | Tie both together |
| CC1 (A5) | **5.1 kΩ to GND** | Required, advertises a sink |
| CC2 (B5) | **5.1 kΩ to GND** | **Separate resistor**, not shared with CC1 |
| SBU1 / SBU2 | no connect | |

two independent 5.1 kΩ resistors. share one, or use 10 kΩ, and some hosts and
chargers just wont give you power at all.

### ESD protection, USBLC6-2SC6 ([C7519](https://www.lcsc.com/product-detail/C7519.html)), SOT-23-6

U6, between the receptacle and the bridge. the USB-C port is the only bit of this
board anyone touches while its live, and the FT231X data pins are the only thing
sitting behind it.

| U6 pin | Name | Net | Notes |
|---|---|---|---|
| 1 | I/O1 | USB_DM | From J1 A7/B7 |
| 2 | GND | GND | |
| 3 | I/O2 | USB_DP | From J1 A6/B6 |
| 4 | I/O2 | USB_DP_F | To FT231X USBDP |
| 5 | VBUS | VBUS | Clamps the 5 V rail too |
| 6 | I/O1 | USB_DM_F | To FT231X USBDM |

pins 1/6 are the two ends of one protected line, 3/4 the other, each pair shorted
inside the package. giving each end its own net name is deliberate. it forces the
trace to route **through** the part instead of stubbing off it, so the clamp is
in the path and not just near it.

3.5 pF max line capacitance, irrelevant at full speed and still fine at high
speed. IEC 61000-4-2 level 4.

where it sits matters more than which part it is. U6 goes beside J1 on the
back, abt 5 mm from the connector's D+/D- pads, since protection downstream of a
long trace only protects the trace. the direct line between U2 and J1 is a
1.2 mm gap, too
narrow for SOT-23-6, and the front face is the LED display, so 5 mm is the best
the current placement allows. if routing says thats too long, shift U2 west and
reopen the centre channel. dont move the clamp further out.

### SPI configuration flash, W25Q32JVSSIQ ([C179173](https://www.lcsc.com/product-detail/C179173.html))

| Flash pin | FPGA pin | Net |
|---|---|---|
| CS# | 16 (SPI_SS) | FLASH_CS, **10 kΩ pull-up to +3V3** |
| CLK | 15 (SPI_SCK) | FLASH_CLK |
| DI (IO0) | 17 (SPI_SI) | FLASH_DI |
| DO (IO1) | 14 (SPI_SO) | FLASH_DO |
| WP# (IO2) | - | Tie to +3V3, quad mode unused |
| HOLD# (IO3) | - | Tie to +3V3 |
| VCC | - | +3V3, 100 nF local |
| GND | - | GND |

### oscillator: 1532H4-16000JWPDTSNL (LCSC C5383161), SMD3225-4P

| XO pad | Net | Notes |
|---|---|---|
| 1 | OE / tri-state enable | Tie to +3V3 through 10 kΩ to keep the output enabled |
| 2 | GND | |
| 3 | OUT | To FPGA **pin 35** (IOT_46b_G0) |
| 4 | VDD | +3V3, 100 nF right at the pad |

the 4-pad arrangement is standard across SMD XOs. this one is 3225
(3.2 x 2.5 mm). pad 1 is a tri-state enable, tying it high through 10 kΩ keeps
the output permanently on and leaves the option of gating it later if that ever
becomes interesting.

### configuration control

| Net | Treatment |
|---|---|
| CRESET_B (pin 8) | 10 kΩ pull-up to +3V3, plus a test point |
| CDONE (pin 7) | 10 kΩ pull-up to +3V3, plus an LED, lit means configured |
| Reset button | To FPGA **pin 10**, a user I/O, not CRESET_B |

the button is a logic reset and it keeps the loaded fabric topology. CRESET_B
reloads the whole bitstream, which is a much bigger hammer, so it gets a test
point instead of a button for the times you actually want that.

### LED grid

16 red LEDs, KT-0603R ([C2286](https://www.lcsc.com/product-detail/C2286.html)),
Vf 1.8-2.4 V, laid out as a physical 4×4 matching the fabric map.

```
R = (3.3 V - 2.0 V) / 5 mA = 260 Ω  ->  270 Ω (E24)
```

5 mA against the **8 mA IOL/IOH ceiling** from Table 4.13 leaves decent margin,
gives about 75 mcd out of a 300 mcd @ 20 mA part, and keeps the whole grid at
80 mA instead of 320 mA. going with the sinking arrangement instead? subtract the
0.4 V max VOL and use 200 Ω for the same current.

polarity is a schematic choice and the gateware follows it via `LED_ACTIVE_LOW`
on `morphcpu_top`, so it costs nothing to flip:

| Wiring | Parameter |
|---|---|
| Pin -> resistor -> anode, cathode to GND (pin sources) | `LED_ACTIVE_LOW = 0` (default) |
| +3V3 -> resistor -> anode, cathode -> pin (pin sinks) | `LED_ACTIVE_LOW = 1` |

---

## PCB brief

**placement is done, routing is not.** open `morphcpu.kicad_pcb` and route it by
hand, see [what is not here](#what-is-not-here).

net classes, JLC DRC rules and the order to route in are in
[ROUTING.md](ROUTING.md). read that first, it flags a resistor-ring placement
problem this section doesnt know about.

| Item | Value |
|---|---|
| Shape | Round, **70 mm** diameter (matches `pcb_dia` in [case/morphcpu_case.scad](../case/morphcpu_case.scad)) |
| Layers | 2, 1.6 mm, 1 oz - JLCPCB default stackup |
| Mounting | 4 x M2 on a 58 mm bolt circle (29 mm radius) at 45/135/225/315 deg |
| Min track / clearance | 6 mil / 6 mil |
| Min via | 0.3 mm hole / 0.6 mm pad |

### the board grew to 70 mm

first placement pass went at 60 mm and didnt fit. 79 footprints including a
QFN-48, an SSOP-20, a SOIC-8 and an edge-mounted USB-C left nothing between the
LED resistor ring and the outer parts. DRC came back with courtyard overlaps and
shorting pads that only cleared if you stacked parts over the mounting holes,
which isnt clearing them.

70 mm clears with margin: zero courtyard overlaps, zero shorting pads, zero
clearance violations. the case being parametric meant following the change was
two numbers (`pcb_dia`, `mount_hole_r`) and a re-export.

### placement scheme

the LED grid owns the centre of the **front**. everything else lives on the
**back** in concentric rings around the FPGA:

| Radius | What |
|---|---|
| 0 | FPGA, QFN-48 |
| 6.5 mm | One 100 nF per supply pin - seven of them |
| 9.0 mm | VCCPLL 100R filter and the VPP_2V5 ferrite, just outboard of their caps |
| 11.5 mm | 12 of the LED series resistors, each on its own LED's ray |
| 14.5 mm | The other 4, for the corner LEDs, which share a diagonal with the inner four |
| >= 17 mm | Everything with a real body, on the four cardinal directions |

diagonals stay clear from r=22 to r=26 for the mounting holes.

outer parts group by function. **east** is USB-C with the FT231X directly behind
it and the USBLC6 tucked beside the connector. **west** is the config flash and
the oscillator, both kept close to the FPGA because the SPI and clock nets care.
**north** is the 3.3 V regulator with its enable RC. **south** is the 1.2 V
regulator.

the 4x4 grid sits on a **9 mm pitch, 27 mm across** (four columns is three gaps),
matching `led_pitch` in the case source. cell 0 top-left, row-major, so the
physical grid reads the same way as the fabric map in
[gateware/README.md](../gateware/README.md). getting this backwards would make
the demo lie, so its worth checking twice.

silkscreen artwork space is the outer annulus past r=20, minus the four mounting
holes on the diagonals and the two front-face parts (SW1 top, CDONE LED bottom).

**paddle grounding is critical**, its the only ground path to the die. give it a
3x3 or 4x4 field of 0.3 mm vias into the ground pour, and window the paste
stencil into four or five squares instead of one big aperture so the part doesnt
float during reflow.

pour ground on both layers, stitch it, no isolated islands.

## JLCPCB assembly notes

| Part | LCSC | Tier | Stock (20 Aug 2026) |
|---|---|---|---|
| ICE40UP5K-SG48I | C2678152 | Extended | 546, **lowest in the design, order early** |
| FT231XS-R | C132160 | Extended | 1,657 |
| W25Q32JVSSIQ | C179173 | Extended | 39,664 |
| TYPE-C-31-M-12 | C165948 | Extended | 407,730 |
| ME6211C33M5G-N | C82942 | Basic | 272,820 |
| ME6211C12M5G-N | C236672 | Basic | 28,080 |
| KT-0603R | C2286 | Basic | 3,752,200 |
| 1532H4-16000JWPDTSNL | C5383161 | Extended | 147 |
| USBLC6-2SC6 | C7519 | Extended (inferred) | 35,370 |
| TS-1187A-B-A-B | C318884 | **Basic** (confirmed) | 792,020 |
| CL05B104KO5NNNC 100 nF | C1525 | **Basic** (confirmed) | 8,423,900 |
| CL05A105KA5NQNC 1 µF | C52923 | **Basic** (confirmed) | 5,345,900 |
| CL05A475MP5NRNC 4.7 µF | C23733 | **Basic** (confirmed) | 1,132,850 |
| CL05A106MQ5NUNC 10 µF | C15525 | **Basic** (confirmed) | 5,949,500 |
| 0402WGF1000TCE 100 Ω | C25076 | **Basic** (confirmed) | 329,500 |
| RC0402FR-07270RL 270 Ω | C163474 | Extended (confirmed) | 281,900 |
| 0402WGF1001TCE 1 kΩ | C11702 | **Basic** (confirmed) | 4,014,300 |
| 0402WGF5101TCE 5.1 kΩ | C25905 | **Basic** (confirmed) | 6,365,200 |
| 0402WGF1002TCE 10 kΩ | C25744 | **Basic** (confirmed) | 7,032,300 |
| 0402WGF1003TCE 100 kΩ | C25741 | **Basic** (confirmed) | 8,524,800 |
| BSMD1206-050-6V polyfuse | C883122 | Extended (confirmed) | 36,710 |
| MMZ1608Y601BTA00 ferrite | C136491 | Extended (inferred) | 11,200 |

rows below the oscillator were pinned on **23 Aug 2026**, stock figures for them
are from that date. "Inferred" means the part appears in neither JLC's Basic
category listings nor a published Basic-parts export, likely Extended, but not
quoted. Confirm in the PCBA quote.

both regulators are **Basic**. AMS1117 was Basic too, so swapping it for
ME6211C33M5G-N is fee-neutral, not a saving. the actual win is that the ME6211
pair share a footprint, which helped placement.

1. **extended parts carry a per-part setup fee**, charged once per distinct
   extended part per order. between **7 and 9** parts here are Extended
   depending on how C7519 and C136491 resolve. on a 5-unit run this is the
   dominant cost, bigger than the whole BOM. nine of the ten passive values were
   deliberately pinned to Basic parts to keep them off this list. 270 Ω 0402 has
   no Basic option at JLC at any tolerance, so its the one that couldnt be.
2. **check every footprint against JLCPCB's own land pattern**, not the generic
   KiCad library. the USB-C receptacle and the QFN-48 paddle are where
   mismatches actually bite.
3. **confirm stock the day you order.** 546 FPGAs is not many.

---

## post-routing checklist

**do this once manual routing is done.** next session's problem, not this one's.

the live working copy, plus the items the netclass pass added, is in
[ROUTING.md](ROUTING.md#post-routing-checklist). tick boxes there, not here.

- [ ] **DRC.** run it with the JLCPCB constraints (6 mil track/clearance, 0.3 mm
      via hole). zero errors, and review and justify every warning.
- [ ] **check the paddle.** via field present and connected, paste aperture
      windowed rather than one big square.
- [ ] **verify the 4×4 grid.** measure LED positions, 9 mm pitch, centred, cell 0
      top-left. silkscreen order matches the fabric map.
- [ ] **confirm the artwork annulus** (r = 22-29 mm) is still clear.
- [ ] **update the case.** set `pcb_dia`, `pcb_thickness`, `mount_hole_r`,
      `mount_hole_count`, `mount_hole_angle_offset`, `usb_angle`, `usb_z_centre`
      in `case/morphcpu_case.scad` from the finished board, then `./export.sh`.
- [ ] **re-check the PCF against the pin table** if any pin moved during
      routing. they agree right now, all 20.
- [ ] **build a bitstream.** install the OSS CAD Suite, run `gateware/build.sh`,
      put real LUT/BRAM utilisation and Fmax in `JOURNAL.md`.
- [ ] **re-run `gen_fab.py`.** the fab package already exists but was generated
      from the unrouted board, so it has no copper in it. regenerate after
      routing or youll ship blank layers.
- [ ] **3D view screenshot** for the README:
      `kicad-cli pcb render` (or KiCad's 3D viewer) -> `docs/img/pcb-3d.png`.
- [ ] **composite render** of case + PCB together for the README hero image.
- [ ] **re-check the BOM** in `docs/BOM.md` against the final board. its costed
      and all 22 rows are pinned, but quantities come from the schematic and the
      two inferred Extended tiers still need confirming in the quote.
- [ ] **confirm the USB-C overhang** against the board edge and the case cutout
      once the outline is final.
- [ ] **tidy silkscreen.** three cosmetic text overlaps left from the placement
      pass. theyll move as you adjust parts anyway.

---

## what is not here

**there is no routing in this repository.** placement is done and the board opens
clean, but the copper between the pads is deliberately absent.

there are gerbers, in `fab_output/`, and theyre real enough for JLC to quote
from, because a quote reads size, layer count and placement and nothing else.
they are not orderable. they were plotted from the unrouted board so the copper
layers are basically empty. regenerate them after routing.

why stop here: placement is a solvable layout problem. parts go in logical groups
at known coordinates and DRC confirms nothing collides. routing is a spatial
judgment call you make by looking at the board, and KiCad has no autorouter.
emitting trace coordinates without that feedback loop gets you a file that looks
finished and isnt, and on a $210 budget thats the worst available outcome.

so the board goes as far as "opens clean, route it by hand" and no further.

### state of the board file

`morphcpu.kicad_pcb`: 80 components plus the 4 mounting holes, so 84
footprints in the file. 92 nets, **0 tracks**.

`kicad-cli 10.0.5 pcb drc --severity-all` says:

```
** Found 1 DRC violations **
[silk_overlap]: Silkscreen clearance
    Rule: board setup constraints silk; warning
    @(150.8346 mm, 93.4503 mm): Reference field of C20
    @(150.7132 mm, 90.9523 mm): Reference field of R27

** Found 167 unconnected pads **
```

167 unconnected is every net, nothing is routed. the silk one is two reference
labels touching. no courtyard overlaps, no shorting pads, no clearance errors.

check these when you open it, before routing:

- **J1 overhang.** the USB-C receptacle sits at the +X edge so a plug can seat.
  confirm the shell position against the board outline and against `usb_angle`
  and the cutout in the case source. this is the one dimension the render cant
  settle for you.
- **front/back assignment.** the 16 LEDs, SW1 and the CDONE LED are front,
  everything else is back.
