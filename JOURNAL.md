# morphcpu build journal

**Total time: 1h 47m**

build log. spatially-reconfigurable processor on a small low power fpga. due
**31 aug 2026**. seven sessions 1h 47m of actual keyboard time

most of that went on two things and neither was the fun part. reading the power
up sequence properly and finding out the hard way that 60mm of board is nowhere
near enough for 79 footprints

btw 002 through 006 are all the same day just split by what got built not by the
clock. template's in [docs/journal-template.txt](docs/journal-template.txt)

![board front, the 4x4 led grid](docs/img/pcb-placement-front.png)

*where its at rn. placement done drc clean of collisions zero tracks. routing is
next and its lowk the only thing between here and ordering*

| # | date | time | focus |
|---|---|---|---|
| 001 | 2026-08-18 | 6m | repo + scaffolding |
| 002 | 2026-08-18 | 21m | fabric rtl + fabric testbench |
| 003 | 2026-08-18 | 18m | end to end uart testbench, build flow, constraints |
| 004 | 2026-08-18 | 14m | case, parametric cad |
| 005 | 2026-08-18 | 24m | electrical design spec + bom |
| 006 | 2026-08-18 | 5m | readme restructure |
| 007 | 2026-08-22 | 19m | datasheet items closed, schematic, pcb placement |

---

## session 007 - 2026-08-22

**Time spent:** 19m
**Running total:** 1h 47m
**Focus:** closing the eight blocking datasheet items, schematic, pcb placement

**what i did**

closed all 8 open items in the design spec against the family datasheet + the
symbol lib. one citation each. full 48 pin table lives in the spec now

picked the oscillator and pushed the clock change through gateware, constraints,
build script. generated the schematic off the netlist transcription and erc came
back 0/0 with everything turned on which ngl i did not expect first try

generated first pass placement through the layout api. 79 footprints 90 nets
zero tracks zero courtyard overlaps zero shorting pads. then grew the board
60mm -> 70mm cause it just did not fit, and followed that through the case params

**decisions**

both regulators run off 5v in parallel now with an rc delay on the 3v3 enable.
the obvious way is the cascade 5v -> 3v3 -> 1v2, simpler and one less rail off
usb, but the datasheet wants core + pll up first then the spi bank then the
programming rail, and the cascade brings 3v3 up first which is exactly
backwards. every 3v3 consumer sits after core in the ordering so the whole thing
collapses to one rule, 1v2 has to hit 0.5v before 3v3 shows up. thats in the
power up supply sequence section plus the bit listing which rails the on chip
reset actually watches. downside is the 3v3 reg now needs an enable pin which
killed the part i'd already picked, rip. running 1v2 straight off 5v burns
~114mw in a sot-23-5, abt a 28c rise, fine

went 16mhz on the oscillator instead of 12. the two 12mhz parts i looked at had
9 units and 1 unit in stock, and nothing actually depends on 12, so it wasnt
much of a call. stock of 9 on a hard deadline is how you end up redesigning the
week before submission. uart divisor goes 104 -> 139 so the error drops 0.16% ->
0.08%, got better by accident lol, and the tick divider got rescaled to hold 4hz

board went 60mm -> 70mm. could've stayed at 60 and packed tighter but 60 gave
courtyard overlaps + shorting pads that only cleared if you put parts on top of
the mounting holes, which isnt clearing them. cost two numbers in the case
source and a re export. more board area, cost is nothing

**parts and refs touched**

| part / doc | exact p/n or ref | what i needed |
|---|---|---|
| fpga | ICE40UP5K-SG48I | pin summary, rail voltages, io current ceiling, power up sequence |
| symbol lib | `ICE40UP5K-SG48ITR` | sg48 pin numbers |
| oscillator | 1532H4-16000JWPDTSNL | 16mhz, 1.8-3.3v, hcmos, tri state enable on pad 1 |
| 3v3 ldo | ME6211C33M5G-N | 500ma, has the enable pin the sequencing needs |
| 1v2 ldo | ME6211C12M5G-N | 300ma, same footprint as the 3v3 one |

**numbers**

