# MorphCPU — Build Journal

**Total time: 0h 0m**

<!-- Update the line above after every session. Running total across all sessions. -->

Build log for MorphCPU, a spatially-reconfigurable processor on the Lattice
iCE40UP5K. Submission deadline: **21 Aug 2026**.

Every work chunk gets its own entry using the template at the bottom of this
file. Entries 002–006 are all the same working day, split by what was actually
built, so time can be attributed per chunk rather than guessed at afterwards.

---

## Session index

| # | Date | Time | Focus |
|---|---|---|---|
| 001 | 2026-08-18 | _fill in_ | Repo + project setup |
| 002 | 2026-08-18 | _fill in_ | Fabric RTL + fabric testbench |
| 003 | 2026-08-18 | _fill in_ | End-to-end UART testbench, build flow, constraints |
| 004 | 2026-08-18 | _fill in_ | Case, parametric OpenSCAD |
| 005 | 2026-08-18 | _fill in_ | Electrical design spec + BOM |
| 006 | 2026-08-18 | _fill in_ | README restructure |
| 007 | 2026-08-22 | _fill in_ | Datasheet items resolved, schematic, PCB placement |

---

# Sessions

## Session 007 - 2026-08-22

**Time spent:** _fill in_ &nbsp;&nbsp;|&nbsp;&nbsp; **Running total:** _fill in_
**Focus:** Closing the eight blocking datasheet items, schematic capture, PCB placement

### What I did
- Resolved all eight open items in `hardware/DESIGN.md` against
  FPGA-DS-02008-2.0 and the KiCad `ICE40UP5K-SG48ITR` symbol, with a citation
  per item. Full SG48 pin table now in DESIGN.md.
- Chose the oscillator: 1532H4-16000JWPDTSNL (LCSC C5383161), 16 MHz active XO.
  Applied the clock change through the gateware, PCF and build script.
- Generated the KiCad schematic from a netlist transcribed out of DESIGN.md.
  **ERC: 0 errors, 0 warnings** with `--severity-all`.
- Generated first-pass PCB placement via the `pcbnew` Python API. 79 footprints,
  90 nets, 0 tracks. Zero courtyard overlaps, zero shorting pads.
- Grew the board from 60 mm to 70 mm because the part count would not fit, and
  followed the change through the case parameters.

### What I learned
_(fill in)_

### Design decisions

**Decision:** Both regulators fed from 5 V in parallel, with an RC delay on the 3.3 V enable
- **Alternatives considered:** The original cascade 5V -> 3V3 -> 1V2, which is simpler and one fewer rail off USB.
- **Rationale:** DS section 4.5 requires VCC and VCCPLL up first, then SPI_VCCIO1, then VPP_2V5. The cascade brings 3.3 V up first - exactly backwards. Since every 3.3 V consumer on the FPGA is sequenced after VCC, the rule collapses to "1.2 V must reach 0.5 V before 3.3 V is applied".
- **Source:** FPGA-DS-02008-2.0 section 4.5 Power-up Supply Sequence, p.31; section 4.4 for which rails the POR monitors.
- **Consequences / risks:** The 3.3 V regulator now needs an enable pin, so AMS1117-3.3 is out. 1.2 V from 5 V dissipates ~114 mW in a SOT-23-5, about a 28 C rise.

**Decision:** 16 MHz oscillator instead of 12 MHz
- **Alternatives considered:** 12 MHz C7503622 (9 in stock), 12 MHz TCXO C2451123 (1 in stock, $5.94).
- **Rationale:** 147 in stock against 9, cheaper, smaller package. The system clock is a gateware parameter, not a fixed requirement.
- **Source:** LCSC stock checked 20 Aug 2026.
- **Consequences / risks:** UART divisor becomes 139 (0.08% error) rather than 104 (0.16%) - slightly better. Fabric tick divider rescaled to hold 4 Hz.

