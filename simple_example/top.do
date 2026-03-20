# top_accum_complete.do
#
# ModelSim run script for the Drop-In-JTAG accumulator demonstration.
#
# Either bring up ModelSim and type the following at the "ModelSim>" prompt:
#     do top_accum_complete.do
# or, to run from a shell, type the following at the shell prompt:
#     vsim -do top_accum_complete.do -c
# (omit the "-c" to see the GUI while running from the shell)

onbreak {resume}

# ── create library ────────────────────────────────────────────────────────────
if [file exists work] {
    vdel -all
}
vlib work

# ── compile source files ──────────────────────────────────────────────────────
# Testbench
vlog tb_top_accum.sv

# JTAG infrastructure (shared with RISC-V top)
vlog ../JTAG-HDL/jtag_test_logic.sv
vlog ../JTAG-HDL/bsr_cell.sv
vlog ../JTAG-HDL/bsr.sv
vlog ../JTAG-HDL/synchronizer.sv
vlog ../JTAG-HDL/tap_controller.sv
vlog ../JTAG-HDL/instruction_register.sv
vlog ../JTAG-HDL/bypass_register.sv
vlog ../JTAG-HDL/device_identification_register.sv

# Accumulator DUT + top-level wrapper
vlog top_accum.sv

# ── start simulation ──────────────────────────────────────────────────────────
vsim -debugdb -voptargs=+acc work.tb_top_accum

# ── wave configuration ────────────────────────────────────────────────────────

# -- JTAG pins
add wave -noupdate -divider -height 32 "JTAG Pins"
add wave -noupdate -group "JTAG Pins" /tb_top_accum/tck
add wave -noupdate -group "JTAG Pins" /tb_top_accum/tms
add wave -noupdate -group "JTAG Pins" /tb_top_accum/tdi
add wave -noupdate -group "JTAG Pins" /tb_top_accum/tdo
add wave -noupdate -group "JTAG Pins" /tb_top_accum/trst

# -- System
add wave -noupdate -divider -height 32 "System"
add wave -noupdate -group "System" /tb_top_accum/clk
add wave -noupdate -group "System" /tb_top_accum/reset
add wave -noupdate -group "System" /tb_top_accum/dut/dm_reset
add wave -noupdate -group "System" /tb_top_accum/dut/reset
add wave -noupdate -group "System" /tb_top_accum/dut/dbgclk
add wave -noupdate -group "System" /tb_top_accum/dut/success
add wave -noupdate -group "System" /tb_top_accum/dut/fail

# -- BSR scan chain readback vector
add wave -noupdate -divider -height 32 "BSR Scan Readback"
add wave -hex -color Blue /tb_top_accum/tdovector
add wave -hex /tb_top_accum/rb_op
add wave -hex /tb_top_accum/rb_operand
add wave -hex /tb_top_accum/rb_acc
add wave -hex /tb_top_accum/rb_result
add wave -noupdate /tb_top_accum/rb_zero
add wave -noupdate /tb_top_accum/rb_carry
add wave -noupdate /tb_top_accum/rb_overflow

# -- Accumulator DUT internals
add wave -noupdate -divider -height 32 "Accumulator DUT"
add wave -noupdate -group "Accumulator" /tb_top_accum/dut/dut/clk
add wave -noupdate -group "Accumulator" /tb_top_accum/dut/dut/reset
add wave -hex     -group "Accumulator" /tb_top_accum/dut/dut/op
add wave -hex     -group "Accumulator" /tb_top_accum/dut/dut/operand
add wave -hex     -group "Accumulator" /tb_top_accum/dut/dut/acc
add wave -hex     -group "Accumulator" /tb_top_accum/dut/dut/result
add wave -hex     -group "Accumulator" /tb_top_accum/dut/dut/full_result
add wave -noupdate -group "Accumulator" /tb_top_accum/dut/dut/zero
add wave -noupdate -group "Accumulator" /tb_top_accum/dut/dut/carry
add wave -noupdate -group "Accumulator" /tb_top_accum/dut/dut/overflow

# -- TAP controller
add wave -noupdate -divider -height 32 "TAP Controller"
add wave -hex /tb_top_accum/dut/jtag/fsm/*

# -- Instruction register
add wave -noupdate -divider -height 32 "Instruction Register"
add wave -hex /tb_top_accum/dut/jtag/ir/*

# -- JTAG block (top-level signals)
add wave -noupdate -divider -height 32 "JTAG Block"
add wave -hex /tb_top_accum/dut/jtag/*

# -- BSR chains
add wave -noupdate -divider -height 32 "op_bsr"
add wave -hex /tb_top_accum/dut/op_bsr/*

add wave -noupdate -divider -height 32 "operand_bsr"
add wave -hex /tb_top_accum/dut/operand_bsr/*

add wave -noupdate -divider -height 32 "acc_bsr"
add wave -hex /tb_top_accum/dut/acc_bsr/*

add wave -noupdate -divider -height 32 "result_bsr"
add wave -hex /tb_top_accum/dut/result_bsr/*

add wave -noupdate -divider -height 32 "flags_bsr"
add wave -hex /tb_top_accum/dut/flags_bsr/*

# ── wave display settings ─────────────────────────────────────────────────────
TreeUpdate [SetDefaultTree]
WaveRestoreZoom {0 ps} {200 ns}
configure wave -namecolwidth 150
configure wave -valuecolwidth 250
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

# ── run ───────────────────────────────────────────────────────────────────────
run 10000 ns

if {[info exists gui] && $gui} {
    wave sort ascending
}

# ── optional: save waveform snapshot ─────────────────────────────────────────
# wave write accum_waves.wlf

