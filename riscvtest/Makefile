## SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# ================================================================
# RISC-V Assembly Build Makefile
#
# Author: James Stine
#
# Description:
# This Makefile compiles RISC-V assembly programs using the
# Wally RISC-V toolchain from the OpenHW Group:
#
#     https://github.com/openhwgroup/cvw
#
# The assembly programs used with this Makefile are based on
# exercises from the textbook:
#
#   Digital Design and Computer Architecture: RISC-V Edition
#   by Sarah Harris and David Harris
#
#   https://pages.hmc.edu/harris/ddca/ddcarv.html
#
# Build Flow:
#
#   1. Compile assembly into ELF executable
#   2. Generate objdump disassembly
#   3. Convert ELF to memory initialization file (.memfile)
#
# The resulting .memfile can be used to initialize instruction
# memory in simulation environments such as Wally or other
# RISC-V processor test frameworks.
#
# Required Tools:
#
#   riscv64-unknown-elf-gcc
#   riscv64-unknown-elf-objdump
#   riscv64-unknown-elf-elf2hex
#
# These tools are provided as part of the Wally toolchain setup.
#
# ================================================================

CC      = riscv64-unknown-elf-gcc
CFLAGS  = -march=rv32i -mabi=ilp32 -mcmodel=medany -nostartfiles -Tlink.ld
OBJDUMP = riscv64-unknown-elf-objdump
ELF2HEX = riscv64-unknown-elf-elf2hex
SRCS    = $(wildcard *.S)
PROGS   = $(patsubst %.S,%,$(SRCS))

all: $(PROGS)

%: %.S
	$(CC) $(CFLAGS) -o $@.elf $<
	$(OBJDUMP) -Dls $@.elf > $@.objdump
	$(ELF2HEX) --bit-width 32 --input $@.elf --output $@.memfile

clean:
	rm -f *.elf
	rm -f *.objdump
	rm -f *.memfile
	rm -f *~