**Decision:** Board grown from 60 mm to 70 mm
- **Alternatives considered:** Staying at 60 mm and packing tighter.
- **Rationale:** 60 mm produced courtyard overlaps and shorting pads that could only be cleared by putting parts over the mounting holes. 70 mm clears everything with margin.
- **Consequences / risks:** Case parameters followed in two numbers. Slightly more PCB area cost, which is negligible.

### Parts & references touched this session

| Part / doc | Exact P/N or link | What I needed from it |
|---|---|---|
| Datasheet | FPGA-DS-02008-2.0 | Pin summary p.45, Table 4.2 p.29, Table 4.13 p.34, section 4.5 p.31 |
| KiCad symbol | `ICE40UP5K-SG48ITR` in FPGA_Lattice.kicad_sym | SG48 package pin numbers |
| Oscillator | 1532H4-16000JWPDTSNL / LCSC C5383161 | 16 MHz, 1.8-3.3 V, HCMOS, SMD3225-4P, $0.36, 147 stock |
| 3.3 V LDO | ME6211C33M5G-N / LCSC C82942 | 500 mA, CE pin, Basic tier, $0.053 |
| 1.2 V LDO | ME6211C12M5G-N / LCSC C236672 | 300 mA, CE pin, $0.0606 |

### Numbers

| Metric | Value | Notes |
|---|---|---|
| FPGA supply pins | 7 | 2 VCC, 3 VCCIO, VCCPLL, VPP_2V5 - so 7 x 100 nF |
| Dedicated GND pins | **0** | Ground reaches the die only via the exposed paddle |
| LED drive | 5 mA of an 8 mA ceiling | LVCMOS33 IOL/IOH, Table 4.13 |
| Schematic | 87 symbols, 90 nets, 257 pins | ERC 0/0 |
| PCB | 79 footprints, 0 tracks | DRC: 0 courtyard, 0 shorting, 0 clearance |
| Board | 70 mm dia, 2 layer | LED grid 9 mm pitch, 27 mm across |

### What broke / dead ends
- **Symptom:** `kicad-cli` reported only "Failed to load schematic", no detail.
- **Actual root cause:** `ME6211C12M5` only *extends* `ME6211C33M5`. Emitting the parent body under the child's name leaves the nested per-unit sub-symbols named after the parent, which makes the file unloadable. Fixing only the names then trips ERC `lib_symbol_mismatch`, because the properties still read as the parent. The real fix is to embed the derived symbol fully flattened.
- **Fix:** `lib_symbol_node()` in `gen_schematic.py`.

- **Symptom:** `gen_pcb.py` segfaulted with no traceback.
- **Actual root cause:** Calling `footprint.Flip()` on a footprint that had not yet been added to the board. The pcbnew bindings do not check ownership.
- **Fix:** `board.Add(fp)` before `Flip()`.

- **Symptom:** First placement pass had 87 DRC violations including pads shorting across the FPGA.
- **Actual root cause:** The 16 LED series resistors were placed 3.2 mm from each LED, which put them directly on top of the QFN in the centre of the board. Then 60 mm simply was not enough area.
- **Fix:** Moved the resistors to a ring at r=11.5 mm and grew the board to 70 mm.

### Screenshots / photos
![PCB placement, front](docs/img/pcb-placement-front.png)
*(caption to fill in - the 4x4 grid is the front face)*

![PCB placement, back](docs/img/pcb-placement-back.png)
*(caption to fill in)*

### Next session
- [ ] Route the board by hand
- [ ] Work the post-routing checklist at the bottom of hardware/DESIGN.md

---

## Session 006 — 2026-08-18

**Time spent:** _fill in_ &nbsp;&nbsp;|&nbsp;&nbsp; **Running total:** _fill in_
**Focus:** README restructure for the no-AI-prose rule

### What I did
- Stripped the AI-written project description and "how it works" prose out of
  `README.md` and replaced them with marked `WRITE THIS YOURSELF` placeholders.
