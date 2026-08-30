# docs/

[BOM.md](BOM.md) is the costed BOM, 23 rows all pinned to LCSC, $203.73 for 5.
[img/](img/) is renders and screenshots

The machine-readable BOM and CPL live in
[../hardware/fab_output/](../hardware/fab_output/) instead. `gen_fab.py` spits
them out with the gerbers and they have to match the board

## datasheets

- [iCE40 UltraPlus, FPGA-DS-02008](https://www.latticesemi.com/-/media/LatticeSemi/Documents/DataSheets/iCE/iCE40-UltraPlus-Family-Data-Sheet.ashx) - pin summary p.45, Table 4.2 p.29, Table 4.13 p.34, power-up 4.5 p.31
- iCE40 Programming and Configuration, FPGA-TN-02001
- FTDI FT231X
- [W25Q32JV](https://www.winbond.com/hq/product/code-storage-flash-memory/serial-nor-flash/?__locale=en)
- USB-C mech drawing and the Type-C spec for the CC pulldowns. 5.1k each never shared
- [JLCPCB parts](https://jlcpcb.com/parts) - tier listings. part pages render the badge in JS
