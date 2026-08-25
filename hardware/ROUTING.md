# routing prep

**still zero tracks and zero zones.** nothing in this pass placed copper or moved a
part. what changed is Board Setup: ten net classes, JLC-shaped DRC minimums, a
`morphcpu.kicad_dru` for the rules the setup dialog cant express, and the list below
of what to route first.

open `morphcpu.kicad_pcb`, work down [route these in this order](#route-these-in-this-order),
then run the [post-routing checklist](#post-routing-checklist).

## net classes

| Class | Track | Clearance | Via pad/drill | Nets |
|---|---|---|---|---|
| PWR_5V | 0.50 mm | 0.2 mm | 0.8 / 0.4 mm | VBUS, VBUS_IN, FT_VCC |
| PWR_3V3 | 0.40 mm | 0.2 mm | 0.8 / 0.4 mm | +3V3 |
| PWR_1V2 | 0.40 mm | 0.2 mm | 0.8 / 0.4 mm | +1V2 |
| GND | 0.40 mm | 0.2 mm | 0.6 / 0.3 mm | GND |
| PWR_FILT | 0.30 mm | 0.2 mm | 0.6 / 0.3 mm | FT_3V3, VCCPLL_F, VPP_2V5 |
| CLK | 0.25 mm | 0.2 mm | 0.6 / 0.3 mm | CLK |
| USB | 0.25 mm | 0.2 mm | 0.6 / 0.3 mm | USB_DP, USB_DM, USB_DP_F, USB_DM_F |
| UART | 0.25 mm | 0.2 mm | 0.6 / 0.3 mm | UART_TX_O, UART_RX_I |
| SPI_FLASH | 0.20 mm | 0.2 mm | 0.6 / 0.3 mm | FLASH_CLK, FLASH_CS, FLASH_DI, FLASH_DO |
| Default | 0.20 mm | 0.2 mm | 0.6 / 0.3 mm | the other 43, mostly LED* and LED*_A |

USB also carries diff pair width 0.25 mm / gap 0.25 mm so the pair tool doesnt fight
you. every class got a pcb_color too, so you can see at a glance which ring youre on.

verified against the actual board, all 63 real nets land in a class and nothing fell
thru to Default that shouldnt have:

```
CLK (1), GND (1), PWR_1V2 (1), PWR_3V3 (1), PWR_5V (3), PWR_FILT (3),
SPI_FLASH (4), UART (2), USB (4), Default (43)
```

### why those widths, checked not guessed

IPC-2221 external-layer formula, `I = 0.048 x dT^0.44 x A^0.725`, A in mil squared,
1 oz = 1.378 mil thick. same formula and constants
[tracewidthcalculator.com](https://tracewidthcalculator.com/) and
[schemalyzer's trace width guide](https://www.schemalyzer.com/en/blog/pcb-design/basics/pcb-trace-width-guide)
publish. at dT = 10 C:

| Width | mil | Max current @ dT=10 C | @ dT=20 C |
|---|---|---|---|
| 0.15 mm | 5.91 | 0.60 A | 0.82 A |
| 0.20 mm | 7.87 | 0.74 A | 1.01 A |
| 0.25 mm | 9.84 | 0.88 A | 1.19 A |
| 0.30 mm | 11.81 | 1.00 A | 1.36 A |
| 0.40 mm | 15.75 | 1.23 A | 1.67 A |
| 0.50 mm | 19.69 | 1.45 A | 1.96 A |

cross-check: schemalyzer's published table says 5 mil -> 0.5 A and 10 mil -> 1 A at
1 oz / 10 C. my 5.91 mil -> 0.60 A and 9.84 mil -> 0.88 A sit either side of those, so
the arithmetic tracks.

now the honest part. run it backwards against [DESIGN.md's power tree](DESIGN.md#power-tree)
and **nothing on this board is current-limited**:

| Rail | Current | Width IPC-2221 actually demands |
|---|---|---|
| VBUS, at the 500 mA polyfuse hold | 0.500 A | 0.115 mm (4.55 mil) |
| +3V3 total | 0.110 A | 0.014 mm |
| LED grid alone | 0.080 A | 0.009 mm |
| +1V2 worst case | 0.030 A | 0.002 mm |

IR drop says the same thing. 1 oz copper is 0.4914 mOhm/square, so a 30 mm run of
0.5 mm VBUS at 500 mA drops **14.7 mV**, 30 mm of 0.4 mm +3V3 at 110 mA drops
**4.1 mV**, and 25 mm of 0.4 mm +1V2 at 30 mA drops **0.92 mV** against a 1.14-1.26 V
window. all noise.

so the widths arent thermal and they arent IR. theyre picked so 0.5 mm VBUS has ~2.9x
margin over the fuse it sits behind, so the rails are visually obvious while you hand
route, and so DRC catches you if you ever pull VBUS out of a pad at signal width by
accident. thats the whole justification, no more than that.

**neck the escapes.** U1 is a QFN-48 on 0.5 mm pitch with 0.25 mm pads, so the gap
between adjacent pads is 0.25 mm. a 0.4 mm power trace centred on one leaves 0.175 mm
to its neighbour, which is under the 0.2 mm class clearance -> DRC error. come off pins
1, 5, 22, 24, 30 and 33 at 0.2 mm and widen once youre clear of the package. the board
minimum is 0.1524 mm so youve got room to neck.

## DRC rules, and what JLC actually charges for

Board Setup minimums now:

| Constraint | Value | Why |
|---|---|---|
| min track width | 0.1524 mm (6 mil) | [DESIGN.md PCB brief](DESIGN.md#pcb-brief) |
| min clearance | 0.1524 mm (6 mil) | same |
| min connection width | 0.1524 mm | catches necked zone connections |
| min via diameter | 0.6 mm | JLC standard tier |
| min through hole | 0.3 mm | JLC standard tier |
| min via annular ring | 0.15 mm | falls out of 0.6 / 0.3 |
| min hole clearance | 0.25 mm | between JLC's via 0.2 and PTH 0.28 |
| min hole to hole | 0.25 mm | ditto, `.kicad_dru` splits it properly |
| copper to edge | 0.5 mm | unchanged, way above JLC's 0.2 |
| min text height | 1.0 mm | JLC floor |
| min text thickness | 0.15 mm | JLC floor |

the two silk numbers are exactly JLC's floor and the board already sits on it, all 168
reference and value fields are 1.0 mm high / 0.15 mm thick. nothing to fix, the rules
are there so a future edit cant drift under.

`morphcpu.kicad_dru` holds the five rules the dialog cant express, all of them scoped
to one item type: via drill 0.3-6.3 mm, via pad 0.6 mm, via-to-via hole spacing 0.2 mm,
pad-to-pad hole spacing 0.45 mm, plated-pad-to-track 0.3 mm.

### the surcharge line

per [jlcpcb.com/capabilities/pcb-capabilities](https://jlcpcb.com/capabilities/pcb-capabilities)
and [schemalyzer's JLCPCB design rules](https://www.schemalyzer.com/en/blog/manufacturing/jlcpcb/jlcpcb-design-rules),
for 2-layer 1 oz FR-4:

- the hard process floor is **0.10 mm / 0.10 mm (4 mil / 4 mil)** track and space, but
  the number you actually want to design to is **5 mil**, which is the economical tier
  for 2-layer. 6 mil is a mil clear of that, so **nothing here triggers a fine trace
  fee**. 3.5 mil is a multilayer-only thing anyway and carries +20% on 4-8 layers.
- **0.15 mm drills cost more.** JLC flags it on the page. 0.3 mm hole / 0.6 mm pad is
  the free combination and thats what every class is set to. dont hand-place a 0.25 mm
  via to squeeze under the FPGA, the `.kicad_dru` will catch it but its easier not to.
- copper to routed board edge only needs 0.2 mm. were at 0.5 mm, so the round outline
  has room even where J1 overhangs.

btw the DRC state is unchanged from before this pass, still the same 3 cosmetic silk
violations and 167 unconnected pads. so the new rules didnt break anything that was
already passing.

## route these in this order

hardest first. the first two items will eat most of the session.

### 1. the 16 LED anodes, and read this before you draw anything

`LED0_A` thru `LED15_A`, 405 mm of ratsnest across 16 nets, and **all 16 chords pass
within 3.11 mm of the board centre**, ie straight under the QFN-48 and its paddle.

| Net | Length | Closest approach to centre |
|---|---|---|
| LED14_A | 26.5 mm | 0.13 mm |
| LED15_A | 31.7 mm | 0.21 mm |
| LED12_A | 30.6 mm | 0.22 mm |
| LED8_A | 25.5 mm | 0.33 mm |
| LED6_A | 18.9 mm | 0.35 mm |
| LED5_A | 17.8 mm | 0.38 mm |
| LED7_A | 27.0 mm | 0.58 mm |
| LED1_A | 26.0 mm | 0.80 mm |
| LED9_A | 17.7 mm | 1.16 mm |
| LED10_A | 18.7 mm | 1.37 mm |
| LED13_A | 25.8 mm | 1.73 mm |
| LED11_A | 26.7 mm | 2.03 mm |
| LED4_A | 25.1 mm | 2.15 mm |
| LED2_A | 26.1 mm | 2.44 mm |
| LED0_A | 29.9 mm | 3.06 mm |
| LED3_A | 31.0 mm | 3.11 mm |

cause is the resistor ring. [DESIGN.md's placement scheme](DESIGN.md#placement-scheme)
says the 270 Ohm resistors sit at r = 11.5 mm, "each roughly outboard of its own LED".
**the board file doesnt do that.** every R sits roughly 180-200 deg around the ring
from its own D:

| | D angle | R angle | apart |
|---|---|---|---|
| LED0 | D1 133 deg | R1 337 deg | 204 deg |
| LED1 | D2 105 deg | R2 293 deg | 188 deg |
| LED2 | D3 69 deg | R3 270 deg | 201 deg |
| LED3 | D4 43 deg | R4 247 deg | 204 deg |
| LED5 | D6 130 deg | R6 315 deg | 185 deg |
| LED12 | D13 227 deg | R13 45 deg | 178 deg |

the ring itself is a clean uniform 22.5 deg ring, its the index-to-angle mapping thats
a permutation that lands each part opposite its partner. matched properly the anodes
would be roughly radial hops of 5-8 mm, call it ~112 mm total. as placed theyre 405 mm.
thats ~290 mm of copper that exists for no reason.

the LEDs are front and the resistors are back so each anode needs a via regardless. the
front layer is nearly empty, only the 17 LEDs and SW1, so on paper you can just run all
16 across the front centre. **dont, or at least know what it costs.** the paddle via
field drops the die's only ground into the front pour at exactly that spot. sixteen
traces thru there shreds the front ground island under the paddle, which is the one
connection [DESIGN.md](DESIGN.md#supply-and-configuration-pins) calls a hard electrical
requirement rather than a thermal nicety.

three ways out, pick one before you start:

- **re-index the resistor ring.** all sixteen are identical 270 Ohm 0402, so its a pure
  positional shuffle, no schematic change, no BOM change. rotate each R to its own D's
  angle and the problem evaporates. this is a placement edit, which is why its not done
  here, but its the right answer and DESIGN.md already claims its true.
- **route the anodes as arcs, not chords.** keep them on the front at r = 11.5-19 mm as
  an annulus and let them go the long way round the paddle. costs length, keeps the
  centre solid.
- **accept it**, keep the paddle island whole on the back pour instead, and stitch hard
  around the edges of the traces. least work, worst ground.

### 2. VBUS and VBUS_IN

0.5 mm wide, 137 mm of ratsnest combined, and it spans the entire back layer which is
also the only crowded layer. do it early while the rim is still empty, cause a 0.5 mm
trace cannot squeeze thru gaps that a 0.2 mm signal left behind.

the awkward bit is that F1, the polyfuse, is at th = 90 deg (north, r = 25-27) while J1
is at th = 0 deg (east). so VBUS_IN runs ~26 mm around the rim from the connector up to
the fuse before VBUS comes back out and fans to U4 (north, th = 93 deg), U5 (south,
th = 267 deg), FB2 (east, th = 16 deg) and U6 (east, th = 345 deg). nine pads spread
over ~300 deg of arc.

### 3. +3V3

25 pads, 147 mm, back layer only, touches basically every part on the board. and note
the LED current path: the grid sources from FPGA I/O, so the whole **80 mA of LED drive
arrives thru VCCIO pins 1, 22 and 33**. dont neck +3V3 down anywhere between U4 and
those three pins.

### 4. GND

there is **no zone in the file yet**, zero of them, so all 58 GND pads are currently
floating and thats most of the 167 unconnected. pour both layers early and refill
often, every later net changes the pour.

the paddle needs its 3x3 or 4x4 field of 0.3 mm vias per DESIGN.md. those already match
the class geometry.

### 5. the USB pair

`USB_DP` / `USB_DM` from J1 -> U6, then `USB_DP_F` / `USB_DM_F` from U6 -> U2. short,
10-14 mm each, but U6 sits at r = 29-32 mm which is *outboard* of J1 at r = 26 mm, so
the pair goes out to the clamp and back in to the bridge. thats deliberate, DESIGN.md
wants the trace routed thru the part not stubbed off it.

impedance, plainly: **you cannot hit 90 Ohm differential on 2-layer 1.6 mm FR-4.** a
50 Ohm single-ended microstrip over 1.6 mm of dielectric wants a trace ~2.9 mm wide.
not happening on a 70 mm board. the FT231X is full speed, 12 Mbps, over ~15 mm of
trace, so it works untuned and everyone does it. route them short, symmetric, tightly
coupled at the 0.25 mm class gap, over unbroken ground. dont pretend to tune it.

### 6. CLK

29.5 mm, from X1 pad 3 at r = 25.6 mm / th = 167 deg to U1 pin 35 at r = 4.1 mm /
th = 327 deg. thats near enough diametric, and it crosses the resistor ring and the
decap ring on the way in.

[DESIGN.md](DESIGN.md#placement-scheme) says west holds the flash and the oscillator
"both kept close to the FPGA because the SPI and clock nets care". X1 is at r = 26.8 mm,
which makes it the **furthest-out part on the west side**, outboard of U3 at r = 20 mm.
so the clock net is 29.5 mm and no pin choice fixes that.

the other GBIN pins dont help much either. pin 37 is at th = 309 deg, pin 20 at
th = 78 deg, pin 44 at th = 258 deg. none of them face west. moving CLK to pin 44 gets
you from 29.5 mm to ~26.0 mm, which isnt worth a schematic change. **moving X1 inward
is**, if you decide its worth reopening placement.

keep it on one layer if you can, give it more clearance by hand than the 0.2 mm class
rule asks for, and dont let it run parallel to the UART for any distance.

### 7. LED0 thru LED15, the pin side

193 mm across 16 nets, each a short radial hop from a QFN pad out to its resistor at
r = 11.5 mm. individually easy, collectively a congestion problem, cause 16 escapes
plus 7 decoupling vias plus 6 supply escapes all leave the same 8.7 x 9.8 mm package
footprint. do these after the anodes so you already know which side of the ring each
resistor ended up on.

### 8. the flash, FLASH_CLK / CS / DI / DO

15-27 mm each. U1 pins 14-17 sit at th = 102-123 deg (north face) but U3 is at
th = 173-185 deg (west), so they sweep round the northwest quadrant. FLASH_CS and
FLASH_DO come off U3's far pads at r = 23.6 mm so theyre the long two at 27 mm and
22 mm. keep CLK and DO about the same length. its only a config-time bus but its the
bus that decides whether the board boots.

### 9. UART_TX_O and UART_RX_I

21 mm and 26 mm, and genuinely annoying: **the bridge is east and the FPGA's UART pins
face west.** U1 pin 9 is at th = 160 deg and pin 6 at th = 184 deg, while U2 pin 4 is at
th = 357 deg and pin 20 at th = 353 deg. both nets have to get from the west face of the
QFN, thru the decap ring, thru the resistor ring, and all the way across to the east rim.

the pin assignment is still soft. [DESIGN.md's post-routing checklist](DESIGN.md#post-routing-checklist)
still lists "update the PCF" as open and the table there supersedes
`gateware/morphcpu.pcf`, so nothing is locked. pins 34 (th = 333 deg) and 36
(th = 321 deg) are free ordinary I/O on the east face and would cut UART_TX_O from 21 mm
to ~14 mm while removing the crossing entirely. thats a schematic edit so its your call,
but its the cheapest win available and its free right now in a way it wont be later.

### 10. +1V2

8 pads, 45 mm, U5 (south, th = 267 deg) up to U1 pins 5 and 30 plus the two 100 nF at
r = 6 mm. straightforward, just wide.

### 11. RST_N, CDONE, CDONE_A

front-to-back, 19-51 mm. SW1 is front north at r = 23 mm, D17 is front south at
r = 21 mm, and both their partners are on the back. RST_N is 51 mm of ratsnest over 4
pads cause SW1's two pole pairs and R28 at th = 328 deg pull it three directions at once.

### 12. the rest

CC1, CC2, EN_3V3, XO_EN, CRESET_B, FLASH_WP, FLASH_HOLD, FT_RESET, FT_VCC, FT_3V3,
VCCPLL_F, VPP_2V5. all short, all local to one cluster, none over 15 mm. mop-up.

## post-routing checklist

working copy. the original lives in [DESIGN.md](DESIGN.md#post-routing-checklist) and
stays there unchanged.

- [ ] **DRC.** run it with the JLCPCB constraints (6 mil track/clearance, 0.3 mm
      via hole). zero errors, and review and justify every warning.
- [ ] **check the paddle.** via field present and connected, paste aperture
      windowed rather than one big square.
- [ ] **verify the 4x4 grid.** measure LED positions, 9 mm pitch, centred, cell 0
      top-left. silkscreen order matches the fabric map.
- [ ] **confirm the artwork annulus** (r = 22-29 mm) is still clear.
- [ ] **update the case.** set `pcb_dia`, `pcb_thickness`, `mount_hole_r`,
      `mount_hole_count`, `mount_hole_angle_offset`, `usb_angle`, `usb_z_centre`
      in `case/morphcpu_case.scad` from the finished board, then `./export.sh`.
- [ ] **update the PCF.** copy the [user I/O assignment](DESIGN.md#user-io-assignment)
      into `gateware/morphcpu.pcf` and delete its "candidate" header. the
      bitstream means nothing until this is done.
- [ ] **build a bitstream.** install the OSS CAD Suite, run `gateware/build.sh`,
      put real LUT/BRAM utilisation and Fmax in `JOURNAL.md`.
- [ ] **re-run `gen_fab.py`.** the fab package already exists but was generated
      from the unrouted board, so it has no copper in it. regenerate after
      routing or you'll ship blank layers.
- [ ] **3D view screenshot** for the README:
      `kicad-cli pcb render` (or KiCad's 3D viewer) -> `docs/img/pcb-3d.png`.
- [ ] **composite render** of case + PCB together for the README hero image.
- [ ] **re-check the BOM** in `docs/BOM.md` against the final board. it's costed
      and all 22 rows are pinned, but quantities come from the schematic and the
      two inferred Extended tiers still need confirming in the quote.
- [ ] **confirm the USB-C overhang** against the board edge and the case cutout
      once the outline is final.
- [ ] **tidy silkscreen.** three cosmetic text overlaps left from the placement
      pass. they'll move as you adjust parts anyway.

new since this pass:

- [ ] **ground zones exist and are filled** on both layers, stitched, no isolated
      islands. there were zero zones in the file when routing started.
- [ ] **every track is on its net class width.** select by net class in pcbnew and
      confirm nothing got drawn at Default width on a power net, and that the QFN
      escapes you necked to 0.2 mm actually widen again once theyre clear.
- [ ] **DRC with `morphcpu.kicad_dru` active.** confirm no via ended up under 0.3 mm
      drill / 0.6 mm pad, thats the JLC surcharge line.
- [ ] **BOM/CPL regeneration picks up any net added while routing.** if you added a
      test point, a stitching pad or a zero-ohm link it needs a designator, a footprint
      and an LCSC part or itll fail the PCBA parse.
- [ ] **decide the LED anode question** and write down which of the three options you
      took, cause the next person will ask.