- Kept the generated content the rules allow: status table, parts table with
  LCSC numbers, grid diagram, commands, repository layout, image embeds.

### What I learned
_(fill in)_

### Design decisions
_(fill in — or delete if this chunk had none)_

### Screenshots / photos
_(none for this chunk)_

### Next session
- [ ] Write the README prose by hand
- [ ] Decide whether the rule extends to the other docs in the repo

---

## Session 005 — 2026-08-18

**Time spent:** _fill in_ &nbsp;&nbsp;|&nbsp;&nbsp; **Running total:** _fill in_
**Focus:** Electrical design specification and costed BOM

### What I did
- Wrote `hardware/DESIGN.md`: power tree, net-by-net connection tables,
  decoupling per power-pin group, PCB brief, JLCPCB assembly notes, and eight
  open datasheet items.
- Wrote `docs/BOM.md` for a 5-unit run. Six parts verified against LCSC with
  real prices and stock; unpinned parts listed with no price.
- Added `LED_ACTIVE_LOW` to `morphcpu_top` so the schematic can pick LED
  polarity without a gateware change.

### What I learned
_(fill in — the two findings below are the ones worth writing up properly)_

### Design decisions

**Decision:** Added a 3.3 V and a 1.2 V regulator that were not in the original plan
- **Alternatives considered:** Running the FPGA from USB 5 V directly — impossible, the UP5K core is 1.2 V and its I/O banks are 3.3 V.
- **Rationale:** USB-C supplies 5 V and nothing in the original parts list produced either rail.
- **Source:** iCE40 UltraPlus Family Data Sheet FPGA-DS-02008, recommended operating conditions. VCC core 1.14–1.26 V, VCCIO_0 LVCMOS33 2.70–3.47 V.
- **Consequences / risks:** Two more parts. 1.2 V LDO fed from 3.3 V rather than 5 V to keep dissipation trivial.

**Decision:** 12 MHz clock is an active oscillator module, not a bare crystal
- **Alternatives considered:** (a) passive crystal + load caps — the iCE40 has no crystal amplifier and no XIN/XOUT pins, so it cannot start one. (b) internal `SB_HFOSC` at 48 MHz ÷4 = 12 MHz, free and zero parts, but roughly ±10% accuracy.
- **Rationale:** 115200 baud UART tolerates about ±2–3% total error. ±10% will not enumerate reliably.
- **Source:** iCE40 Oscillator Usage Guide FPGA-TN-02008 — the family provides only SB_HFOSC (48 MHz, ÷1/2/4/8) and SB_LFOSC (10 kHz).
- **Consequences / risks:** Part changes to a 4-pad SMD 3225 XO; the two load capacitors disappear. Still worth wiring `SB_HFOSC` as a gateware fallback so an unpopulated XO does not brick the board.

**Decision:** Use FT231XS-R rather than the specified FT231XS-U
- **Alternatives considered:** FT231XS-U (LCSC C89607) as originally specified.
- **Rationale:** C89607 is out of stock at LCSC, and `-U` is tube packaging; `-R` is tape-and-reel, which is what SMT assembly wants. Same silicon, same SSOP-20-150mil footprint.
- **Source:** LCSC C89607 (out of stock) vs C132160 (1,657 in stock), checked 18 Aug 2026.
- **Consequences / risks:** None functionally. Costs about $2 more per unit.

### Parts & references touched this session

| Part / doc | Exact P/N or link | What I needed from it |
|---|---|---|
| FPGA | ICE40UP5K-SG48I / LCSC C2678152 | Price $8.564, stock 546, QFN-48-EP(7×7) |
| USB–UART | FT231XS-R / LCSC C132160 | Price $5.9542, stock 1,657 |
| Config flash | W25Q32JVSSIQ / LCSC C179173 | Price $1.6846, stock 39,664 |
| USB-C | TYPE-C-31-M-12 / LCSC C165948 | Price $0.1716, stock 407,730 |
| 3.3 V LDO | AMS1117-3.3 / LCSC C6186 | Price $0.2032, SOT-223, 1 A |
| LED | KT-0603R / LCSC C2286 | Price $0.0075, Vf 1.8–2.4 V, 300 mcd @ 20 mA |
| Datasheet | FPGA-DS-02008 | Rail voltages, VPP_2V5 range |
| Tech note | FPGA-TN-02008 | On-chip oscillators only, no external crystal support |

