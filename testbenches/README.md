
# Drop-In-JTAG Testbench

## Overview

This repository demonstrates a **Drop-In-JTAG debug infrastructure** that allows internal processor signals to be observed through a JTAG interface without modifying the processor datapath. The example testbench shows how a running processor can be:

1. Executed normally under the system clock
2. Halted through a JTAG command sequence
3. Placed into the JTAG `SAMPLE/PRELOAD` state
4. Scanned to retrieve internal processor signals
5. Decoded and printed for debugging

This approach enables **non‑intrusive hardware debugging** by attaching a scan chain to selected internal signals and accessing them through the JTAG TAP controller.

---

# Architecture Overview

The design separates two clock domains:

| Clock | Purpose |
|------|--------|
| `clk` | System / processor clock |
| `tck` | JTAG test clock driving the TAP controller |

The processor runs normally on `clk`, while debug operations occur through the JTAG interface driven by `tck`.

This separation reflects real hardware debugging systems where the CPU continues operating independently of the debug interface.

---

# JTAG Interface Signals

Standard JTAG signals are used:

| Signal | Description |
|------|-------------|
| `tck` | Test clock |
| `tms` | Test mode select (controls TAP state transitions) |
| `tdi` | Test data input (serial input to scan chain) |
| `tdo` | Test data output (serial output from scan chain) |
| `trst` | Test reset (resets the TAP controller) |

System signals include:

| Signal | Description |
|------|-------------|
| `sysclk` | Processor clock |
| `sys_reset` | Processor reset |

---

# Execution Flow

The testbench performs the following operations:

```
Processor execution
        ↓
Detect program completion
        ↓
Halt processor via JTAG
        ↓
Move TAP to SAMPLE/PRELOAD
        ↓
Scan internal signals
        ↓
Display processor state
```

---

# Halting the Processor via JTAG

The processor is halted using a **JTAG command sequence** shifted into the TAP controller using `tms` and `tdi`.

This sequence drives the TAP through specific states and loads a control instruction that stops the processor pipeline.

Example code:

```systemverilog
$display("HALTing system logic");
for (i=11; i >= 0; i=i-1) begin
   @(negedge tck) begin
      tms <= halt_tmsvector[i];
      tdi <= halt_tdivector[i];
   end
end
```

### Why the Processor Must Be Halted

If the processor continues running during a scan operation:

* internal signals change every cycle
* captured scan data becomes inconsistent
* debugging results become unreliable

Halting the processor ensures the internal architectural state remains **stable while being scanned out**.

---

# SAMPLE/PRELOAD Mode

After halting the processor, the TAP controller is moved to the **SAMPLE/PRELOAD state**.

```systemverilog
$display("putting TAP in SAMPLE/PRELOAD");
for (i=11; i >= 0; i=i-1) begin
   @(negedge tck) begin
      tms <= sp_tmsvector[i];
      tdi <= sp_tdivector[i];
   end
end
```

### What SAMPLE/PRELOAD Does

The `SAMPLE/PRELOAD` state allows the scan chain to:

* **capture internal signals**
* prepare the scan chain for shifting data out
* observe internal processor state without modifying it

In this Drop‑In‑JTAG design, selected processor signals are connected into a scan chain so they can be captured and shifted out serially.

---

# Scanning the Data Register

Once the TAP is in the correct state, the scan chain is shifted out through `tdo`.

```systemverilog
for (i=160; i >= 0; i=i-1) begin
   @(negedge tck) begin
      tdovector[i] <= tdo;
   end
end
```

Each clock cycle shifts one bit of internal processor state out of the scan chain.

---

# Captured Processor Signals

The scan chain contains several internal signals from the processor pipeline.

| Bits | Signal |
|-----|-------|
| `[160:129]` | `ReadDataM` |
| `[128:97]` | `WriteDataM` |
| `[96:65]` | `DataAdrM` |
| `[64]` | `MemWriteM` |
| `[63:32]` | `InstrF` |
| `[31:0]` | `PCF` |

These signals expose both datapath and control information from the processor.

---

# Displaying Captured State

After scanning the vector, the testbench prints the decoded values.

```systemverilog
$display("ReadDataM: %h | WriteDataM %h | DataAdrM: %h | MemWriteM: %b | InstrF: %h | PCF: %h",
         tdovector[160:129],
         tdovector[128:97],
         tdovector[96:65],
         tdovector[64],
         tdovector[63:32],
         tdovector[31:0]);
```

This allows inspection of processor execution state through JTAG.

---

# Why It Is Called Drop‑In‑JTAG

The term **Drop‑In‑JTAG** refers to the ability to add debug capability to an existing design with minimal changes.

Instead of modifying the processor architecture, internal signals are simply connected to a scan chain accessible through JTAG.

Advantages include:

* Non‑intrusive debugging
* Minimal design modification
* Reusable debug infrastructure
* FPGA and ASIC compatibility
* Visibility into internal processor state

---

# Summary

This example demonstrates a simple but powerful debugging approach:

* The processor runs normally on the system clock.
* JTAG commands halt the processor and control the TAP controller.
* The TAP captures internal signals through `SAMPLE/PRELOAD`.
* The scan chain shifts internal state out through `tdo`.
* The testbench decodes and prints the captured processor signals.

This Drop‑In‑JTAG approach provides a lightweight and reusable mechanism for inspecting processor internals during simulation or hardware debugging.
