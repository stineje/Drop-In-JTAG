# TAP Controller (New Version)

## Overview
The `tap_controller_new` module is an updated implementation of the IEEE 1149.1 JTAG Test Access Port (TAP) controller.  
It is designed with a clean, **finite state machine (FSM)** architecture to make the TAP behavior more explicit, maintainable, and extensible for future debugging, testing, and boundary scan features.

This controller supports all TAP states for both **Instruction Register (IR)** and **Data Register (DR)** scan paths, generating control signals for shifting, capturing, updating, and selecting between registers.

---

## Objectives
- **FSM-based clarity:** Represent TAP state transitions explicitly with a SystemVerilog `enum` for easier reading and modification.
- **Extensibility:** Serve as a foundation for creating more FSM-driven blocks across the project, making logic more modular and easier to verify.
- **Specification alignment:** Follow the IEEE 1149.1 standard state transition rules for DR and IR paths.
- **Signal generation:** Provide well-defined outputs for reset, enable, capture, shift, clocking, update, and select signals.

---

## Features
- **Full TAP State Encoding:** All 16 TAP controller states represented using a `logic [3:0]` enum.
- **State Transition Logic:** Implemented in a single always block triggered on the rising edge of TCK.
- **Output Control Signals:**
  - `shiftIR`, `captureIR`, `clockIR`, `updateIR`
  - `shiftDR`, `captureDR`, `clockDR`, `updateDR`
  - `tdo_en` for tri-state control
  - `reset` and `select` for global control
- **Clocking Assignments:** `clockIR` and `clockDR` generation derived from TAP state encoding.

---

## Why This Matters
The TAP controller is the **entry point for test and debug operations** in any JTAG-compliant device.  
By restructuring it as a clean FSM:
- Future modules can use similar FSM templates for better maintainability.
- Designers can clearly see **state-to-signal mapping** without digging into tangled conditional logic.
- This approach encourages **reuse of FSM logic** for other control modules.

---

## Future Work
- Integrate with boundary-scan cells.
- Add parameterization for custom JTAG instruction sets.
- Incorporate simulation assertions to catch invalid state transitions.

---

## References
- IEEE 1149.1 Standard (JTAG) — TAP Controller State Diagram
- Internal FSM coding guidelines for maintainable hardware design
