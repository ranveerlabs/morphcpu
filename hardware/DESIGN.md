# MorphCPU board design

The schematic passes ERC. The board is placed and routed on four layers.

The datasheet references are to FPGA-DS-02008-2.0, the iCE40 UltraPlus Family
Data Sheet (Lattice, 2018-2021). I checked most prices and stock on 20 Aug 2026,
then added the passive parts on 23 Aug.

The board hasnt been tested on a bench. The 28 °C rise is calculated, the ~200 µs
rail-up time is inferred rather than measured, and the LED brightness comes from
a curve at a different current. I havent scoped the RC delay either. The earlier
pin map built at 37.33 MHz, but the latest LED1/LED2 assignments still need a
fresh build.

---

## power and clock

### regulator voltages

USB-C gives you 5 V. the iCE40UP5K needs 1.2 V core (VCC, pins 5 and 30) and
3.3 V I/O (VCCIO_0/1/2) and runs on neither, so two regulators

### clock source

a passive crystal needs an amplifier to start it and the iCE40 doesnt have one.
the family gives you `SB_HFOSC` (48 MHz, ÷1/2/4/8) and `SB_LFOSC` (10 kHz) and
thats the lot. no XIN/XOUT pair on SG48 either, all 48 pins are accounted for as
I/O, supply or configuration

the internal oscillator wont do, its roughly ±10% untrimmed and 115200 baud
tolerates abt ±2-3% total