| metric | value | notes |
|---|---|---|
| supply pins | 7 | 2 core 3 io bank 1 pll 1 programming. so 7x 100nf |
| dedicated gnd pins | **0** | ground only reaches the die thru the exposed paddle |
| led drive | 5ma of an 8ma ceiling | fine |
| schematic | 87 symbols 90 nets 257 pins | erc 0/0 |
| pcb | 79 footprints 0 tracks | 0 courtyard 0 shorting 0 clearance |
| board | 70mm dia 2 layer | grid 9mm pitch 27mm across |

**what broke**

schematic export died with "failed to load schematic" and literally nothing
else, no line no detail. the 1v2 symbol only *extends* the 3v3 one, so emitting
the parent body under the child name leaves the nested per unit sub symbols
still named after the parent and the file wont load. rename just those and it
loads, then trips a symbol mismatch check instead cause the properties still
read as parent. fix is embedding the derived symbol fully flattened, one function

placement generator segfaulted, no traceback nothing. flipping a footprint that
wasnt added to the board yet. bindings dont check ownership they just die. fix
is adding to board then flipping it

first placement pass came back 87 violations incl pads shorting straight across
the fpga. i'd put the 16 led series resistors 3.2mm from each led which parked
the entire ring on top of the qfn in the middle of the board, and 60mm wasnt
enough area anyway. fix is moving the resistors out to a ring at r=11.5mm and
growing the board

**screenshots**

![board front](docs/img/pcb-placement-front.png)
*front face. 4x4 grid on a 9mm pitch owns the centre, nothing else allowed on
this side except the reset button and the done led*

![board back](docs/img/pcb-placement-back.png)
*back face. rings around the fpga, decoupling innermost, anything with a real
body pushed past 17mm, diagonals empty for mounting holes*

![3d render of the placement](docs/img/pcb-3d.png)
*same placement in 3d. worth the check, cell 0 top left thru 15 bottom right row
major so the physical grid reads the same as the fabric map. get that backwards
and the whole demo lies to you*

**next session**
- [ ] route the board by hand
- [ ] work the post routing checklist at the bottom of the design spec

---

## session 006 - 2026-08-18

**Time spent:** 5m
**Running total:** 1h 28m
**Focus:** readme restructure for the no-ai-prose rule

**what i did**

ripped the ai written project description + the how it works section out of the
readme and left marked placeholders. kept the generated stuff the rules do
allow, status table parts table grid diagram commands repo layout image embeds

tiny session and mostly bookkeeping but giving it its own entry cause it changes
what the readme is allowed to contain from here on. thats exactly the kind of
thing you forget three sessions later and then undo by accident

**next session**
- [ ] write the readme prose by hand
- [ ] figure out if the rule covers the other docs too

---

## session 005 - 2026-08-18

**Time spent:** 24m
**Running total:** 1h 23m
**Focus:** electrical design spec and costed bom

**what i did**

wrote the design spec. power tree, net by net tables, decoupling per power pin
group, pcb brief, assembly notes, and 8 open datasheet items i couldnt close yet

wrote the bom for a 5 unit run. six parts verified w real stock, anything
unpinned listed with no price instead of a guess. added a polarity param to the
top level so the schematic can pick led orientation without touching gateware

**what i learned**

the two below are the ones that mattered. this chip has no crystal amp, and the
obvious power cascade is backwards. both changed the parts list and tbh both are
things i'd have got wrong if i'd trusted the reference designs floating around
instead of just reading the datasheet

**decisions**

added two regulators that were not in the plan at all. running the fpga straight
off usb 5v is impossible, core is 1v2 and the io banks are 3v3, and usb-c gives
you 5v so nothing in the original parts list made either rail. idk how i just
didnt think about power. rail numbers are in the recommended operating
conditions table. costs two more parts and thats it

the clock is an active oscillator module not a bare crystal. options were a
passive crystal + load caps, or the internal osc which is free and zero parts
but abt ±10% untrimmed. theres no crystal amp on this family and no xin/xout
pair in this package so it physically cannot start a passive crystal, and 115200
tolerates abt ±2-3% total so ±10% wont enumerate reliably. the oscillator usage
guide says the family gives you the two on chip oscillators and nothing
external. so the part becomes a 4 pad module and the two load caps disappear.
still worth wiring the internal osc as a gateware fallback so an unpopulated
part doesnt brick the board

swapped the usb-uart bridge to the tape and reel variant. the tube packaged one
i originally specified was out of stock, and tube isnt what an assembly line
wants anyway. same silicon same footprint no pin changes, so functionally
nothing changes

**parts and refs touched**