### Numbers

| Metric | Value | Notes |
|---|---|---|
| BOM subtotal, 5 units | $83.49 | Verified rows only; XO, 1.2 V LDO, passives not yet priced |
| LED current | 5 mA each, 80 mA total | 270 Ω from 3.3 V, Vf ≈ 2.0 V |

### What broke / dead ends
- **Symptom:** Could not read the iCE40 UltraPlus datasheet PDF locally to confirm exact SG48 power-pin counts.
- **Actual root cause:** No PDF rendering tooling installed.
- **Fix:** Left the pin-count-dependent decoupling quantities as an explicitly open item rather than guessing. Eight such items are listed in `DESIGN.md`.

### Screenshots / photos
_(none — add a KiCad schematic screenshot once it exists)_

### Next session
- [ ] Close the 8 open datasheet items
- [ ] Pick the XO and 1.2 V LDO
- [ ] Start the schematic

---

## Session 004 — 2026-08-18

**Time spent:** _fill in_ &nbsp;&nbsp;|&nbsp;&nbsp; **Running total:** _fill in_
**Focus:** Case, parametric OpenSCAD

### What I did
- Wrote `case/morphcpu_case.scad`: slim open-face frame, 65.4 mm OD, 7.8 mm
  tall, four standoff posts, USB-C cutout with an outer relief, eight floor
  vents.
- Exported binary STL and 3MF; both render manifold, genus 12.
- `case/export.sh` regenerates the exports and the preview renders.

### What I learned
_(fill in)_

### Design decisions

**Decision:** Open face with no lid and no light pipe
- **Alternatives considered:** Closed case with a window or a light-pipe array over the LEDs.
- **Rationale:** The LED grid is the entire demo. Anything over it costs brightness and adds an alignment problem for no benefit.
- **Consequences / risks:** Board front is exposed. Acceptable for a desk object.

**Decision:** Every board-derived dimension is a named parameter
- **Rationale:** The PCB does not exist yet, so all seven board dimensions are assumptions. Parameterising them means the finished layout is a seven-number edit and a re-export, not a remodel.
- **Consequences / risks:** Must remember to actually update them. Listed as a table in `case/README.md`.

### Parts & references touched this session

| Part / doc | Exact P/N or link | What I needed from it |
|---|---|---|
| OpenSCAD | 2025.09.07 nightly | CLI export formats |

### Numbers

| Metric | Value | Notes |
|---|---|---|
| Outside diameter | 65.4 mm | 60 mm board + 0.6 fit + 4.8 wall |
| Height | 7.8 mm | 2.0 floor + 3.0 standoff + 1.6 board + 1.2 rim |
| Mesh | 4,769 vertices / 9,582 facets | Manifold, genus 12 |

### What broke / dead ends
- **Symptom:** `openscad -o case.step` failed with "Invalid suffix step".
- **Actual root cause:** OpenSCAD cannot export STEP at all. It is a mesh/CSG modeller; STEP is a B-rep format. Its CLI supports stl, off, wrl, amf, 3mf, csg, dxf, svg, pdf, png only.
- **Fix:** Exported STL and 3MF. Documented the two routes to a STEP file (FreeCAD conversion, giving a tessellated STEP; or rebuilding in a B-rep tool) in `case/README.md`.

### Screenshots / photos
![Case with mock board](docs/img/case-assembly-preview.png)
_(caption to fill in)_

### Next session
- [ ] Update the seven board parameters once the PCB outline is fixed
- [ ] Test print and check the fit clearance

---

## Session 003 — 2026-08-18

