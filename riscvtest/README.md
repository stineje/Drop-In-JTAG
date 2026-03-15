# RISC-V Assembly Example — Compiling with the Wally Toolchain

This directory contains example **RISC-V assembly programs** derived from exercises in the excellent textbook:

📘 **Digital Design and Computer Architecture: RISC-V Edition**  
by **Sarah Harris** and **David Harris**

Official materials and example code are available here:

- https://pages.hmc.edu/harris/ddca/ddcarv.html

These programs are compiled and executed using the Wally RISC-V toolchain and development environment associated with the Wally processor infrastructure developed in collaboration with the OpenHW Group. The toolchain provides the compiler, assembler, linker, and simulation support needed to build and execute software for the processor, enabling a consistent development environment for both hardware and software experimentation.

The design used in this work is based on the pipelined RISC-V architecture described by Harris and Harris in Digital Design and Computer Architecture: RISC-V Edition. A more complete System-on-Chip implementation and supporting materials are presented in our new textbook, RISC-V System-on-Chip Design, available at RISC-V System-on-Chip Design textbook resources (https://pages.hmc.edu/harris/ddca/rvsocd.html). The materials associated with the textbook provide a full environment for building and experimenting with RISC-V systems, including processor implementations, peripheral integration, and supporting infrastructure for hardware and software development. The implementation used here follows the standard five-stage pipelined organization and provides access to multiple internal architectural registers for observation and debugging.

The textbook resources also include a set of scripts that automatically configure the RISC-V development environment and toolchain across a wide range of operating systems. These scripts install and configure the necessary compilers, simulators, and supporting tools required to compile, simulate, and debug RISC-V software and hardware designs. By automating the setup process, the environment can be reproduced easily on Linux, macOS, and other common development platforms, allowing students and researchers to quickly establish a consistent working environment for experimentation with the RISC-V processor and associated System-on-Chip infrastructure.

The framework is intentionally structured to allow selected registers and internal signals to be exported, making it convenient for testing, educational demonstrations, and architectural exploration. Because the design is modular, the set of exposed registers can be easily extended or modified, and the same approach can be adapted to other RISC-V cores or alternative processor architectures with minimal changes to the surrounding infrastructure.

To support external visibility and control, selected signals are connected through an HDL-based boundary scan cell. Each observable register or signal is routed through a scan element that can operate either in normal functional mode or in scan mode under the control of the JTAG interface. In functional mode, the signal passes transparently through the boundary cell so that the processor operates normally. When boundary scan mode is enabled, the scan chain allows these signals to be captured, shifted out, or updated through the JTAG data path. This approach enables non-intrusive observation of internal processor state and provides a flexible mechanism for debugging, testing, and experimentation without modifying the core architectural behavior. Because the boundary scan cells are implemented at the HDL level, they can be easily replicated or adapted to expose additional registers or signals as needed.
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
