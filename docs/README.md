
# Arty A7-100T PMOD JA → JTAG Wiring

This README describes how to connect an **external JTAG debugger** to the **PMOD JA header** on the **Digilent Arty A7-100T** FPGA board.

The configuration below maps JTAG signals to the JA PMOD connector using Vivado constraints.

---

## Vivado Constraints (XDC)

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

These constraints map the JTAG signals to pins on the **PMOD JA connector**.

---

## PMOD JA Connector Layout

The PMOD connector is a **2×6 header**.

Pins **1–4 and 7–10** are signal pins.  
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

## JTAG Signal Mapping

| JTAG Signal | PMOD Pin | FPGA Port |
|-------------|----------|-----------|
| TCK | JA1 | tck |
| TDO | JA2 | tdo |
| TMS | JA3 | tms |
| TDI | JA4 | tdi |
| TRST | JA7 | trst (optional) |
| GND | JA5 or JA11 | Ground |
| VTREF | JA6 or JA12 | 3.3V reference |

---

## Wiring Example

```
External JTAG Adapter        Arty A7 PMOD JA
------------------------------------------------
TCK   ---------------------> JA1  (tck)
TMS   ---------------------> JA3  (tms)
TDI   ---------------------> JA4  (tdi)
TDO   <--------------------- JA2  (tdo)
TRST  ---------------------> JA7  (trst)  [optional]
GND   ---------------------> JA5 or JA11
VTREF ---------------------> JA6 or JA12
```

---

## Important Notes

- **TDO is an output from the FPGA**, so the signal direction is opposite the other JTAG signals.
- All signals use **LVCMOS33 (3.3 V logic)**.
- Do **not drive signals above 3.3 V**.
- `TRST` is optional and may not be required depending on the debugger.
- JA8–JA10 are unused in this configuration and may be repurposed if needed.

---

## Summary

```
JA1  -> TCK
JA2  -> TDO
JA3  -> TMS
JA4  -> TDI
JA7  -> TRST
JA5 / JA11 -> GND
JA6 / JA12 -> 3.3V
```

This configuration allows a standard external JTAG debugger to communicate with FPGA logic through the **JA PMOD connector** on the **Arty A7-100T**.
