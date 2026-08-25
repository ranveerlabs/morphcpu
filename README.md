# MorphCPU

_a 70 mm round FPGA board where the program is the wiring, and you can watch it run._

## what it is

its a small round circuit board with a 4x4 grid of red LEDs in the middle and an
iCE40UP5K underneath. plug it into USB and you get a serial port. send it 9 bytes
and youve rewired what the chip computes.

the thing that makes it not-a-processor: theres no instruction pointer, no
fetch, no decode. there are 16 cells sitting in a grid, each one holding a single
operation and a single direction to shove its result. data enters at the west
edge and physically walks across the grid, getting operated on by whatever cell
it lands in. the "program" is the topology, the map of which cell does what and
points where. latency isnt cycles, its distance. a value four cells from the
exit takes four ticks to get out, always, because thats how far it has to walk.

i built it because i wanted to actually see that. dataflow and systolic arrays
are the kind of thing you read about in a paper full of arrows and then never
touch. putting one LED per cell and running the whole fabric at 4 Hz instead of
16 MHz turns it into something you can point at. the grid lights up in the shape
of the computation. thats the entire pitch.

## how it works

each cell holds 4 bits of config. 2 bits pick one of four operations, 2 bits pick
which of its four neighbours gets the answer.

the ops are PASS, INV, ADD and XOR. the directions are north, east, south, west.
thats it, thats the whole instruction set.

where it gets interesting is how a cell decides what to operate *on*. it scans
its four inputs in a fixed order, north then east then south then west. first
valid one it finds becomes `a`. a second valid one becomes `b`. if only one input
showed up, `b` falls back to whatever the cell is already holding.

that one rule is what makes the grid do anything. two streams converging on an
ADD cell get summed. a single stream walking through an ADD cell accumulates
against itself instead. you get accumulators and adders out of the same four
config bits depending purely on what you route into them.

one tick moves every value exactly one cell. so you dont schedule anything, you
just lay out a path and the geometry does the timing for you. data that leaves
the east edge of column 3 comes back to you over UART. anything routed off the
north, south or west edges is dropped on the floor.

the whole topology loads over USB in one 9-byte command. rewriting the program is
sending 9 different bytes. theres no bitstream rebuild, no recompile, nothing to
reflash. the fabric is already in the FPGA, youre just telling it what shape to
be.

## status

| Area | Status | Notes |
|---|---|---|
| concept / architecture | 🟢 done | cell ISA and routing scheme defined and simulated |
| gateware | 🟢 done | 4×4 fabric, UART config loader, LED taps |
| simulation / testbenches | 🟢 done | 18/18 checks passing under Icarus Verilog |
| synthesis / bitstream | 🔴 blocked | flow written, never run, OSS CAD Suite not installed |
| electrical design | 🟢 done | all 8 datasheet items resolved and cited |
| schematic | 🟢 done | ERC clean, 0 errors 0 warnings |
| PCB placement | 🟢 done | 80 footprints, 92 nets, DRC clean of collisions |
| PCB routing | 🔴 blocked | 0 tracks. freerouting tried and reverted, see [hardware/ROUTING.md](hardware/ROUTING.md) |
| gerbers / fab package | 🟢 done | gerbers, drill, BOM and CPL in `hardware/fab_output/` |
| case | 🟢 done | parametric OpenSCAD, STL + 3MF exported |
| BOM | 🟢 done | all 22 rows pinned to LCSC parts and priced |
| costing | 🟢 done | $198.41 all-in, under the $210 tier |
| bring-up | ⚪ not started | needs a real board |

**legend:** ⚪ not started · 🟡 in progress · 🟢 done · 🔴 blocked

### next up

- [ ] route the board by hand, its the one thing standing between here and ordering.
      net classes and DRC rules are set up, see [hardware/ROUTING.md](hardware/ROUTING.md)
- [ ] install the OSS CAD Suite, run `gateware/build.sh` for real LUT and Fmax numbers
- [ ] work the post-routing checklist at the bottom of [hardware/DESIGN.md](hardware/DESIGN.md)
- [ ] order from JLC, confirm the two inferred Extended parts in the quote first

## hardware

