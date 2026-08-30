"""MorphCPU netlist, transcribed from hardware/DESIGN.md.

every net here matches a row in a DESIGN.md connection table. nothing is
improvised. if a connection isnt documented there its not here.

component entry fields:
  ref, lib, sym, value, fp   identification
  unit                       which sub-symbol (multi-unit parts only)
  nets                       {pin number: net name}
  nc                         pins deliberately left unconnected
"""

# net names
GND = "GND"
VBUS = "VBUS"          # 5 V straight off USB-C, after the polyfuse
P3V3 = "+3V3"
P1V2 = "+1V2"
FT3V3 = "FT_3V3"       # FT231X internal LDO output, local to the bridge
VPP = "VPP_2V5"        # 3V3 behind a ferrite, into FPGA pin 24
VCCPLL = "VCCPLL_F"    # 1V2 behind 100R, into FPGA pin 29
EN3V3 = "EN_3V3"       # RC delay node -> 3V3 regulator CE
FT_VCC = "FT_VCC"      # 5 V behind a ferrite, into FT231X VCC

LED_NETS = ["LED%d" % i for i in range(16)]

# FPGA pin -> LED index, from DESIGN.md "User I/O assignment"
#
# LED9/12/13/14 sit on the south row, not the east column or the north row.
# The east column ran twelve nets out of twelve 0.5 mm channels and four of them
# (LED12, LED13, CLK, VCCPLL_F) have destinations on the far side of the board,
# so they crossed the fan twice and +3V3 (22, 33), +1V2 (5, 30) and LED12 had no
# way out at all. A 0.6 mm via needs 1.2 mm of clearance from its neighbours'
# copper while adjacent escape rays are only 0.5 mm apart, so nothing can change
# layer until the fan has spread, and there was nothing left to spread into.
# R10/R13/R14/R15 all sit south or south-west of the package and pads 37-48 were
# entirely unused, so those four move to south pads ordered by their resistors'
# x, which keeps them from crossing:
#     LED12 -> 48 (R13 x=140.1), LED13 -> 46 (R14 x=146.5),
#     LED14 -> 38 (R15 x=153.5)
# LED9 went to the south row too at first, but pad 47 then fought LED12 on pad 48
# for the same south-west corridor, so it sits on pad 9 on the west face instead:
# R10 is at 141.5, 108.5 and pad 9's ray points straight at it.
# LED2 and LED3 are the other two far-side crossers: both sit on the west face
# and both of their resistors are north-east, so they cut clean across the
# package, and LED2's diagonal is what walled in +1V2 at pin 5. They take the
# two north/east pads LED9 and LED12 just vacated:
#     LED2 -> 23 (R3 due north at 153.5, 89.6), LED3 -> 27 (R4 at 159.9, 90.1)
# 46/47/48 are bank 2 (VCCIO_2 = pin 1) and 23/27/38 are bank 0 (VCCIO_0 = pin
# 33), both already +3V3, so no level change. None is a global buffer pin (37 is
# G1, 44 is G6, 20 is G3 and stays free) or an RGB driver (39-41).
LED_PIN_MAP = {
    2: 0,  3: 1,  23: 2, 27: 3, 12: 4, 13: 5, 18: 6, 19: 7,
    21: 8,  9: 9, 25: 10, 26: 11, 48: 12, 46: 13, 38: 14, 32: 15,
}

FP_R = "Resistor_SMD:R_0402_1005Metric"
FP_C = "Capacitor_SMD:C_0402_1005Metric"
FP_LED = "LED_SMD:LED_0603_1608Metric"
FP_FB = "Inductor_SMD:L_0603_1608Metric"

components = []

def add(ref, lib, sym, value, fp, nets, unit=1, nc=None, at=None):
    components.append({
        "ref": ref, "lib": lib, "sym": sym, "value": value, "fp": fp,
        "unit": unit, "nets": nets, "nc": nc or [], "at": at,
    })

FPGA = ("FPGA_Lattice", "ICE40UP5K-SG48ITR", "ICE40UP5K-SG48I",
        "Package_DFN_QFN:QFN-48-1EP_7x7mm_P0.5mm_EP5.6x5.6mm")

# UART on 34/36 not 6/9. U2 sits due east and 6/9 face west.
# TX on 34 and RX on 36 not the other way round, U2 pad 4 is at y=+0.95 and pad
# 20 at y=+2.86 so this way the two traces dont cross
u1_nets = {33: P3V3, 35: "CLK", 34: "UART_TX_O", 36: "UART_RX_I"}
u1_nc = [28, 31, 37, 39, 40, 41, 42, 43]
for pin in (23, 25, 26, 27, 32, 38):
    u1_nets[pin] = LED_NETS[LED_PIN_MAP[pin]]
add("U1", FPGA[0], FPGA[1], FPGA[2], FPGA[3], u1_nets, unit=1, nc=u1_nc)

u2_nets = {
    7: "CDONE", 8: "CRESET_B", 10: "RST_N",
    14: "FLASH_DO", 15: "FLASH_CLK", 16: "FLASH_CS", 17: "FLASH_DI",
    22: P3V3,
}
for pin in (12, 13, 18, 19, 21):
    u2_nets[pin] = LED_NETS[LED_PIN_MAP[pin]]
