## Drop-In-JTAG.xdc
##
## Project-specific constraints for the Arty A7-100T.
## Only pins used by top.sv are active here.
## For the full board pinout, refer to Arty_Master.xdc.

## ------------------------------------------------------------
## System Clock (100 MHz)
## ------------------------------------------------------------
set_property -dict { PACKAGE_PIN E3  IOSTANDARD LVCMOS33 } [get_ports { sysclk }]; #IO_L12P_T1_MRCC_35 Sch=gclk[100]
create_clock -name sys_clk_pin -period 10.000 -waveform {0 5.000} [get_ports { sysclk }]

## ------------------------------------------------------------
## JTAG (Pmod JA)
##   ja[1]  = tdi   (G13)
##   ja[2]  = tdo   (B11)
##   ja[3]  = trst  (A11)
##   ja[4]  = tms   (D12)
##   ja[10] = tck   (E15)
## ------------------------------------------------------------
set_property -dict { PACKAGE_PIN G13  IOSTANDARD LVCMOS33 } [get_ports { tdi  }]; #IO_0_15        Sch=ja[1]
set_property -dict { PACKAGE_PIN B11  IOSTANDARD LVCMOS33 } [get_ports { tdo  }]; #IO_L4P_T0_15   Sch=ja[2]
set_property -dict { PACKAGE_PIN A11  IOSTANDARD LVCMOS33 } [get_ports { trst }]; #IO_L4N_T0_15   Sch=ja[3]
set_property -dict { PACKAGE_PIN D12  IOSTANDARD LVCMOS33 } [get_ports { tms  }]; #IO_L6P_T0_15   Sch=ja[4]
set_property -dict { PACKAGE_PIN E15  IOSTANDARD LVCMOS33 } [get_ports { tck  }]; #IO_L11P_T1_SRCC_15 Sch=ja[10]
create_clock -name tck_clk_pin -period 100.000 -waveform {0 50.000} [get_ports { tck }]

## Declare TCK and sys_clk as asynchronous clock groups so the timing
## engine does not attempt to analyse cross-domain paths between them.
set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks sys_clk_pin] \
    -group [get_clocks -include_generated_clocks tck_clk_pin]

## ------------------------------------------------------------
## Reset (btn[0])
## ------------------------------------------------------------
set_property -dict { PACKAGE_PIN D9   IOSTANDARD LVCMOS33 } [get_ports { sys_reset }]; #IO_L6N_T0_VREF_16 Sch=btn[0]

## ------------------------------------------------------------
## PHY DEBUG
## ------------------------------------------------------------
set_property -dict { PACKAGE_PIN H5   IOSTANDARD LVCMOS33 } [get_ports { success }]; #IO_L24N_T3_35         Sch=led[4]
set_property -dict { PACKAGE_PIN J5   IOSTANDARD LVCMOS33 } [get_ports { fail    }]; #IO_25_35              Sch=led[5]

## ------------------------------------------------------------
## LEDs
##   led[0] = tck active   (T9  / led[6] on schematic)
##   led[1] = clk_locked   (T10 / led[7] on schematic)
##   led[2] = dm_reset     (F6  / led0_g RGB green)
##   led[3] = bsr_shift    (J4  / led1_g RGB green)
## ------------------------------------------------------------
set_property -dict { PACKAGE_PIN T9   IOSTANDARD LVCMOS33 } [get_ports { led[0] }]; #IO_L24P_T3_A01_D17_14 Sch=led[6]
set_property -dict { PACKAGE_PIN T10  IOSTANDARD LVCMOS33 } [get_ports { led[1] }]; #IO_L24N_T3_A00_D16_14 Sch=led[7]
set_property -dict { PACKAGE_PIN F6   IOSTANDARD LVCMOS33 } [get_ports { led[2] }]; #IO_L19N_T3_VREF_35    Sch=led0_g
set_property -dict { PACKAGE_PIN J4   IOSTANDARD LVCMOS33 } [get_ports { led[3] }]; #IO_L21P_T3_DQS_35     Sch=led1_g


