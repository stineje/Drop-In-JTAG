# RISC-V Assembly Example — Compiling with the Wally Toolchain

This directory contains example **RISC-V assembly programs** derived from exercises in the excellent textbook:

📘 **Digital Design and Computer Architecture: RISC-V Edition**  
by **Sarah Harris** and **David Harris**

Official materials and example code are available here:

- https://pages.hmc.edu/harris/ddca/ddcarv.html

These programs are compiled and executed using the **Wally RISC-V toolchain and environment** developed by the OpenHW Group.

Repository:

- https://github.com/openhwgroup/cvw

---

# Overview

The **Wally processor platform** provides a complete open-source environment for:

- RISC-V processor design
- simulation and verification
- FPGA and ASIC flows
- compiling and running RISC-V software

The toolchain included in the Wally environment provides:

- GNU RISC-V assembler (`riscv64-unknown-elf-as`)
- GNU RISC-V compiler (`riscv64-unknown-elf-gcc`)
- linker (`riscv64-unknown-elf-ld`)
- objdump utilities
- simulation support through **Spike** and the **Wally simulation environment**

These assembly examples are intended to illustrate fundamental concepts from the DDCA textbook and can be compiled and run within the Wally environment.

---

# Prerequisites

Before compiling the assembly programs, install the **Wally environment**.

## 1. Clone the Wally Repository

```bash
git clone https://github.com/openhwgroup/cvw
cd cvw