# 20 stays free, second global clock. 6 and 9 freed up by the UART move
u2_nets[9] = LED_NETS[9]
add("U1", FPGA[0], FPGA[1], FPGA[2], FPGA[3], u2_nets, unit=2, nc=[6, 11, 20])

u3_nets = {1: P3V3}
for pin in (2, 3, 46, 48):
    u3_nets[pin] = LED_NETS[LED_PIN_MAP[pin]]
add("U1", FPGA[0], FPGA[1], FPGA[2], FPGA[3], u3_nets, unit=3,
    nc=[4, 44, 45, 47])

add("U1", FPGA[0], FPGA[1], FPGA[2], FPGA[3],
    {5: P1V2, 24: VPP, 29: VCCPLL, 30: P1V2, 49: GND}, unit=4)

# bridge TXD goes to the FPGA RX, the usual trap
add("U2", "Interface_USB", "FT231XS", "FT231XS-R",
    "Package_SO:SSOP-20_3.9x8.7mm_P0.635mm",
    {15: FT_VCC, 13: FT3V3, 3: FT3V3, 11: "USB_DP_F", 12: "USB_DM_F",
     20: "UART_RX_I", 4: "UART_TX_O", 14: "FT_RESET",
     6: GND, 16: GND},
    nc=[1, 2, 5, 7, 8, 9, 10, 17, 18, 19])

add("U3", "Memory_Flash", "W25Q32JVSS", "W25Q32JVSSIQ",
    "Package_SO:SOIC-8_5.3x5.3mm_P1.27mm",
    {1: "FLASH_CS", 2: "FLASH_DO", 3: "FLASH_WP", 4: GND,
     5: "FLASH_DI", 6: "FLASH_CLK", 7: "FLASH_HOLD", 8: P3V3})

# pullups not strapped to the rail. same level, quad mode stays reachable, and
# ERC stops flagging a bidir pin on a power output
add("R29", "Device", "R", "10k", FP_R, {1: P3V3, 2: "FLASH_WP"})
add("R30", "Device", "R", "10k", FP_R, {1: P3V3, 2: "FLASH_HOLD"})

# same footprint both. 1V2 always on, 3V3 held off by an RC on CE
add("U4", "Regulator_Linear", "ME6211C33M5", "ME6211C33M5G-N",
    "Package_TO_SOT_SMD:SOT-23-5",
    {1: VBUS, 2: GND, 3: EN3V3, 5: P3V3}, nc=[4])

add("U5", "Regulator_Linear", "ME6211C12M5", "ME6211C12M5G-N",
    "Package_TO_SOT_SMD:SOT-23-5",
    {1: VBUS, 2: GND, 3: VBUS, 5: P1V2}, nc=[4])

add("X1", "Oscillator", "ASE-xxxMHz", "1532H4-16000JWPDTSNL",
    "Oscillator:Oscillator_SMD_Abracon_ASE-4Pin_3.2x2.5mm",
    {1: "XO_EN", 2: GND, 3: "CLK", 4: P3V3})

# sink only
add("J1", "Connector", "USB_C_Receptacle_USB2.0_16P", "TYPE-C-31-M-12",
    "Connector_USB:USB_C_Receptacle_HRO_TYPE-C-31-M-12",
    {"A1": GND, "A12": GND, "B1": GND, "B12": GND,
     "A4": "VBUS_IN", "A9": "VBUS_IN", "B4": "VBUS_IN", "B9": "VBUS_IN",
     "A6": "USB_DP", "B6": "USB_DP", "A7": "USB_DM", "B7": "USB_DM",
     "A5": "CC1", "B5": "CC2", "SH": GND},
    nc=["A8", "B8"])

# pins 1/6 are one protected line and 3/4 the other, shorted inside the package.
# separate net names per end force the trace thru the part instead of stubbing
# off it. keep it hard against J1
add("U6", "Power_Protection", "USBLC6-2SC6", "USBLC6-2SC6",
    "Package_TO_SOT_SMD:SOT-23-6",
    {1: "USB_DM", 2: GND, 3: "USB_DP", 4: "USB_DP_F", 5: VBUS,
     6: "USB_DM_F"})

# user I/O not CRESET_B. footprint follows the part, TL3342 is 6.3 x 3.8 pad
# pitch and the TS-1187A JLC stocks is 6.0 x 3.75. looks fine on screen, does
# not solder
add("SW1", "Switch", "SW_Push", "TS-1187A-B-A-B",
    "Button_Switch_SMD:SW_Push_1P1T_XKB_TS-1187A", {1: "RST_N", 2: GND})
add("R28", "Device", "R", "10k", FP_R, {1: P3V3, 2: "RST_N"})

# R = (3.3 - 2.0) / 5mA = 260 -> 270R E24. LED_ACTIVE_LOW = 0
for i in range(16):
    add("R%d" % (i + 1), "Device", "R", "270", FP_R,
        {1: LED_NETS[i], 2: "LED%d_A" % i})
    add("D%d" % (i + 1), "Device", "LED", "KT-0603R", FP_LED,
        {1: GND, 2: "LED%d_A" % i})