| part / doc | exact p/n or ref | what i needed |
|---|---|---|
| fpga | ICE40UP5K-SG48I | rail voltages, programming rail range |
| usb-uart | FT231XS-R | packaging variant, footprint confirm |
| config flash | W25Q32JVSSIQ | pinout, quad mode pins to tie off |
| usb-c | TYPE-C-31-M-12 | pin map, cc pulldown requirement |
| led | KT-0603R | forward voltage 1.8-2.4v, brightness at 20ma |
| datasheet | family datasheet | rail voltages, programming rail range |
| tech note | oscillator usage guide | on chip oscillators only, no external crystal |

**numbers**

| metric | value | notes |
|---|---|---|
| led current | 5ma each, 80ma total | 270Ω from 3v3, vf abt 2.0v |
| open items | 8 | all pin count or rail voltage dependent |

**what broke**

couldnt read the datasheet pdf locally to confirm the exact supply pin counts,
no pdf tooling installed. so instead of guessing i left every pin count
dependent decoupling qty as an explicitly open item, 8 of them, all listed in
the spec. guessing here quietly propagates into the schematic and then you never
catch it

**screenshots**

![board back, showing the parts this session picked](docs/img/pcb-3d-back.png)
*nothing visual existed this session, its all tables. this is the back of the
board from two sessions later, but its every part the power tree here settled
on, the two regulators, the flash, the oscillator and the bridge, sat where they
ended up. easier to check a parts list against a picture than against a netlist*

**next session**
- [ ] close the 8 open datasheet items
- [ ] pick the osc and the 1v2 reg
- [ ] start the schematic

---

## session 004 - 2026-08-18

**Time spent:** 14m
**Running total:** 59m
**Focus:** case, parametric cad

**what i did**

wrote the case as parametric source. slim open face frame, four standoff posts,
usb-c cutout w an outer relief so a moulded plug boot clears the rim, eight
vents in the floor. exported mesh formats both manifold. export script
regenerates the exports + the preview renders in one go

**decisions**

open face, no lid, no light pipe. could've done a closed case with a window or a
light pipe array over the leds but the grid *is* the demo, and anything over it
costs brightness and adds an alignment problem for zero benefit. board front
ends up exposed which is fine for a desk object

every board derived dimension is a named param. the pcb didnt exist yet so all
seven board dims were assumptions, and parameterising them means the finished
layout is a seven number edit + re export instead of a remodel. only catch is i
have to actually remember to update them, so theyre a table in the case readme
where theyre hard to miss. paid off immediately in 007 when the board grew

**numbers**

| metric | value | notes |
|---|---|---|
| outside dia | 65.4mm | 60 board + 0.6 fit + 4.8 wall. now 75.4, board grew to 70 in 007 |
| height | 7.8mm | 2.0 floor + 3.0 standoff + 1.6 board + 1.2 rim |
| mesh | 4,769 verts / 9,582 facets | manifold genus 12 |

**what broke**

export to step failed with "invalid suffix step". this tool cannot export step
at all ever, its a mesh/csg modeller and step is a boundary rep format so theres
literally nothing to write out. fix is exporting mesh formats instead and
documenting the two real routes to a step file if one is ever needed, both in
the case readme

**screenshots**

![case with a mock board fitted](docs/img/case-assembly-preview.png)
*frame w a mock board dropped in. open face, board sits on four standoff posts,
3mm of air underneath for back side parts*

![the printable frame on its own](docs/img/case-frame-preview.png)
*printable part by itself. 2.4mm wall, eight lightening holes in the floor, no
lid no light pipe cause the grid is meant to be looked at directly*

**next session**
- [ ] update the seven board params once the outline is fixed
- [ ] test print, check the fit clearance

---

## session 003 - 2026-08-18

**Time spent:** 18m
**Running total:** 45m
**Focus:** end to end uart testbench, build flow, pin constraints

**what i did**

wrote an end to end testbench that drives the design *only* thru its uart pins,
so it tests the wire protocol + the config bit packing not just the fabric. 5/5

wrote the sim runner, build script, pin constraints. wrote up the protocol table
and a worked add two numbers example that matches the testbench byte for byte

**decisions**

fabric tick defaults to 4hz not full clock rate. a hop every 83ns is invisible
and the board exists to be watched. tradeoff is that at full tick rate the
fabric outruns the serial link and results get dropped, which is exactly why the
single step command exists

