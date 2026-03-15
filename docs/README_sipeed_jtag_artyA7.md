
# Arty A7-100T PMOD JA → JTAG Wiring (Sipeed USB‑JTAG Adapter)

This document describes how to connect a **Sipeed USB‑JTAG debugger** to the **PMOD JA header** on the **Digilent Arty A7‑100T** FPGA board.  We used the Sipeed USB-JTAG debugger but you can probably use whatever you can connnect to via through USB.  A link of the device is here [Sipeed USB-JTAG Debugger](https://www.digikey.com/en/products/detail/seeed-technology-co-ltd/114991786/10060366?_gl=1*1xobv3f*_gcl_au*MTI0MzUzNTY1Mi4xNzczNTM2NTQ4).  We utilized the ArtyA7-100T as its relatively cheap and easy to use from [Digilent ArtyA7-100T](https://digilent.com/shop/arty-a7-100t-artix-7-fpga-development-board/?srsltid=AfmBOorbwjRsO-zJlkpczOTosNvzRwnXn1g6ZVx3xiNGtv4Zny58v5Er)

The signals below expose JTAG on the PMOD connector so an external debugger can control a soft processor or debug module implemented in the FPGA.

---

# Vivado Constraints (XDC)

```tcl
set_property -dict { PACKAGE_PIN G13 IOSTANDARD LVCMOS33 } [get_ports { tck }];   # JA1
set_property -dict { PACKAGE_PIN B11 IOSTANDARD LVCMOS33 } [get_ports { tdo }];   # JA2
set_property -dict { PACKAGE_PIN A11 IOSTANDARD LVCMOS33 } [get_ports { tms }];   # JA3
set_property -dict { PACKAGE_PIN D12 IOSTANDARD LVCMOS33 } [get_ports { tdi }];   # JA4
set_property -dict { PACKAGE_PIN D13 IOSTANDARD LVCMOS33 } [get_ports { trst }];  # JA7
set_property -dict { PACKAGE_PIN B18 IOSTANDARD LVCMOS33 } [get_ports { ja[8] }];
set_property -dict { PACKAGE_PIN A18 IOSTANDARD LVCMOS33 } [get_ports { ja[9] }];
set_property -dict { PACKAGE_PIN E15 IOSTANDARD LVCMOS33 } [get_ports { ja[10] }];
```

---

# PMOD JA Pin Layout

The PMOD connector is a **2×6 header**.

Signal pins are **1–4 and 7–10**.  
Pins **5 and 11** are **GND**.  
Pins **6 and 12** provide **3.3V**.

```
Top Row
---------------------------------
JA1   JA2   JA3   JA4   JA5   JA6
TCK   TDO   TMS   TDI   GND   3V3

Bottom Row
---------------------------------
JA7   JA8   JA9   JA10  JA11  JA12
TRST  NC    NC    NC    GND   3V3
```

---

# JTAG Wiring for Sipeed USB‑JTAG

When using a **Sipeed USB‑JTAG adapter**, the debugger must know the voltage level of the target.  
The **3.3V pin is used only as a voltage reference (VTREF)**.

⚠️ **Do NOT connect the 5V pin from the Sipeed debugger.**  
The Arty board already has its own power supply.

| Sipeed USB‑JTAG | Arty PMOD JA | Notes |
|-----------------|--------------|------|
| TCK | JA1 | JTAG clock |
| TMS | JA3 | JTAG mode |
| TDI | JA4 | Data to FPGA |
| TDO | JA2 | Data from FPGA |
| TRST | JA7 | Optional |
| GND | JA5 or JA11 | Required |
| 3.3V | JA6 or JA12 | Voltage reference |
| 5V | **Do NOT connect** | Leave unconnected |

---

# Wiring Example

```
Sipeed USB‑JTAG            Arty A7 PMOD JA
------------------------------------------------
TCK   -------------------> JA1  (tck)
TMS   -------------------> JA3  (tms)
TDI   -------------------> JA4  (tdi)
TDO   <------------------- JA2  (tdo)
TRST  -------------------> JA7  (optional)
GND   -------------------> JA5 or JA11
3.3V  -------------------> JA6 or JA12
5V    -------------------> (leave unconnected)
```

---

# Important Notes

• The FPGA I/O uses **3.3V LVCMOS**.  
• The **3.3V line from the debugger is only used as a voltage reference**.  
• The debugger draws **almost no current from this pin**.  
• Never connect the **5V pin** from the debugger to the PMOD header.  
• `TRST` is optional and may not be required depending on the JTAG software.

---

# Summary

```
JA1  -> TCK
JA2  -> TDO
JA3  -> TMS
JA4  -> TDI
JA7  -> TRST
JA5 / JA11 -> GND
JA6 / JA12 -> 3.3V (VTREF from debugger)
```

This setup allows the **Sipeed USB‑JTAG adapter** to debug logic implemented in the FPGA through the **JA PMOD connector** on the **Arty A7‑100T**.
