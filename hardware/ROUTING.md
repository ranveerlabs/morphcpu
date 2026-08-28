# routing prep

Copper is placed now, on 4 layers: 666 tracks and 141 vias, four GND pours and
the one F.Cu rule area. What this file still holds is Board Setup, ten net classes,
JLC-shaped DRC minimums, a `morphcpu.kicad_dru` for the rules the dialog cant
express, and the order to route in

current state: **0 DRC violations, 10 unrouted connections**. it was 1 violation
and 17 unrouted before this pass. see [what is left unrouted](#what-is-left-unrouted)
at the bottom - the ten need the U1 fanout rearranged, not just extra copper - the pads are
walled in by neighbouring escapes.

placement did move once after the first pass. the 16 LED resistors went onto
their own LEDs' rays which took the anode ratsnest 405 mm -> 53.4 mm, and the
UART went from pins 6/9 to 34/36. both generator changes not hand edits, whats
at the bottom of the route order covers it.

open `morphcpu.kicad_pcb`, work down [route these in this order](#route-these-in-this-order),
then the [post-routing checklist](#post-routing-checklist)

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
you. every class got a pcb_color too.

verified against the actual board, all 63 real nets land in a class and nothing fell
thru to Default that shouldnt have:

```
CLK (1), GND (1), PWR_1V2 (1), PWR_3V3 (1), PWR_5V (3), PWR_FILT (3),
SPI_FLASH (4), UART (2), USB (4), Default (43)
```

### where the widths came from

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

run it backwards against [DESIGN.md's power tree](DESIGN.md#power-tree) and
**nothing on this board is current-limited**:

| Rail | Current | Width IPC-2221 actually demands |
|---|---|---|
| VBUS, at the 500 mA polyfuse hold | 0.500 A | 0.115 mm (4.55 mil) |
| +3V3 total | 0.110 A | 0.014 mm |
| LED grid alone | 0.080 A | 0.009 mm |
| +1V2 worst case | 0.030 A | 0.002 mm |

IR drop says the same thing. 1 oz copper is 0.4914 mOhm/square, so a 30 mm run of
0.5 mm VBUS at 500 mA drops **14.7 mV**, 30 mm of 0.4 mm +3V3 at 110 mA drops
**4.1 mV**, and 25 mm of 0.4 mm +1V2 at 30 mA drops **0.92 mV** against a 1.14-1.26 V
window. all of it is noise.

so the widths arent thermal and they arent IR. theyre picked so 0.5 mm VBUS has ~2.9x
margin over the fuse it sits behind, so the rails are visually obvious while you hand
route, and so DRC catches you if you ever pull VBUS out of a pad at signal width by
accident.

**neck the escapes.** U1 is a QFN-48 on 0.5 mm pitch with 0.25 mm pads, so the gap
between adjacent pads is 0.25 mm. a 0.4 mm power trace centred on one leaves 0.175 mm
to its neighbour, which is under the 0.2 mm class clearance -> DRC error. come off pins
1, 5, 22, 24, 30 and 33 at 0.2 mm and widen once youre clear of the package. the board
minimum is 0.1524 mm so youve got room to neck.

## DRC rules

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

### what JLC charges extra for

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

current DRC, `kicad-cli 10.0.5 --severity-all`: **0 violations** and **10 unconnected
items** (was 167 unconnected pads before any copper went down). the C20/R27 silk
overlap is gone - C20s reference field moved 1.3 mm in X, both run vertically and
were stacked in Y. zero courtyard overlaps, zero shorting pads, zero clearance errors.

**run DRC with the `.kicad_pro` beside the board.** `kicad-cli pcb drc` on a lone
`.kicad_pcb` silently falls back to *default* Board Setup, not this one, and then
reports every 0.15 mm track as a `track_width` error against a 0.2 mm minimum that
isnt ours. copy `morphcpu.kicad_pro` and `morphcpu.kicad_dru` next to any board you
verify out of tree.

## the freerouting attempt

the *first* attempt was reverted and the board went back to 0 tracks. a later pass
did land - thats where the copper on the board now came from - but keeping the
numbers here so nobody spends another evening rediscovering the setup.

freerouting 2.3.0 needs **Java 25**, not 21. the jar is class file version 69 and
Temurin 21 refuses to load it. winget install of the Temurin MSI wants elevation
and dies with 1602 if nothing is there to click the prompt, so unpack the Adoptium
zip instead, no admin needed.

`pcbnew.ExportSpecctraDSN` and `pcbnew.ImportSpecctraSES` both exist in the python
API, so the round trip is scriptable. `kicad-cli pcb export` has no dsn subcommand
in KiCad 10, dont go looking for one. the DSN carries all ten net classes with
their widths and both via padstacks.

```sh
java -jar freerouting-2.3.0.jar -de hardware/route/morphcpu.dsn \
     -do hardware/route/morphcpu.ses -inc GND -mp 100 --gui.enabled=false
```

32 passes, 8m10s, then it stalled. best score 877.18 hadnt moved since pass 22 and
the optimizer quit after one pass at 0.0000% improvement. what came back:

| | |
|---|---|
| DRC violations | 13 |
| unconnected | 8 |
| tracks | 753 segments + 112 vias |
| F.Cu | 211 segments, 791.9 mm, 45.9% |
| B.Cu | 542 segments, 932.9 mm, 54.1% |

the 13 were 8 `track_width` at 0.150 mm against the 0.1524 minimum, 2
`annular_width` on VBUS vias at a 0.10 mm ring, 2 `via_dangling`, and the usual
cosmetic silk overlap. widths came back off-class in six different values it
invented on the fly, 0.1874 and 0.2502 and 0.3998 and so on.

three things made it not worth keeping. **`-inc GND` doesnt exclude GND**, it
routed it anyway, 339.1 mm across 168 segments, which is the opposite of the pour
plan. the **QFN paddle came out with zero vias in it** and U1-49 was one of the
unconnected, and thats the only ground path to the die. and the 8 unconnected were
real breaks on +3V3, VBUS, +1V2 and VBUS_IN, not pour artifacts.

the front face is the main reason it got reverted. 211 segments and long
diagonals running corner to corner straight thru the LED grid, which is the face
people actually look at. renders are in
[docs/img/routed-3d-top.png](../docs/img/routed-3d-top.png) and
[routed-3d-bottom.png](../docs/img/routed-3d-bottom.png) if you want to see it, the
back was fine, roughly radial fan-out from the QFN.

the DSN in `hardware/route/` is still there and still valid, so if you want another
go at it the export step is done. would want GND actually excluded and a keepout
over the LED grid on F.Cu first.

## route these in this order

hardest first. the LED anodes used to own this list, see [the bottom](#12-the-led-anodes)
for why they dont any more.

### 1. VBUS and VBUS_IN

0.5 mm wide, 137 mm of ratsnest combined, and it spans the entire back layer
which is also the only crowded layer. do it first while the rim is still empty,
cuz a 0.5 mm trace cannot squeeze thru gaps that a 0.2 mm signal left behind.

the awkward bit is that F1, the polyfuse, is at th = 90 deg (north, r = 25-27)
while J1 is at th = 0 deg (east). so VBUS_IN runs ~26 mm around the rim from the
connector up to the fuse before VBUS comes back out and fans to U4 (north,
th = 93 deg), U5 (south, th = 267 deg), FB2 (east, th = 16 deg) and U6 (east,
th = 345 deg). nine pads spread over ~300 deg of arc.

### 2. +3V3

25 pads, 147 mm, back layer only, touches basically every part on the board. and
note the LED current path: the grid sources from FPGA I/O, so the whole **80 mA
of LED drive arrives thru VCCIO pins 1, 22 and 33**. dont neck +3V3 down anywhere
between U4 and those three pins.

### 3. GND

there is **no zone in the file yet**, zero of them, so all 58 GND pads are
currently floating and thats most of the 167 unconnected. pour both layers early
and refill often, every later net changes the pour.

the paddle needs its 3x3 or 4x4 field of 0.3 mm vias per DESIGN.md. those already
match the class geometry.

### 4. LED0 thru LED15, the pin side

193 mm across 16 nets, each a hop from a QFN pad out to its resistor at
r = 11.5 mm, or r = 14.5 mm for the four corners. this is now the biggest signal
group on the board and its a congestion problem, cuz 16 escapes plus 7
decoupling vias plus 6 supply escapes all leave the same 8.7 x 9.8 mm package
footprint.

this total did **not** improve when the resistors moved. 193.4 mm before, 193.4 mm
after. makes sense, the hop length is set by the ring radius and the ring radius
didnt change. the whole win was on the anode side.

### 5. the USB pair

`USB_DP` / `USB_DM` from J1 -> U6, then `USB_DP_F` / `USB_DM_F` from U6 -> U2.
short, 10-14 mm each, but U6 sits at r = 29-32 mm which is outboard of J1 at
r = 26 mm, so the pair goes out to the clamp and back in to the bridge. thats
deliberate, DESIGN.md wants the trace routed thru the part not stubbed off it.

impedance, plainly: **you cannot hit 90 Ohm differential on 2-layer 1.6 mm
FR-4.** a 50 Ohm single-ended microstrip over 1.6 mm of dielectric wants a trace
~2.9 mm wide. not happening on a 70 mm board. the FT231X is full speed, 12 Mbps,
over ~15 mm of trace, so it works untuned and everyone does it. route them short,
symmetric, tightly coupled at the 0.25 mm class gap, over unbroken ground. dont
pretend to tune it.

### 6. CLK

29.5 mm, from X1 pad 3 at r = 25.6 mm / th = 167 deg to U1 pin 35 at r = 4.1 mm /
th = 327 deg. thats near enough diametric, and it crosses the resistor ring and
the decap ring on the way in.

[DESIGN.md](DESIGN.md#placement-scheme) says west holds the flash and the
oscillator "both kept close to the FPGA because the SPI and clock nets care". X1
is at r = 26.8 mm, which makes it the **furthest-out part on the west side**,
outboard of U3 at r = 20 mm. so the clock net is 29.5 mm and no pin choice fixes
that. moving X1 inward would, if you decide its worth reopening placement.

**this got slightly harder, and its the one real cost of the UART move.** pin 35
used to have empty pads either side of it, 34 and 36, so CLK could escape straight
out between them with nothing to cross. both are UART now. CLK still escapes
cleanly outward but it has to cross one UART trace to turn west, so plan on a via
down to the front within a couple of mm of the package and run it west on the
front, which is nearly empty anyway. one via on a 16 MHz clock over a ground pour
is a non-event, but its no longer optional the way it was.

dont let it run parallel to the UART for any distance, and give it more clearance
by hand than the 0.2 mm class rule asks for.

### 7. the flash, FLASH_CLK / CS / DI / DO

15-27 mm each. U1 pins 14-17 sit at th = 102-123 deg (north face) but U3 is at
th = 173-185 deg (west), so they sweep round the northwest quadrant. FLASH_CS and
FLASH_DO come off U3's far pads at r = 23.6 mm so theyre the long two at 27 mm and
22 mm. keep CLK and DO about the same length. its only a config-time bus but its
the bus that decides whether the board boots.

### 8. +1V2

8 pads, 45 mm, U5 (south, th = 267 deg) up to U1 pins 5 and 30 plus the two 100 nF
at r = 6 mm. straightforward, just wide.

### 9. RST_N, CDONE, CDONE_A

front-to-back, 19-51 mm. SW1 is front north at r = 23 mm, D17 is front south at
r = 21 mm, and both their partners are on the back. RST_N is 51 mm of ratsnest
over 4 pads cuz SW1's two pole pairs and R28 at th = 328 deg pull it three
directions at once.

### 10. UART_TX_O and UART_RX_I

**was** 21.0 mm and 26.2 mm crossing the whole board, cuz the bridge is east and
pins 6/9 face west. **now 14.0 mm and 19.2 mm**, both straight shots at U2.

UART moved off pins 6/9 in the config bank onto **34 and 36 in bank 0**, which look
directly at U2. checked for tradeoffs and there is exactly one, the CLK escape
above. everything else came back clean:

| Check | Result |
|---|---|
| VCCIO level | bank 0 is +3V3 via pin 33, same as bank 1 was. no level change |
| LED bank balance | untouched, the 80 mA split across banks is unchanged |
| GBIN pins | 34 and 36 are plain IOT, pin 20 (G3) and pin 37 (G1) stay free |
| config pins | 34/36 are not SPI (14-17), CRESET_B (8) or CDONE (7) |
| RGB driver pins | 39-41 still unused |
| ERC | 0 errors, 0 warnings after the change |

**34 is TX and 36 is RX, not the other way round.** U2 pad 4, its RXD, sits at
y = +0.95 and pad 20, its TXD, at y = +2.86, both on U2's south edge, and pin 36 is
the more southerly FPGA pin. feeding the southern target from the southern pin runs
the two traces parallel. the literal 6->34, 9->36 swap puts them the other way and
they cross about 14 mm out. one line of difference, and not crossing was the whole
point of the change.

pins 6 and 9 are free ordinary I/O now.

### 11. the rest

CC1, CC2, EN_3V3, XO_EN, CRESET_B, FLASH_WP, FLASH_HOLD, FT_RESET, FT_VCC, FT_3V3,
VCCPLL_F, VPP_2V5. all short, all local to one cluster, none over 15 mm. mop-up.

### 12. the LED anodes

**was 405 mm with all 16 chords passing within 3.11 mm of board centre**, ie
straight under the QFN paddle. **now 53.4 mm, and the closest any of them gets to
centre is 5.83 mm**, which is the LED pad itself on the four inner cells, not a
crossing. nothing passes under the package any more.

| | before | after |
|---|---|---|
| total anode ratsnest | 405.0 mm | **53.4 mm** |
| longest single anode | 31.7 mm (LED15_A) | 5.21 mm (LED5_A, LED9_A) |
| shortest | 17.7 mm | 1.49 mm |
| chords within 5 mm of centre | 16 | **0** |
| closest approach to centre | 0.13 mm | 5.83 mm |

each anode is now a radial hop of 1.5 to 5.2 mm from an LED pad to the resistor
directly inboard or outboard of it. route them last, theyre 16 near-identical
short stubs and they will fall out of whatever the pour leaves.

the cause was one line in `scripts/gen_pcb.py`. it sorted the LEDs by angle,
correctly, then handed out ring slots at `k * 22.5` starting from zero. the sorted
list starts at -161.6 deg. so slot 0 went to the LED at -161.6 deg and every
resistor landed 157-180 deg from its partner. the sort was never the problem, the
handout was.

the fix isnt a rotation either, cuz a uniform 16-slot ring cant work here at all.
a 4x4 grid on 9 mm pitch puts the four inner LEDs and the four corner LEDs on the
**same four diagonals**, 45/135/225/315, so eight parts want four rays. the corner
resistors go out to r = 14.5 mm and the other twelve stay on r = 11.5 mm, which
breaks the tie with 3.00 mm between the closest pair.

the LED grid itself did not move. all 16 are still at their exact 9 mm pitch
positions, cell 0 top-left row-major, front layer, each `D(n+1)` still carrying
`LED(n)_A`. verified pad by pad after regeneration, cuz that mapping is what
makes the demo mean anything.

### watch out for gen_pcb.py

`pcbnew.SaveBoard` rewrites `morphcpu.kicad_pro` from the board object's defaults,
which silently wipes all of Board Setup: every net class, every DRC minimum, the
track and via presets. found it by regenerating and watching the previous session's
netclass work disappear. `gen_pcb.py` now lifts `board.design_settings` and
`net_settings` out before the save and puts them back after, and prints
`restored Board Setup: 10 net classes + DRC rules` so you can see it happen.

if that line ever stops appearing, check Board Setup before you route anything.


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
- [ ] **re-check the PCF against the [pin table](DESIGN.md#user-io-assignment)**
      if any pin moved during routing. they agree right now, all 20.
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
- [ ] **tidy silkscreen.** one cosmetic text overlap left, C20 against R27. was
      three before the resistor ring moved. itll move as you adjust parts anyway.

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
- [ ] **confirm Board Setup survived** any `gen_pcb.py` re-run. the script prints
      `restored Board Setup: 10 net classes + DRC rules` when it worked.

## what is left unrouted

10 connections, from `kicad-cli pcb drc`, measured 28 Aug 2026 against the board as
committed. seven of the original seventeen went in this pass: GND fragments at C4.2,
C12.2 and C7.2, plus VCCPLL_F, VBUS_IN, LED2 and LED15. 84 segments and 11 vias, all
of it exact-clearance checked against every foreign copper item before placement, and
nothing already on the board was moved.

| # | Net | From | To | Layers |
|---|---|---|---|---|
| 2 | GND | C5.2 144.3327,95.9255 | main B.Cu pour | B.Cu |
| 4 | GND | C21.2 155.2335,95.3814 | main B.Cu pour | B.Cu |
| 5 | GND | U2.16 172.6000,100.3175 | main B.Cu pour | B.Cu |
| 7 | CDONE | track end 149.2125,119.7045 | U1.7 146.5625,99.7500 | F.Cu -> B.Cu |
| 8 | LED5_A | R6.2 142.2289,92.2289 | D6.2 146.2875,95.5000 | B.Cu -> F.Cu |
| 9 | +3V3 | U1.22 151.7500,96.5625 | U1.33 153.4375,101.2500 | B.Cu |
| 10 | +3V3 | FB1.1 156.1603,94.5690 | U1.22 151.7500,96.5625 | B.Cu |
| 11 | +1V2 | U1.5 146.5625,100.7500 | U1.30 153.4375,99.7500 | B.Cu |
| 12 | +1V2 | track end 155.9286,103.8361 | U1.30 153.4375,99.7500 | B.Cu |
| 16 | LED12 | R13.1 140.1076,109.8924 | U1.27 153.4375,98.2500 | B.Cu |

DRC reports the three GND items at 185.0,100.0, which is the zone bounding-box corner
and tells you nothing. the pad coordinates above come from clustering the GND net
instead.

### what is actually blocking each one

reachability per connection, each net on its own, most permissive legal geometry
the rules allow (0.20 mm track, 0.6/0.3 mm via, 0.2 mm clearance), flood-filled
across all four layers:

| | |
|---|---|
| 2, 4, 5 (GND) | the fragment's B.Cu pocket never touches the main pour and holds no 0.6 mm via site. C5.2 reaches 1956 grid cells, C21.2 579, U2.16 1831 - none of them off B.Cu |
| 9, 10 (+3V3) | U1.22 reaches **51 cells** as the board stands, about 0.13 mm2, walled by the LED8/LED9 escapes and the U1.49 paddle |
| 16 (LED12) | U1.27's pocket is sealed by the LED11 and LED13 escapes |
| 7, 11, 12 | individually routable; they lose to contention for the same channels |

**9, 10 and 16 are not impossible.** an earlier version of this file said they
could not be routed by adding copper at all. that was too strong, and a
whole-fanout group reroute disproved it: rip out U1's entire north row and east
column (17 two-pad nets) and re-solve them together with +3V3, +1V2 and LED12
competing on equal terms from the start, and **all three place**. what defeats the
one-net-at-a-time approach is that the channel assignment predates them - +3V3
takes U1.22's only slot and LED9 at U1.23 then has nowhere to go, at every cut
radius from 1 mm to 8 mm.

so the wall is the *search*, not the copper. the prior routing shows those 17
fanout nets fit together; the group run shows the 3 new ones fit. nothing has yet
shown all 20 fit **simultaneously** - the group run peaked at 15 of 27 and left
12 unplaced, which is worse than the 10 the board already has, so it was not kept.

the underlying pressure is real either way. tightest genuine foreign-copper
clearance in the U1 pad ring is **0.2000 mm exactly**, pads against the U1.49
paddle, the netclass minimum with zero slack. the escapes leave 0.5 mm channels
and a 0.6 mm via needs 0.5 mm of clearance radius, so nothing can change layer
inside a channel. once a channel dead-ends the net is stuck on B.Cu.

finishing this needs either a router that can hold the whole fanout at once, or a
pin swap that gives +3V3 an outer-row pad. **do it in pcbnew by hand** - you can
drag the fanout into a new pattern, which is exactly the move none of the
automated attempts below can make.

### two automated attempts, both short

**a grid maze router** (0.05 mm cells, 4 layers, 45 degrees, exact-clearance gated).
7/17 with nothing ripped up, 12/23 with the fanout ripped, oscillating between 9 and
12 across rounds and never converging. its paths are the problem: 39 segments and 4
vias for one LED net where the existing fanout is compact, so it burns the channel
space it then needs. rip-up-and-retry without a history cost just thrashes - it tore
up exactly the nets it had placed the round before.

**freerouting 2.3.0, second go**, now that the two things the first attempt wanted are
in place: the F.Cu keepout exists and the GND pours are filled. it did not help.

- the DSN *does* carry the keepout correctly, all 16 per-LED windows come through as
  `(window (polygon F.Cu ...))` inside the `wire_keepout`. the LED grid is safe now.
- **`(type fix)` on the wiring is ignored.** marking all 573 existing wires `fix` gave
  a byte-identical score to leaving them `route` - 593.13, 50 unrouted, 106
  violations. freerouting rips the board up regardless, so you cannot ask it to only
  fill in the gaps.
- **GND is the whole cost.** with GND in the netlist a pass took 462-494 s; deleting
  the `(net GND ...)` block from the DSN dropped fanout from 80 s to 3.7 s and a pass
  to ~30 s. `-inc GND` still does nothing, deleting the net block is what works.
- it stalls anyway. GND-excluded it sat at 45-46 unrouted and 72 violations across
  four passes, score bouncing 483.75 -> 492.29 -> 483.75. that is far worse than the
  10 the board already has, so nothing was imported.

the LED grid keepout is a rectangle with **16 windows punched in it**, one per LED, so
a bounding-box test says every anode escape violates it when none of them do. test it
as outline-minus-holes. it also reads `(vias allowed)` - blocking vias with it costs
you every GND stitch site under the grid.