**Time spent:** _fill in_ &nbsp;&nbsp;|&nbsp;&nbsp; **Running total:** _fill in_
**Focus:** End-to-end UART testbench, build flow, pin constraints

### What I did
- `sim/tb_morphcpu_top.v`: drives the design only through its UART pins, so it
  tests the wire protocol and config bit packing as well as the fabric. 5/5.
- `sim/run_sims.sh`, `build.sh` (yosys → nextpnr → icepack), `morphcpu.pcf`.
- `gateware/README.md`: protocol table and a worked add-two-numbers example
  that matches the testbench byte for byte.

### What I learned
_(fill in)_

### Design decisions

**Decision:** Fabric tick defaults to 4 Hz, not 12 MHz
- **Rationale:** A hop every 83 ns is invisible. The board exists to be watched.
- **Consequences / risks:** At full tick rate the fabric outruns 115200 baud and results get dropped. That is why the STEP command exists.

### Numbers

| Metric | Value | Notes |
|---|---|---|
| UART | 115200 8N1 | 104 clocks/bit at 12 MHz, 0.16% error |
| Config chain | 64 bits | 16 cells × 4 bits |
| Testbench checks | 5/5 | tb_morphcpu_top |

### What broke / dead ends
- **Symptom:** The end-to-end test timed out; no byte ever came back.
- **Suspected cause:** Config not loading.
- **Actual root cause:** Two separate bugs. (1) `cfg_shift` was a registered output while `cfg_sr` shifted combinationally, so the enable lagged the shifter by a cycle and the first config bit was never captured. (2) `morphcpu_top` sampled `east_out_*` on the tick edge itself, which always captured the pre-tick state — one hop stale, so a result was never latched.
- **Fix:** Made `cfg_shift` combinational; added a one-cycle delayed `tick_d` for sampling the east edge. Neither bug was visible to the fabric-level testbench, which drives the config chain directly and reads the edge after the tick — a good argument for testing through the real interface.

### Screenshots / photos
_(add a GTKWave capture of a value crossing the grid)_

### Next session
- [ ] Install the OSS CAD Suite and run `build.sh` for real utilisation numbers

---

## Session 002 — 2026-08-18

**Time spent:** _fill in_ &nbsp;&nbsp;|&nbsp;&nbsp; **Running total:** _fill in_
**Focus:** Fabric RTL and fabric testbench

### What I did
- `morph_cell.v`, `grid.v`, `uart_rx.v`, `uart_tx.v`, `config_loader.v`,
  `morphcpu_top.v`.
- `sim/tb_grid.v`: 13 checks covering exact per-tick latency, all four ops,
  XOR and ADD convergence, config surviving a data clear, activity taps.

### What I learned
_(fill in)_

### Design decisions

**Decision:** A second converging stream is the ALU's second operand
- **Alternatives considered:** A fixed "neighbour" operand, or an immediate field in the config.
- **Rationale:** Makes ADD/XOR meaningful spatially — two streams meeting in a cell get combined — without spending config bits. A lone stream falls back to the cell's held value, which turns ADD into an accumulator.
- **Consequences / risks:** Operand order depends on the fixed N,E,S,W priority scan. Documented, and asserted in the testbench.

**Decision:** Config chain wired highest-cell-index-first
- **Rationale:** Costs one crossed-over wire in fabric (free) and makes the host byte order natural — byte i holds cells 2i and 2i+1 in ascending order, no reversing.

### Numbers

| Metric | Value | Notes |
|---|---|---|
| Grid | 4×4, 16 cells | 8-bit datapath |
| Config | 4 bits/cell, 64 total | 2 bits op + 2 bits dir |
| Testbench checks | 13/13 | tb_grid |
| LUT usage (nextpnr) | _/ 5280_ | Not yet synthesised |
| Fmax | _fill in_ | Not yet synthesised |

