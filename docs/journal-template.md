# journal entry template

Copy the block below for each new session. **Be specific, this journal is
evidence of real engineering work.** Concretely, that means:

- Name **exact part numbers** (`ICE40UP5K-SG48I`, not "the FPGA"; `FT231XS-R`,
  not "the USB chip").
- **Link the datasheet page/section** you actually read, with the page or table
  number.
- Record **why** you chose something and **what you rejected**, a decision with
  no alternative considered isn't a decision, it's a default.
- Include **real numbers**: clock frequencies, LUT/BRAM utilisation from
  nextpnr, current draw, trace widths, timing slack, baud rates, resistor
  values and the maths behind them.
- Record **failures and dead ends** in as much detail as successes. What broke,
  the exact error text, what the actual root cause turned out to be.

~~~markdown
## session NNN, YYYY-MM-DD

**focus:** <one-line summary of the session's goal>

### what i did
<!-- Specific actions, not "worked on gateware". Include file and module names. -->
- 
- 

### what i learned
<!-- New technical understanding. Datasheet findings, tool behaviour, gotchas. -->
- 

### design decisions
<!-- One entry per decision. Fill in every field. -->
**decision:** <what I chose>
- **alternatives:** <what else, and why they lost>
- **why:** <the actual reason, cost, pin count, routability, power, availability>
- **source:** <datasheet + page/table/section, app note, or forum thread with link>
- **consequences:** <what this locks in or makes harder later>

### parts and refs touched
| Part / doc | Exact P/N or link | What I needed from it |
|---|---|---|
| | | |

### numbers
<!-- Delete rows that don't apply. -->
| Metric | Value | Notes |
|---|---|---|
| Clock frequency | | |
| LUT usage (nextpnr) | / 5280 | |
| BRAM usage | / 30 | |
| Fmax / timing slack | | |
| Measured current draw | | |
| Baud rate | | |

### what broke
<!-- Exact error text, what I thought the cause was, what it actually was. -->
- **symptom:** 
- **suspected:** 
- **root cause:** 
- **fix:** 

### screenshots
<!-- Save to docs/img/ as session-NNN-description.png and link them here.
     Good subjects: GTKWave waveforms, nextpnr utilisation output, KiCad
     schematic sheets, PCB 3D view, scope traces, the board on the bench,
     LEDs mid-computation. -->
![<caption>](docs/img/session-NNN-<description>.png)
*<Caption: what this shows and why it matters>*

### next session
- [ ] 
- [ ]
~~~
