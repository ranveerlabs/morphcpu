# MorphCPU — Build Journal

**Total time: 0h 0m**

<!-- Update the line above after every session. Running total across all sessions. -->

Build log for MorphCPU, a spatially-reconfigurable processor on the Lattice iCE40UP5K.
Submission deadline: **21 Aug 2026**.

Newest entries at the top. Every session gets its own entry using the template at the bottom
of this file.

---

## Session index

| # | Date | Time | Focus |
|---|---|---|---|
| 001 | 2026-08-18 | 0h 0m | Repo + project setup |

---

# Sessions

## Session 001 — 2026-08-18

**Time spent:** 0h 0m &nbsp;&nbsp;|&nbsp;&nbsp; **Running total:** 0h 0m
**Focus:** Repository and project scaffolding

### What I did
- Initialised the repo, folder structure, README, journal, and .gitignore.

### What I learned
- _(fill in)_

### Design decisions
- _(fill in)_

### Screenshots / photos
![Session 001 screenshot](docs/img/session-001-placeholder.png)
<!-- Replace with a real image. Save images to docs/img/ as session-NNN-description.png -->

### Next session
- [ ] Define the cell opcode + routing-direction encoding
- [ ] First single-cell Verilog module + testbench

---

# Session entry template

Copy the block below for each new session. **Be specific — this journal is evidence of real
engineering work.** Concretely, that means:

- Name **exact part numbers** (`iCE40UP5K-SG48ITR`, not "the FPGA"; `FT231XS-R`, not "the USB chip").
- **Link the datasheet page/section** you actually read, with the page or table number.
- Record **why** you chose something and **what you rejected** — a decision with no alternative
  considered isn't a decision, it's a default.
- Include **real numbers**: clock frequencies, LUT/BRAM utilisation from nextpnr, current draw,
  trace widths, timing slack, baud rates, resistor values and the maths behind them.
- Record **failures and dead ends** in as much detail as successes. What broke, the exact error
  text, what the actual root cause turned out to be.

~~~markdown
## Session NNN — YYYY-MM-DD

**Time spent:** Xh Ym &nbsp;&nbsp;|&nbsp;&nbsp; **Running total:** Xh Ym
**Focus:** <one-line summary of the session's goal>

### What I did
<!-- Specific actions, not "worked on gateware". Include file names and module names. -->
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
     Good subjects: GTKWave waveforms, nextpnr utilisation output, KiCad schematic sheets,
     PCB 3D view, scope traces, the board on the bench, LEDs mid-computation. -->
![<caption>](docs/img/session-NNN-<description>.png)
*<Caption: what this shows and why it matters>*

### Next session
- [ ] 
- [ ]
~~~