### What broke / dead ends
- **Symptom:** `gateware/rtl/cell.v:32: syntax error` on a module header that looked completely valid.
- **Suspected cause:** Something in the comment header; backtick-quoted words in `//` comments are seen by Icarus's preprocessor and do break parsing, so that was a real find — but not this bug.
- **Actual root cause:** `cell` is a **reserved word** in Verilog-2001. It belongs to the `config`/`design` configuration construct.
- **Fix:** Renamed the module to `morph_cell`.

- **Symptom:** Every fabric test failed with nothing lighting up at all.
- **Actual root cause:** Testbench race, not an RTL bug. Stimulus was driven on the same rising edge the DUT samples, so `tick` was cleared before the design saw it.
- **Fix:** All testbench stimulus now changes on the falling edge.

### Screenshots / photos
_(add a GTKWave capture)_

### Next session
- [ ] Test through the real UART interface, not just the fabric ports

---

## Session 001 — 2026-08-18

**Time spent:** _fill in_ &nbsp;&nbsp;|&nbsp;&nbsp; **Running total:** _fill in_
**Focus:** Repository and project scaffolding

### What I did
- Initialised the repo, folder structure, README, journal, and .gitignore.

### What I learned
_(fill in)_

### Screenshots / photos
_(none)_

### Next session
- [ ] Define the cell opcode + routing-direction encoding

---

# Session entry template

Copy the block below for each new session. **Be specific — this journal is
evidence of real engineering work.** Concretely, that means:

- Name **exact part numbers** (`ICE40UP5K-SG48I`, not "the FPGA"; `FT231XS-R`,
  not "the USB chip").
- **Link the datasheet page/section** you actually read, with the page or table
  number.
- Record **why** you chose something and **what you rejected** — a decision with
  no alternative considered isn't a decision, it's a default.
- Include **real numbers**: clock frequencies, LUT/BRAM utilisation from
  nextpnr, current draw, trace widths, timing slack, baud rates, resistor
  values and the maths behind them.
- Record **failures and dead ends** in as much detail as successes. What broke,
  the exact error text, what the actual root cause turned out to be.

~~~markdown
## Session NNN — YYYY-MM-DD

**Time spent:** Xh Ym &nbsp;&nbsp;|&nbsp;&nbsp; **Running total:** Xh Ym
**Focus:** <one-line summary of the session's goal>

### What I did
<!-- Specific actions, not "worked on gateware". Include file and module names. -->
- 
- 

### What I learned
<!-- New technical understanding. Datasheet findings, tool behaviour, gotchas. -->
- 

### Design decisions
<!-- One entry per decision. Fill in every field. -->
**Decision:** <what I chose>
- **Alternatives considered:** <what else, and why they lost>
- **Rationale:** <the actual reason — cost, pin count, routability, power, availability>
- **Source:** <datasheet + page/table/section, app note, or forum thread with link>
- **Consequences / risks:** <what this locks in or makes harder later>

### Parts & references touched this session
| Part / doc | Exact P/N or link | What I needed from it |
|---|---|---|
| | | |

### Numbers
<!-- Delete rows that don't apply. -->
| Metric | Value | Notes |
|---|---|---|
| Clock frequency | | |
| LUT usage (nextpnr) | / 5280 | |
| BRAM usage | / 30 | |
| Fmax / timing slack | | |
| Measured current draw | | |
| Baud rate | | |

### What broke / dead ends
<!-- Exact error text, what I thought the cause was, what it actually was. -->
- **Symptom:** 
- **Suspected cause:** 
- **Actual root cause:** 
- **Fix:** 

### Screenshots / photos
<!-- Save to docs/img/ as session-NNN-description.png and link them here.
     Good subjects: GTKWave waveforms, nextpnr utilisation output, KiCad
     schematic sheets, PCB 3D view, scope traces, the board on the bench,
     LEDs mid-computation. -->
![<caption>](docs/img/session-NNN-<description>.png)
*<Caption: what this shows and why it matters>*

### Next session
- [ ] 
- [ ]
~~~
