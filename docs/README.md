# docs/

BOM, costing and images.

| File | What it is |
|---|---|
| [BOM.md](BOM.md) | the costed bill of materials. all 22 rows pinned to LCSC parts, plus tier, stock and the full $198.41 breakdown |
| [img/](img/) | journal screenshots, renders and build photos |

the machine-readable BOM and placement files live in
[../hardware/fab_output/](../hardware/fab_output/), not here, because
`gen_fab.py` generates them alongside the gerbers and they have to stay in step
with the board.

datasheet PDFs can go here if they're small. otherwise just link them with the
revision and the date you read it, same as BOM.md does.

## the references worth having open

- [iCE40 UltraPlus family datasheet, FPGA-DS-02008](https://www.latticesemi.com/-/media/LatticeSemi/Documents/DataSheets/iCE/iCE40-UltraPlus-Family-Data-Sheet.ashx) - the one that matters. pin summary p.45, Table 4.2 p.29, Table 4.13 p.34, power-up sequence section 4.5 p.31
- iCE40 Programming and Configuration technical note, FPGA-TN-02001
- FTDI FT231X datasheet
- [W25Q32JV datasheet](https://www.winbond.com/hq/product/code-storage-flash-memory/serial-nor-flash/?__locale=en) - SPI config flash
- USB-C connector mechanical drawing, and the Type-C spec for the CC pull-downs. 5.1k each, never shared
- [JLCPCB parts library](https://jlcpcb.com/parts) - the tier listings, since the part pages render the badge in JS
