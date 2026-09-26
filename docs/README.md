# docs/

[BOM.md](BOM.md) lists the parts and cost for five boards. All 23 rows have an
LCSC part number. [img/](img/) has the renders and screenshots.

The machine-readable BOM and CPL are in
[../hardware/fab_output/](../hardware/fab_output/). `gen_fab.py` exports those
along with the Gerbers, all from the board file.

## datasheets

- [iCE40 UltraPlus, FPGA-DS-02008](https://www.latticesemi.com/-/media/LatticeSemi/Documents/DataSheets/iCE/iCE40-UltraPlus-Family-Data-Sheet.ashx) - pin summary p.45, Table 4.2 p.29, Table 4.13 p.34, power-up 4.5 p.31
- iCE40 Programming and Configuration, FPGA-TN-02001
- FTDI FT231X
- [W25Q32JV](https://www.winbond.com/hq/product/code-storage-flash-memory/serial-nor-flash/?__locale=en)
- USB-C mech drawing and the Type-C spec for the CC pulldowns. 5.1k each never shared
- [JLCPCB parts](https://jlcpcb.com/parts) - tier listings. part pages render the badge in JS