**numbers**

| metric | value | notes |
|---|---|---|
| serial | 115200 8n1 | 0.16% divisor error at the clock i was on then |
| config chain | 64 bits | 16 cells x 4 bits |
| checks | 5/5 | end to end testbench |

**what broke**

end to end test timed out, no byte ever came back. thought it was config not
loading. was actually two bugs stacked which is why it took a while. the shift
enable was a registered output while the shift register shifted combinationally
so the enable lagged a cycle and the first config bit never got captured. and
the top level sampled the east edge on the tick edge itself which always caught
the pre tick state, one hop stale, so a result never latched. fix is making the
enable combinational and adding a one cycle delayed tick for sampling the edge

neither bug was visible to the fabric level testbench cause that one drives the
config chain directly and reads the edge after the tick. good argument for
testing thru the real interface and not just the convenient one

**screenshots**

![led state through the end to end run, rendered from the sim dump](docs/img/sim-003-uart-activity.png)
*leds through the end to end run, every column is a state change. this one is
driven entirely over the serial link, nothing reaching into the hierarchy. fills
in as a triangle rather than a diagonal cause the leds are pulse stretched to
~150ms so a single tick visit stays visible, so the trail hangs around. cells 0
thru 7 light in order which is the worked add example, 0 south into 4 then east
out thru 5 6 7*

**next session**
- [ ] get the synth toolchain installed, run the build for real utilisation numbers

---

## session 002 - 2026-08-18

**Time spent:** 21m
**Running total:** 27m
**Focus:** fabric rtl and fabric testbench

**what i did**

wrote the whole fabric. the cell, the grid + neighbour interconnect, serial rx
and tx, config loader and tick gen, top level. then a fabric testbench, 13
checks, exact per tick latency, all four ops, both convergence cases, config
surviving a data clear, and the activity taps that drive the leds

**decisions**

a second converging stream is the alu's second operand. alternative was a fixed
neighbour operand or an immediate field in the config, but doing it this way
makes add and xor mean something spatially, two streams meeting in a cell get
combined, and it costs zero extra config bits. a lone stream falls back to
whatever the cell already holds which turns add into an accumulator for free.
operand order ends up depending on the fixed n,e,s,w priority scan so thats
documented and asserted in the testbench where it cant drift

config chain is wired highest cell index first. costs one crossed over wire
inside the fabric which is free, and makes the host byte order natural, byte i
holds cells 2i and 2i+1 ascending with nothing to reverse on either end

**numbers**

| metric | value | notes |
|---|---|---|
| grid | 4x4, 16 cells | 8 bit datapath |
| config | 4 bits/cell, 64 total | 2 op + 2 direction |
| checks | 13/13 | fabric testbench |

**what broke**

syntax error on a module header that looked completely valid. first thought was
something in the comment header, and backtick quoted words inside `//` comments
*do* get seen by the preprocessor and *do* break parsing, so that was a real
find, just not this bug. actual cause is that `cell` is a reserved word in
verilog-2001, belongs to the configuration construct. fix is renaming the
module. genuinely annoying to find

then every fabric test failed with nothing lighting up at all. testbench race,
not an rtl bug. stimulus was driven on the same rising edge the design samples
on so the tick got cleared before the design ever saw it. fix is all stimulus
changing on the falling edge

**screenshots**

![activity taps over 28 ticks, rendered from the fabric testbench dump](docs/img/sim-002-grid-activity.png)
*the 16 activity taps, one row per cell, one column per tick. straight off the
sim dump w `vcd_png.js`. every diagonal streak is one value physically walking
east one cell per tick, 0 -> 1 -> 2 -> 3 along the top row and 4 -> 5 -> 6 along
the next. thats the whole idea of the thing in one picture. also the fastest way
to spot a routing bug, a value going the wrong way slopes the wrong direction*

**next session**
- [ ] test thru the real serial interface not just the fabric ports

---

## session 001 - 2026-08-18

**Time spent:** 6m
**Running total:** 6m
**Focus:** repo and scaffolding

**what i did**

initialised the repo, folder structure, readme skeleton, this journal, ignore
file. nothing interesting tbh. but starting the journal at 001 instead of
backfilling it later is lowk the only reason the rest of these entries have any
real detail in them

**next session**
- [ ] define the cell opcode + routing direction encoding

---