add("R17", "Device", "R", "10k", FP_R, {1: P3V3, 2: "CRESET_B"})
add("R18", "Device", "R", "10k", FP_R, {1: P3V3, 2: "CDONE"})
add("R19", "Device", "R", "10k", FP_R, {1: P3V3, 2: "FLASH_CS"})
add("R20", "Device", "R", "10k", FP_R, {1: P3V3, 2: "FT_RESET"})
add("R21", "Device", "R", "10k", FP_R, {1: P3V3, 2: "XO_EN"})

# CDONE indicator, lit means configured
add("R22", "Device", "R", "1k", FP_R, {1: P3V3, 2: "CDONE_A"})
# same part as the grid LEDs, value field says so, so it groups in the BOM
add("D17", "Device", "LED", "KT-0603R", FP_LED, {1: "CDONE", 2: "CDONE_A"})

# two separate 5.1k, never shared
add("R23", "Device", "R", "5k1", FP_R, {1: "CC1", 2: GND})
add("R24", "Device", "R", "5k1", FP_R, {1: "CC2", 2: GND})

# Power entry: polyfuse, then the 3V3 enable delay
add("F1", "Device", "Polyfuse", "500mA", "Fuse:Fuse_1206_3216Metric",
    {1: "VBUS_IN", 2: VBUS})

# 100k/100nF = 10 ms on CE, way longer than 1V2 takes to rise. 10k bleed so CE
# discharges on power-down and the sequence repeats
add("R25", "Device", "R", "100k", FP_R, {1: VBUS, 2: EN3V3})
add("C19", "Device", "C", "100n", FP_C, {1: EN3V3, 2: GND})
add("R26", "Device", "R", "10k", FP_R, {1: EN3V3, 2: GND})

# VCCPLL RC filter from the 1V2 rail (DS Table 4.2 note 1)
add("R27", "Device", "R", "100", FP_R, {1: P1V2, 2: VCCPLL})
add("C20", "Device", "C", "100n", FP_C, {1: VCCPLL, 2: GND})

# Ferrites: VPP_2V5 off 3V3, and FT231X VCC off VBUS
add("FB1", "Device", "FerriteBead", "600R@100M", FP_FB, {1: P3V3, 2: VPP})
add("C21", "Device", "C", "100n", FP_C, {1: VPP, 2: GND})
add("FB2", "Device", "FerriteBead", "600R@100M", FP_FB, {1: VBUS, 2: FT_VCC})

# Decoupling - one 100 nF per supply pin, 11 in total (DESIGN.md)
DECOUPLE = [
    ("C1", P1V2, "FPGA pin 5 VCC"),
    ("C2", P1V2, "FPGA pin 30 VCC"),
    ("C3", P3V3, "FPGA pin 33 VCCIO_0"),
    ("C4", P3V3, "FPGA pin 22 SPI_VCCIO1"),
    ("C5", P3V3, "FPGA pin 1 VCCIO_2"),
    ("C6", P3V3, "flash VCC"),
    ("C7", P3V3, "oscillator Vdd"),
    ("C8", FT_VCC, "FT231X VCC"),
    ("C9", FT3V3, "FT231X 3V3OUT"),
]
for ref, net, _why in DECOUPLE:
    add(ref, "Device", "C", "100n", FP_C, {1: net, 2: GND})
# C_PLL and C_VPP above are the tenth and eleventh.

# Bulk
add("C10", "Device", "C", "10u", FP_C, {1: P1V2, 2: GND})
add("C11", "Device", "C", "4u7", FP_C, {1: P3V3, 2: GND})
add("C12", "Device", "C", "4u7", FP_C, {1: P3V3, 2: GND})
add("C13", "Device", "C", "4u7", FP_C, {1: P3V3, 2: GND})
add("C14", "Device", "C", "4u7", FP_C, {1: FT3V3, 2: GND})
add("C15", "Device", "C", "1u", FP_C, {1: VBUS, 2: GND})
add("C16", "Device", "C", "1u", FP_C, {1: P3V3, 2: GND})
add("C17", "Device", "C", "1u", FP_C, {1: VBUS, 2: GND})
add("C18", "Device", "C", "10u", FP_C, {1: P1V2, 2: GND})

# Power flags.  GND and VBUS_IN have no power-output pin anywhere on them
# (USB-C VBUS/GND pins are passive), so ERC needs telling they are driven.
add("#FLG1", "power", "PWR_FLAG", "PWR_FLAG", "", {1: GND})
add("#FLG2", "power", "PWR_FLAG", "PWR_FLAG", "", {1: "VBUS_IN"})
# VBUS sits behind the polyfuse, VPP_2V5 and FT_VCC behind ferrites, so each
# is its own net with no power-output pin on it.
add("#FLG3", "power", "PWR_FLAG", "PWR_FLAG", "", {1: VBUS})
add("#FLG4", "power", "PWR_FLAG", "PWR_FLAG", "", {1: VPP})
add("#FLG5", "power", "PWR_FLAG", "PWR_FLAG", "", {1: FT_VCC})
