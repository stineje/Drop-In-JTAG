# Drop-In-JTAG Testbench

## Overview

This repository demonstrates a **Drop-In-JTAG debug infrastructure** that allows a processor or SoC to be halted and inspected through a JTAG interface without modifying the processor datapath. The example testbench shows how to:

1. Run a processor normally
2. Halt execution through JTAG
3. Move the TAP controller to SAMPLE/PRELOAD
4. Scan out internal signals
5. Decode and display processor state

This approach enables lightweight debug visibility through an HDL-based scan chain connected to JTAG.

---

## Architecture Overview

The design separates the processor clock domain from the JTAG debug clock domain.

| Clock | Purpose |
|------|--------|
| clk | System / processor clock |
| tck | JTAG clock driving the TAP controller |

---

## JTAG Interface Signals

Standard JTAG interface pins are used:

| Signal | Description |
|------|-------------|
| tck | Test clock |
| tms | Test mode select |
| tdi | Test data input |
| tdo | Test data output |
| trst | Test reset |

Additional system signals:

| Signal | Description |
|------|-------------|
| sysclk | Processor clock |
| sys_reset | Processor reset |

---

## Testbench Flow

The testbench performs the following steps:

1. Initialize system and JTAG resets.
2. Allow the processor to run until a known memory event occurs.
3. Halt the system through a JTAG command sequence.
4. Move the TAP controller to SAMPLE/PRELOAD.
5. Scan the data register to capture internal processor signals.
6. Display the captured processor state.

---

## Internal Signals Captured

The JTAG scan chain captures the following processor signals:

| Bits | Signal |
|-----|-------|
| [160:129] | ReadDataM |
| [128:97] | WriteDataM |
| [96:65] | DataAdrM |
| [64] | MemWriteM |
| [63:32] | InstrF |
| [31:0] | PCF |

These signals correspond to values inside the processor pipeline and memory stage.

---

## Why Drop-In-JTAG

The term **Drop-In-JTAG** reflects the ability to add debug capability to an existing HDL design with minimal modification. Rather than redesigning the processor, selected internal signals are connected to a scan chain that is accessible through JTAG.

Benefits include:

- Non‑intrusive debug access
- Reusable infrastructure across designs
- Works in FPGA or ASIC environments
- Standardized JTAG interface
- Visibility into internal architectural state

---

## Summary

This example demonstrates how a processor can execute normally while a separate JTAG interface is used to halt execution and inspect internal signals through a scan chain. The approach provides a lightweight and reusable debugging infrastructure suitable for educational processors, FPGA prototypes, and experimental architectures.
