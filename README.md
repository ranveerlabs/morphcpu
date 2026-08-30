# MorphCPU

70mm round board, iCE40UP5K on the back and 16 red leds on the front in a 4x4.
send it 9 bytes over usb and the grid computes something else

Its like a systolic array basically. no PC no fetch no decode, 16 cells
each holding an op and a direction and data goes in the west side and gets
mangled by whatever cell it lands on which sounds more complicated than
it is. 4 cells from the exit is 4 ticks, thats the bit i like. runs at 4Hz
cuz at 16MHz theres obviously nothing to look at

wanted one on a desk so i wrote the fabric. then it needed a testbench, then a
board, then a schematic generator cuz i was not drawing 88 symbols by hand,
then a placement generator, then a case, and then the case had to be parametric
cuz the board diameter kept moving anyway still no traces on it

## state

routed. 770 tracks 148 vias across 4 layers, DRC 0 violations, 2 nets still open
and theyre both leds so 14 of the 16 light. leaving it there cuz deadline, the
board powers and configures and boots and talks. why its two and what would close
them is in [hardware/ROUTING.md](hardware/ROUTING.md). freerouting got two goes and
both went in the bin, the first one ran 211 segments straight across the led face

it needed 4 layers in the end. 2 couldnt do it, the resistor ring and the decap
ring both sit inside the F.Cu keepout over the grid so every led escape was stuck
on B.Cu alone

no bitstream either. OSS CAD Suite isnt installed on this machine so build.sh
has literally never run so idk, salt on the timing numbers

sim 18/18, ERC 0/0, BOM $198.41 for 5

## ops

| op | | dir |
|---|---|---|
| `0` PASS `a` | | `0` N |
| `1` INV `~a` | | `1` E |
| `2` ADD `a+b` | | `2` S |
| `3` XOR `a^b` | | `3` W |

4 bits a cell, 2 op 2 dir, the operand pick is like the only weird bit and
[morph_cell.v](gateware/rtl/morph_cell.v) is short enough to just read

```
        c0    c1    c2    c3
      +-----+-----+-----+-----+
  r0  |  0  |  1  |  2  |  3  |  -> out
      +-----+-----+-----+-----+
  r1  |  4  |  5  |  6  |  7  |  -> out
      +-----+-----+-----+-----+
  r2  |  8  |  9  | 10  | 11  |  -> out
      +-----+-----+-----+-----+
  r3  | 12  | 13  | 14  | 15  |  -> out
      +-----+-----+-----+-----+
         ^
      data in
```

east edge comes back over uart. everything else just falls off the board. five
commands total and [gateware/README.md](gateware/README.md) has the actual bytes
plus a worked example

## parts

| | part | pkg | LCSC |
|---|---|---|---|
| FPGA | ICE40UP5K-SG48I | QFN-48-EP 7×7 | [C2678152](https://www.lcsc.com/product-detail/C2678152.html) |
| usb-uart | FT231XS-R | SSOP-20 | [C132160](https://www.lcsc.com/product-detail/C132160.html) |
| flash | W25Q32JVSSIQ | SOIC-8 | [C179173](https://www.lcsc.com/product-detail/C179173.html) |
| usb-c | TYPE-C-31-M-12 | 16pin | [C165948](https://www.lcsc.com/product-detail/C165948.html) |
| esd | USBLC6-2SC6 | SOT-23-6 | [C7519](https://www.lcsc.com/product-detail/C7519.html) |
| 3v3 | ME6211C33M5G-N | SOT-23-5 | [C82942](https://www.lcsc.com/product-detail/C82942.html) |
| 1v2 | ME6211C12M5G-N | SOT-23-5 | [C236672](https://www.lcsc.com/product-detail/C236672.html) |
| clk | 1532H4-16000JWPDTSNL 16MHz | 3225 | [C5383161](https://www.lcsc.com/product-detail/C5383161.html) |
| leds | KT-0603R ×17 | 0603 | [C2286](https://www.lcsc.com/product-detail/C2286.html) |

two regulators, and the 1v2 one has to be up before the 3v3, which is backwards
from the cascade youd reach for first. i would not wing that bit,
[hardware/DESIGN.md](hardware/DESIGN.md) has it with page numbers, money is in
[docs/BOM.md](docs/BOM.md)

## run

```sh
cd gateware/sim && ./run_sims.sh    # iverilog only
cd gateware && ./build.sh           # needs OSS CAD Suite. never run.
cd case && ./export.sh
```

## pics

![case with a board in it](docs/img/case-assembly-preview.png)

![frame](docs/img/case-frame-preview.png)

75.4mm, 12.9g, like 26c of PLA

![front](docs/img/pcb-routed-front.png)

front. 4x4 on 9mm pitch plus the reset button and the CDONE led. no tracks on
this face on purpose, theres an F.Cu keepout over the whole grid

![back](docs/img/pcb-routed-back.png)

back. fpga in the middle, ring of decaps then the resistor ring, and everything
fanning out of a QFN-48 on 0.5mm pitch which is where all the pain was

board was 60mm at first and everything overlapped. the resistor ring also sat
180 out from its own leds for ages, so every single anode trace ran straight
under the QFN paddle, which took embarrassingly long to spot, rip. both sorted

six leds also ended up on different fpga pins than they started on, cuz the east
side of the package ran out of escape room. thats in ROUTING.md too

## if you order it

gerbers in `hardware/fab_output/` are off the routed board now, all four copper
layers with copper actually in them, drill included. two nets are still open tho
so D2 and D3 wont light, read that before you spend money

- **$198.41 was costed at 2 layers and this is 4 now.** i have not requoted it,
  the $11.59 headroom might be gone. requote before you commit to anything
- fpga stock was 546 when i looked. oscillator 147
- C7519 and C136491 tiers are guesses, confirm in the quote
- QFN paddle is the only ground to the die, SG48 has no GND pin at all. window
  the paste stencil

case prints flat, no supports, 0.2mm layers, 3 perimeters

## licence

apache 2.0
