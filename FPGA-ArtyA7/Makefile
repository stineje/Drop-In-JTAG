# ============================================================
# Makefile for Vivado Arty A7-100T Project Build
#
# Usage:
#   make           - build bitstream
#   make synth     - run synthesis only
#   make impl      - run synthesis + implementation + bitstream
#   make open      - open the Vivado project GUI
#   make clean     - remove log/journal/temp files
#   make distclean - remove the entire generated project
# ============================================================

VIVADO ?= vivado

TCL_BUILD := build_arty_project.tcl
TCL_SYNTH := synth_arty_project.tcl

PROJECT_NAME := Drop-In-JTAG
PROJECT_DIR  := Drop-In-JTAG

RUN_DIR   := $(PROJECT_DIR)/$(PROJECT_NAME).runs
IMPL_DIR  := $(RUN_DIR)/impl_1
SYNTH_DIR := $(RUN_DIR)/synth_1

.PHONY: all build synth impl open clean distclean nuke help

all: build

build: impl

impl:
	@if [ ! -f "$(TCL_BUILD)" ]; then \
		echo "ERROR: $(TCL_BUILD) not found."; \
		exit 1; \
	fi
	$(VIVADO) -mode batch -source $(TCL_BUILD)

synth:
	@if [ -f "$(TCL_SYNTH)" ]; then \
		$(VIVADO) -mode batch -source $(TCL_SYNTH); \
	else \
		echo "ERROR: $(TCL_SYNTH) not found."; \
		echo "Create a synthesis-only TCL script or use: make"; \
		exit 1; \
	fi

open:
	@if [ -d "$(PROJECT_DIR)" ]; then \
		$(VIVADO) $(PROJECT_DIR)/$(PROJECT_NAME).xpr & \
	else \
		echo "Project does not exist yet. Run 'make' first."; \
		exit 1; \
	fi

clean:
	rm -f *.jou *.log *.str
	rm -rf .Xil
	rm -rf webtalk* usage_statistics_webtalk.xml
	rm -f hs_err_pid*.log
	rm -f *.wdb *.pb *.dbg

distclean: clean
	rm -rf $(PROJECT_DIR)

nuke: distclean
	rm -rf *.gen *.cache *.runs *.sim
	rm -rf xsim.dir
	rm -f *.bit *.bin *.ltx
	rm -f *.xml *.csv *.rpt

help:
	@echo "Available targets:"
	@echo "  make / make build  - full Vivado build"
	@echo "  make synth         - synthesis only"
	@echo "  make impl          - synthesis + implementation + bitstream"
	@echo "  make open          - open project in Vivado GUI"
	@echo "  make clean         - remove logs and temporary files"
	@echo "  make distclean     - remove logs and generated project"
	@echo "  make nuke          - aggressive cleanup"