so its an active oscillator module. the pin table in the
[FPGA pinout](#fpga-pinout-ice40up5k-sg48i) section has it

### supply order

I caught the supply-order problem while checking the VCCPLL voltage. It meant
changing the 3.3 V regulator too.

FPGA-DS-02008 §4.5 Power-up Supply Sequence (p.31) requires:

> 1. VCC and VCCPLL should be the first two supplies to be applied.
> 2. SPI_VCCIO1 should be the next supply, and can be applied any time after
>    the previous supplies (VCC and VCCPLL) have reached a level of 0.5 V or higher.
> 3. VPP_2V5 should be the next supply […]
> 4. Other Supplies (VCCIO0 and VCCIO2) […] can be applied any time after the
>    initial power supplies (VCC and VCCPLL) have reached a level of 0.5 V or greater.

§4.4 adds that only VCC, SPI_VCCIO1 and VPP_2V5 are monitored by the on-chip
power-on-reset

The original tree was `5 V -> 3.3 V -> 1.2 V`. That brings 3.3 V up first and
1.2 V last, so SPI_VCCIO1 and VPP_2V5 would be applied before VCC reached 0.5 V.

SPI_VCCIO1, VPP_2V5, VCCIO_0 and VCCIO_2 all use the same 3.3 V rail. The rule
for this board is:

> 1.2 V must reach 0.5 V before 3.3 V is applied.

Both regulators now feed from 5 V in parallel. An RC delay on the 3.3 V
regulator's enable holds that rail off until 1.2 V is up. That needs an enable
pin, which the SOT-223 AMS1117-3.3 doesnt have, so I changed it to AP2112K-3.3TRG1.

Running 1.2 V straight from 5 V costs about 114 mW at 30 mA, or a calculated
28 °C rise in the SOT-23-5 regulator.

---

## oscillator choice

I picked the 16 MHz 1532H4-16000JWPDTSNL (C5383161) because LCSC only had nine
of the 12 MHz active oscillator in stock. I compared three parts and checked
their prices and stock on 20 Aug 2026:

| MPN | LCSC | Freq | Pkg | Price @1 | Stock |
|---|---|---|---|---|---|
| 1575H-12.000G33DTSTL | [C7503622](https://www.lcsc.com/product-detail/C7503622.html) | 12 MHz | SMD7050-4P | $0.87 | 9 |
| 1532H4-16000JWPDTSNL | [C5383161](https://www.lcsc.com/product-detail/C5383161.html) | 16 MHz | SMD3225-4P | $0.36 | 147 |
| ECS-TXO-3225-120-TR | [C2451123](https://www.lcsc.com/product-detail/C2451123.html) | 12 MHz TCXO | SMD3225-4P | $5.94 | 1 |

The TCXO had one in stock and cost 16 times as much for ±2.5 ppm accuracy this
board doesnt need. The 12 MHz part would have avoided a clock change, but nine
in stock felt like a supply risk. The 16 MHz part was cheaper and smaller, so I
changed the clock instead.

the first two are both confirmed active oscillators, not crystals. each one
specifies a supply voltage (A: 2.5-3.3 V, B: 1.8-3.3 V), a supply current, an
HCMOS output and a tri-state enable on pad 1, and a passive crystal has none of
those. plenty of 4-pad 3225 parts at 12 MHz are crystals and got thrown out.
`X322512MSB4SI` (C9002) quotes a 20 pF load capacitance and only a passive
resonator has one of those, so check the load capacitance field

Nothing depended on 12 MHz specifically. I changed `CLK_HZ = 16_000_000` in
`morphcpu_top.v`, `--freq 16` in `build.sh`, `DEFAULT_TICKDIV` 3,000,000 ->
4,000,000 to hold the tick at 4 Hz, and a comment in the pcf. all applied, both
testbenches still pass 18/18

The UART divisor is 16e6 / 115200 = 138.89 -> 139. That drops the error from
0.16% at 12 MHz to 0.08%, a side effect I only noticed afterwards.

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
   +--> AP2112K-3.3TRG1 (SOT-23-5) EN via RC delay from 5V  <-- holds 3V3 off
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
| +3V3 | 3.3 V | AP2112K-3.3TRG1, [C51118](https://www.lcsc.com/product-detail/C51118.html) | VCCIO ×3, VPP_2V5, flash, XO, LEDs | ~110 mA (80 mA of it LEDs) |

both regulators are SOT-23-5 out of the same family so they share a footprint

| Part | Vout | Iout | Vin | CE | Price @1 | Stock |
|---|---|---|---|---|---|---|
| AP2112K-3.3TRG1 | 3.3 V | 600 mA | up to 6.0 V | yes | $0.0967 | 70,670 |
| ME6211C12M5G-N | 1.2 V | 300 mA | 1.2-6.0 V | yes | $0.0606 | 28,080 |

### sequencing RC

The 3.3 V regulator's EN has 100 kΩ to VBUS, 100 nF to GND and a 1 MΩ bleed.
It settles at 5 × 1M/1.1M = 4.55 V. The time constant is (100 kΩ || 1 MΩ) ×
100 nF = 9.1 ms. The 1.2 V regulator starts within hundreds of microseconds of
VBUS, so VCC is past 0.5 V before the 3.3 V regulator turns on.

The bleed matters on power-down too. Without it, EN doesnt discharge and a fast
power cycle can skip the sequence. Section 4.5 requires the sequence each time
the supplies turn on.

I had 10 kΩ there before. Against the 100 kΩ feed, that held EN at 0.45 V, so
the 3.3 V rail wouldnt come up. The time constant was 0.9 ms too. I had also
written 10 ms by multiplying 100 kΩ by 100 nF and leaving the bleed out. I
caught both errors on another datasheet read. This still needs a bench check.

### VPP_2V5

Table 4.2 gives VPP_2V5 as 2.30-3.46 V in Master SPI mode, which is what this
board uses with its external flash. The 3.3 V rail sits inside that range.

Note 4 allows 1.8 V only in Slave SPI mode, with HFOSC/LFOSC and the RGB driver
unused. That doesnt apply here.

I put it through a ferrite with its own 100 nF cap. That rail can be lifted
during bring-up if configuration starts acting up.

### VCCPLL

I had VCCPLL on the 3.3 V rail in an earlier revision. That was wrong: Table 4.2
puts it at 1.14-1.26 V, the core-voltage range. Note 1 says VCC and VCCPLL use
the same supply, with an RC filter on VCCPLL.

I run +1V2 through 100 Ω to pin 29, then put 100 nF to GND at the pin. That gives
a 10 µs time constant. There isnt a PLL in this design, but the pin still needs
power. Section 4.2 says every supply pin must be connected, including during
configuration.

---

## FPGA pinout (iCE40UP5K-SG48I)

This is the complete SG48 pin assignment. Pin numbers come from the KiCad 10
symbol `ICE40UP5K-SG48ITR` in `FPGA_Lattice.kicad_sym`. The counts match
FPGA-DS-02008 §5.2 (2 × VCC, 3 × VCCIO, 1 × VCCPLL, 1 × VPP_2V5, 2 dedicated
config, 39 GPIO and no dedicated GND pin, 48 total).

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
| 49 | GND (paddle) | GND | the only ground connection, see below |
| 8 | CRESET_B | - | 10 kΩ to +3V3, test point |
| 7 | CDONE | - | 10 kΩ to +3V3, plus an LED |
| 14 | SPI_SO (IOB_32a) | FLASH_DO | Dedicated config |
| 15 | SPI_SCK (IOB_34a) | FLASH_CLK | Dedicated config |
| 16 | SPI_SS (IOB_35b) | FLASH_CS | Dedicated config, 10 kΩ pull-up |
| 17 | SPI_SI (IOB_33b) | FLASH_DI | Dedicated config |
| 39 | RGB0 | no connect | Constant-current LED driver, not ordinary I/O |
| 40 | RGB1 | no connect | " |
| 41 | RGB2 | no connect | " |

> theres no dedicated ground pin on SG48, ground reaches the die only thru the
> exposed paddle. FPGA-DS-02008 p.45 note: "48-pin QFN package (SG48) requires
> the package paddle to be connected to GND." a badly soldered paddle leaves the
> die with no ground connection at all

pins 39, 40, 41 are the `SB_RGBA_DRV` open-drain constant-current driver outputs,
left unused on purpose, the 16-LED grid wants plain LVCMOS I/O and these behave
differently

### global-clock-capable pins

| Pin | Name | Buffer |
|---|---|---|
| 35 | IOT_46b_G0 | GBUF0 |
| 37 | IOT_45a_G1 | GBUF1 |
| 20 | IOB_25b_G3 | GBUF3 |
| 44 | IOB_3b_G6 | GBUF6 |

The oscillator goes to pin 35. Sending a 12 or 16 MHz clock through general
fabric instead of a global buffer would make timing closure harder.

### user I/O assignment

| Pin | Symbol name | Net |
|---|---|---|
| 35 | IOT_46b_G0 | CLK (from XO) |
| 10 | IOB_18a | RST_N (button) |
| 34 | IOT_44b | UART_TX_O (to FT231X RXD) |
| 36 | IOT_48b | UART_RX_I (from FT231X TXD) |
| 2 | IOB_6a | LED0 |
| 45 | IOB_5b | LED1 |
| 42 | IOT_51a | LED2 |
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

I checked the assignment for a few things:

- no LED on a dedicated config pin (14-17), on CRESET_B (8) or CDONE (7)
- no LED on an RGB driver pin (39-41)
- clock is on a GBIN pin (35)
- pin 20 (G3) left free instead of spent on an LED, so theres a second global
  clock if it ever matters
- LEDs split across banks, 2, 45, 46, 48 on VCCIO_2 (pin 1), 9, 12, 13, 18, 19, 21
  on VCCIO_1 (pin 22) and 25, 26, 27, 32, 38, 42 on VCCIO_0 (pin 33), so 80 mA
  isnt pulled thru one VCCIO pin, 20 / 30 / 30 mA. all three VCCIO pins are +3V3
- LED1 moved from 3 to 45 and LED2 from 23 to 42 in the final routing cleanup.
  both stay in their original banks and use ordinary I/O pins. the south escapes
  close the last two connections without moving the resistor ring
- six LEDs moved off their first-pass pins during routing, LED12 -> 48,
  LED13 -> 46, LED14 -> 38 and LED9 -> 9, LED2 -> 23, LED3 -> 27. all six were
  crossing the package to reach a resistor on the far side, and U1's east column
  was running twelve nets out of twelve 0.5 mm channels, so +3V3 (22, 33), +1V2
  (5, 30) and LED12 had no escape at all. the south row, pads 37-48, was sitting
  entirely unused. bank assignments and the rest of it are in
  [ROUTING.md](ROUTING.md#the-fanout-ran-out-of-room-so-six-pins-moved)
- the UART sits on 34/36 in bank 0, not 6/9 in the config bank. same +3V3 VCCIO
  either way, costs no LED pin and no GBIN pin, and it puts both nets on the face
  that looks at the FT231X instead of the face opposite it.
  [ROUTING.md](ROUTING.md#10-uart_tx_o-and-uart_rx_i) has the measurement

`gateware/morphcpu.pcf` matches this table pin for pin. Update both if you move
one.

### decoupling, exact count

There are seven supply pins, so each gets a 100 nF cap on the same side, with a
via straight to the plane:

| Pin | Rail | Ceramic | Bulk |
|---|---|---|---|
| 5 | +1V2 VCC | 100 nF | share 10 µF |
| 30 | +1V2 VCC | 100 nF | share 10 µF |
| 29 | +1V2 VCCPLL | 100 nF | behind 100 Ω |
| 33 | +3V3 VCCIO_0 | 100 nF | share 4.7 µF |
| 22 | +3V3 SPI_VCCIO1 | 100 nF | 4.7 µF, keep this bank clean, it is POR-monitored |
| 1 | +3V3 VCCIO_2 | 100 nF | share 4.7 µF |
| 24 | +3V3 VPP_2V5 | 100 nF | behind ferrite |

The other caps are 100 nF at the flash and XO, 100 nF + 4.7 µF at both FT231X
VCC and 3V3OUT, plus 1 µF on each ME6211 input and output. That's the datasheet
minimum. I also put 10 µF on the 1.2 V output.

That makes eleven 100 nF caps total. The BOM now matches the count instead of
the old rough estimate of 10-14.

---

## connections

### FT231XS-R, no pinout change

I checked the FT231XS-U to FT231XS-R swap against every assigned pin. The
pinout stays the same.

| | FT231XS-U | FT231XS-R |
|---|---|---|
| LCSC | [C89607](https://www.lcsc.com/product-detail/C89607.html) | [C132160](https://www.lcsc.com/product-detail/C132160.html) |
| Package (per LCSC) | SSOP-20-150mil | SSOP-20-150mil |
| Stock | 0, out of stock | 1,657 |
| Price @1 | $4.47 | $5.9542 |

`FT231XS` is the SSOP-20 die and package. the trailing `-U` / `-R` is FTDI's
packaging suffix, `-U` is tube and `-R` is tape-and-reel, and both LCSC entries
independently report the same SSOP-20-150mil footprint. the QFN variant is a
different base part number (`FT231XQ`) and isnt in play

tape-and-reel is what an SMT line wants anyway. abt $1.50/unit more

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

direction is the classic trap, TXD on the bridge goes to the FPGA's RX

### USB-C receptacle (16-pin, sink only)

| Pin | Net | Notes |
|---|---|---|
| VBUS (A4/A9/B4/B9) | VBUS | Tie all four together |
| GND (A1/A12/B1/B12) | GND | Tie all four together |
| D+ (A6/B6) | USB_DP | Tie both together, USB 2.0 device |
| D- (A7/B7) | USB_DM | Tie both together |
| CC1 (A5) | 5.1 kΩ to GND | Required, advertises a sink |
| CC2 (B5) | 5.1 kΩ to GND | separate resistor, not shared with CC1 |
| SBU1 / SBU2 | no connect | |

CC1 and CC2 each need their own 5.1 kΩ resistor. If you share one or use 10 kΩ,
some hosts and chargers wont power the board.

### ESD protection, USBLC6-2SC6 ([C7519](https://www.lcsc.com/product-detail/C7519.html)), SOT-23-6

U6, between the receptacle and the bridge. the USB-C port is the only bit of this
board anyone touches while its live and the FT231X data pins are the only thing
sitting behind it

| U6 pin | Name | Net | Notes |
|---|---|---|---|
| 1 | I/O1 | USB_DM | From J1 A7/B7 |
| 2 | GND | GND | |
| 3 | I/O2 | USB_DP | From J1 A6/B6 |
| 4 | I/O2 | USB_DP_F | To FT231X USBDP |
| 5 | VBUS | VBUS | Clamps the 5 V rail too |
| 6 | I/O1 | USB_DM_F | To FT231X USBDM |

pins 1/6 are the two ends of one protected line, 3/4 the other, each pair shorted
inside the package. giving each end its own net name is deliberate, it forces the
trace thru the part instead of stubbing off it

3.5 pF max line capacitance, irrelevant at full speed and still fine at high
speed. IEC 61000-4-2 level 4

U6 goes beside J1 on the back, abt 5 mm from the connector's D+/D- pads, cuz
protection downstream of a long trace only protects the trace. the direct line
between U2 and J1 is a 1.2 mm gap, too narrow for SOT-23-6, and the front face is
the LED display, so 5 mm is the best this placement allows. if routing says thats
too long, shift U2 west and reopen the centre channel, dont move the clamp
further out

### SPI configuration flash, W25Q32JVSSIQ ([C179173](https://www.lcsc.com/product-detail/C179173.html))

| Flash pin | FPGA pin | Net |
|---|---|---|
| CS# | 16 (SPI_SS) | FLASH_CS, 10 kΩ pull-up to +3V3 |
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
| 3 | OUT | To FPGA pin 35 (IOT_46b_G0) |
| 4 | VDD | +3V3, 100 nF right at the pad |

the 4-pad arrangement is standard across SMD XOs, this one is 3225
(3.2 x 2.5 mm). pad 1 is a tri-state enable and tying it high thru 10 kΩ keeps
the output on, leaves the option of gating it later

### configuration control

| Net | Treatment |
|---|---|
| CRESET_B (pin 8) | 10 kΩ pull-up to +3V3, plus a test point |
| CDONE (pin 7) | 10 kΩ pull-up to +3V3, plus an LED, lit means configured |
| Reset button | To FPGA pin 10, a user I/O, not CRESET_B |

The button resets the logic but keeps the loaded fabric topology. CRESET_B reloads
the whole bitstream, so I gave it a test point instead of a button.

### LED grid

16 red LEDs, KT-0603R ([C2286](https://www.lcsc.com/product-detail/C2286.html)),
Vf 1.8-2.4 V, laid out as a physical 4×4 matching the fabric map.

```
R = (3.3 V - 2.0 V) / 5 mA = 260 Ω  ->  270 Ω (E24)
```

At 5 mA, the LEDs stay under the 8 mA IOL/IOH limit in Table 4.13. That's about
75 mcd from a part rated 300 mcd at 20 mA, and keeps the grid at 80 mA instead
of 320 mA. If the pins sink current instead, subtract the 0.4 V max VOL and use
200 Ω for the same current.

polarity is a schematic choice and the gateware follows it via `LED_ACTIVE_LOW`
on `morphcpu_top`, so it costs nothing to flip:

| Wiring | Parameter |
|---|---|
| Pin -> resistor -> anode, cathode to GND (pin sources) | `LED_ACTIVE_LOW = 0` (default) |
| +3V3 -> resistor -> anode, cathode -> pin (pin sinks) | `LED_ACTIVE_LOW = 1` |

---

## PCB brief

The board is routed. Net classes, JLC DRC rules and the routing order are in
[ROUTING.md](ROUTING.md), so read that alongside this spec.

| Item | Value |
|---|---|
| Shape | Round, 70 mm diameter (matches `pcb_dia` in [case/morphcpu_case.scad](../case/morphcpu_case.scad)) |
| Layers | 4, 1.6 mm, 1 oz outer - JLCPCB 4 layer stackup |
| Mounting | 4 x M2 on a 58 mm bolt circle (29 mm radius) at 45/135/225/315 deg |
| Min track / clearance | 6 mil / 6 mil |
| Min via | 0.3 mm hole / 0.6 mm pad |

### board size

My first placement pass used a 60 mm board, but 79 footprints wouldnt fit. The
QFN-48, SSOP-20, SOIC-8 and edge-mounted USB-C left no room between the LED
resistor ring and the outer parts. DRC found courtyard overlaps and shorting pads.
The only way to clear them was to put parts over the mounting holes, which isnt
really clearing them.

At 70 mm, there are no courtyard overlaps, shorting pads or clearance violations.
The case is parametric, so I changed `pcb_dia` and `mount_hole_r` and exported it
again.

### placement scheme

The LED grid takes the centre of the front. I put everything else on the back,
in rings around the FPGA:

| Radius | What |
|---|---|
| 0 | FPGA, QFN-48 |
| 6.5 mm | One 100 nF per supply pin - seven of them |
| 9.0 mm | VCCPLL 100R filter and the VPP_2V5 ferrite, just outboard of their caps |
| 11.5 mm | 12 of the LED series resistors, each on its own LED's ray |
| 14.5 mm | The other 4, for the corner LEDs, which share a diagonal with the inner four |
| >= 17 mm | Everything with a real body, on the four cardinal directions |

The diagonals stay clear from r=22 to r=26 for the mounting holes.

The outer parts are grouped by function. USB-C is on the east, with the FT231X
behind it and the USBLC6 beside the connector. The flash and oscillator are on
the west, close to the FPGA to keep SPI and clock runs short. The 3.3 V regulator
and its enable RC are north, the 1.2 V regulator is south.

The 4x4 grid uses a 9 mm pitch and is 27 mm across, matching `led_pitch` in the
case source. Cell 0 is top-left and the order is row-major, same as the fabric
map in [gateware/README.md](../gateware/README.md), so the board matches the demo.

Silkscreen artwork fits in the outer ring past r=20, except around the four
mounting holes and the two front-side parts, SW1 at the top and the CDONE LED at
the bottom.

The paddle is the die's only ground path. It needs a 3x3 or 4x4 group of 0.3 mm
vias into the ground pour. The paste stencil is split into four or five squares
so the FPGA doesnt float during reflow.

The ground pour should be stitched, with no isolated islands.

## JLCPCB assembly notes

| Part | LCSC | Tier | Stock (20 Aug 2026) |
|---|---|---|---|
| ICE40UP5K-SG48I | C2678152 | Extended | 546, lowest in the design, order early |
| FT231XS-R | C132160 | Extended | 1,657 |
| W25Q32JVSSIQ | C179173 | Extended | 39,664 |
| TYPE-C-31-M-12 | C165948 | Extended | 407,730 |
| AP2112K-3.3TRG1 | C51118 | unverified | 70,670 |
| ME6211C12M5G-N | C236672 | Basic | 28,080 |
| KT-0603R | C2286 | Basic | 3,752,200 |
| 1532H4-16000JWPDTSNL | C5383161 | Extended | 147 |
| USBLC6-2SC6 | C7519 | Extended (inferred) | 35,370 |
| TS-1187A-B-A-B | C318884 | Basic (confirmed) | 792,020 |
| CL05B104KO5NNNC 100 nF | C1525 | Basic (confirmed) | 8,423,900 |
| CL05A105KA5NQNC 1 µF | C52923 | Basic (confirmed) | 5,345,900 |
| CL05A475MP5NRNC 4.7 µF | C23733 | Basic (confirmed) | 1,132,850 |
| CL05A106MQ5NUNC 10 µF | C15525 | Basic (confirmed) | 5,949,500 |
| 0402WGF1000TCE 100 Ω | C25076 | Basic (confirmed) | 329,500 |
| RC0402FR-07270RL 270 Ω | C163474 | Extended (confirmed) | 281,900 |
| 0402WGF1001TCE 1 kΩ | C11702 | Basic (confirmed) | 4,014,300 |
| 0402WGF5101TCE 5.1 kΩ | C25905 | Basic (confirmed) | 6,365,200 |
| 0402WGF1002TCE 10 kΩ | C25744 | Basic (confirmed) | 7,032,300 |
| 0402WGF1003TCE 100 kΩ | C25741 | Basic (confirmed) | 8,524,800 |
| BSMD1206-050-6V polyfuse | C883122 | Extended (confirmed) | 36,710 |
| MMZ1608Y601BTA00 ferrite | C136491 | Extended (inferred) | 11,200 |

I pinned the rows below the oscillator on 23 Aug 2026, and their stock counts
are from that date. "Inferred" means the part isnt in JLC's Basic listing or
published Basic-parts export, so it may be Extended. Confirm it in the PCBA quote.

The 1.2 V regulator is Basic. I switched the 3.3 V regulator to an AP2112K after
C82942 went out of stock. JLC's listing doesnt show its tier, so I wont know if
it adds another setup fee until the quote comes back. Both parts are still
SOT-23-5 and share a footprint.

1. Extended parts have a setup fee for each distinct part. Between 7 and 9
   parts may be Extended, depending on C7519 and C136491. For five boards, those
   fees cost more than the BOM. I got nine of the ten passive values into JLC's
   Basic tier. The 270 Ω 0402 resistor has no Basic option at any tolerance.
2. Check each footprint against JLCPCB's land pattern, not the generic KiCad
   library. The USB-C receptacle and QFN-48 paddle are the ones most likely to
   cause trouble.
3. Check stock when ordering. There were 546 FPGAs in stock when I last checked.

---

## post-routing checklist

lives in [ROUTING.md](ROUTING.md#post-routing-checklist) now, with the items the
netclass pass added. tick boxes there

---

## state of the board file

The current `morphcpu.kicad_pcb` has 80 components, four mounting holes, 546
track segments and 193 vias. The 70 mm outline, 1.6 mm thickness, 9 mm LED pitch
and mounting positions are unchanged.

18 Sep 2026, `kicad-cli 10.0.5 pcb drc --refill-zones --schematic-parity --severity-all`:

```
Found 0 violations
Found 0 unconnected items
Found 0 schematic parity issues
```

LED1 and LED2 now leave the south edge of the FPGA from pins 45 and 42.
[ROUTING.md](ROUTING.md#routing-cleanup) has the cleanup details and the pending
bitstream build check.

If you open the board file, check these two things by hand:

- J1 overhang. The USB-C receptacle sits at the +X edge so a plug can seat. Check
  the shell against the board outline, `usb_angle` and the case cutout. A render
  cant tell you if that clearance is right.
- Which parts are on each side. The 16 LEDs, SW1 and the CDONE LED are on the
  front. Everything else is on the back.