| Block | Part | Package | LCSC |
|---|---|---|---|
| FPGA | ICE40UP5K-SG48I | QFN-48-EP (7×7) | [C2678152](https://www.lcsc.com/product-detail/C2678152.html) |
| USB-UART bridge | FT231XS-R | SSOP-20-150mil | [C132160](https://www.lcsc.com/product-detail/C132160.html) |
| SPI config flash | W25Q32JVSSIQ (32 Mbit) | SOIC-8-208mil | [C179173](https://www.lcsc.com/product-detail/C179173.html) |
| USB-C receptacle | TYPE-C-31-M-12 | SMD, 16-pin | [C165948](https://www.lcsc.com/product-detail/C165948.html) |
| ESD array | USBLC6-2SC6 | SOT-23-6 | [C7519](https://www.lcsc.com/product-detail/C7519.html) |
| 3.3 V regulator | ME6211C33M5G-N | SOT-23-5 | [C82942](https://www.lcsc.com/product-detail/C82942.html) |
| 1.2 V regulator | ME6211C12M5G-N | SOT-23-5 | [C236672](https://www.lcsc.com/product-detail/C236672.html) |
| clock | 1532H4-16000JWPDTSNL, 16 MHz XO | SMD3225-4P | [C5383161](https://www.lcsc.com/product-detail/C5383161.html) |
| status LEDs | KT-0603R × 17 | 0603 | [C2286](https://www.lcsc.com/product-detail/C2286.html) |

board: round, 70 mm diameter, 2-layer, JLCPCB SMT assembled, both sides
populated. 5 units costs **$198.41** all-in including the case filament.

full electrical design in **[hardware/DESIGN.md](hardware/DESIGN.md)**, costed
BOM in **[docs/BOM.md](docs/BOM.md)**.

## gateware

| Cell op | Result | | Routing dir |
|---|---|---|---|
| `0` PASS | `a` | | `0` North |
| `1` INV | `~a` | | `1` East |
| `2` ADD | `a + b` | | `2` South |
| `3` XOR | `a ^ b` | | `3` West |

```
        c0    c1    c2    c3
      +-----+-----+-----+-----+
  r0  |  0  |  1  |  2  |  3  |  -> result out
      +-----+-----+-----+-----+
  r1  |  4  |  5  |  6  |  7  |  -> result out
      +-----+-----+-----+-----+
  r2  |  8  |  9  | 10  | 11  |  -> result out
      +-----+-----+-----+-----+
  r3  | 12  | 13  | 14  | 15  |  -> result out
      +-----+-----+-----+-----+
         ^
     data in
```

run the testbenches (only needs Icarus Verilog):

```sh
cd gateware/sim
./run_sims.sh
```

build a bitstream (needs the OSS CAD Suite):

```sh
cd gateware
./build.sh
```

protocol, cell semantics and a worked example: **[gateware/README.md](gateware/README.md)**.

## case

![MorphCPU case, open-face frame with a board fitted](docs/img/case-assembly-preview.png)

parametric OpenSCAD, exported to STL and 3MF: **[case/](case/)**.

```sh
cd case
./export.sh
```

## repo layout

| Path | Contents |
|---|---|
| [gateware/](gateware/) | verilog: cell logic, routing fabric, UART config loader |
| [gateware/sim/](gateware/sim/) | testbenches |
| [hardware/](hardware/) | KiCad project, generators, fab output, electrical design spec |
| [case/](case/) | OpenSCAD source + exported STL/3MF |
| [docs/](docs/) | BOM, images |
| [JOURNAL.md](JOURNAL.md) | build log |

## screenshots

### case render

![Case frame](docs/img/case-frame-preview.png)

_the printable part on its own. open face, 2.4 mm wall, eight lightening holes in
the floor to save filament and print time. 75.4 mm across, 12.9 g, about 26 cents
of PLA._

### PCB placement

![PCB placement, front](docs/img/pcb-placement-front.png)

_front face. the 4x4 LED grid on a 9 mm pitch is the whole point of the board, so
it owns the centre and nothing else is allowed on this side except the reset
button and the CDONE indicator._

![PCB placement, back](docs/img/pcb-placement-back.png)

_back face, everything else in rings around the FPGA. decoupling closest, then
the LED series resistors, then anything with a real body out past 17 mm. the four
diagonals are kept empty for mounting holes._

## building it yourself

fair warning: **the board is not routed yet**. placement is done and DRC is clean
of collisions, but there are zero tracks on it. the gerbers in `hardware/fab_output/`
are real and JLC will quote from them, but do not order until you have routed it,
or you will get 5 very pretty coasters.

if you do build one:

- **order the FPGA early.** 546 units in stock at LCSC when i checked, and thats
  the thinnest row in the whole BOM by a mile. the oscillator at 147 is the next
  worry.
- **confirm C7519 and C136491 in the quote.** i have them down as Extended tier by
  inference, not from a real quote. JLC renders the tier badge in JavaScript so
  the part pages wont tell you. each Extended part costs its own feeder fee, so
  guessing wrong moves the total.
- **the QFN paddle is the only ground connection to the die.** there is no
  dedicated GND pin on the SG48 package. a badly soldered paddle isnt a thermal
  problem, its a dead board. window the paste stencil into four or five squares
  instead of one big aperture.
- **the $210 tier has $11.59 of headroom** at the current $198.41, and shipping
  and duty arent in that number yet. dont add parts casually.

case prints with no supports, flat on its back, 0.2 mm layers and 3 perimeters.
PLA is fine unless its going to live somewhere warm.

## licence

apache 2.0. see [LICENSE](LICENSE).
