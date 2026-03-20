# Use this run.do file to run this example.
# Either bring up ModelSim and type the following at the "ModelSim>" prompt:
#     do run.do
# or, to run from a shell, type the following at the shell prompt:
#     vsim -do run.do -c
# (omit the "-c" to see the GUI while running from the shell)

onbreak {resume}

# create library
if [file exists work] {
    vdel -all
}
vlib work

# compile source files
vlog ../testbenches/tb_top.sv ../JTAG-HDL/top.sv ../JTAG-HDL/jtag_test_logic.sv
vlog ../JTAG-HDL/bsr_cell.sv ../JTAG-HDL/cdc_sync_stb.sv ../JTAG-HDL/synchronizer.sv
vlog ../JTAG-HDL/tap_controller.sv ../JTAG-HDL/instruction_register.sv 
vlog ../JTAG-HDL/bypass_register.sv ../JTAG-HDL/bsr.sv
vlog ../JTAG-HDL/device_identification_register.sv
vlog ../RISCV_pipe/riscv_pipelined.sv

# start and run simulation
vsim -debugdb  -voptargs=+acc work.testbench

# Load dram to 0
mem load -filltype value -filldata 0 -startaddress 0 -endaddress 255 sim:/testbench/dut/dmem/RAM

#+nowarn3829 -error 3015

# view list
# view wave

# Load Decoding
do ../RISCV_pipe/wave.do

# RISC-V core waves
-- display input and output signals as hexidecimal values
add wave -noupdate -divider -height 32 "Instructions"
add wave -noupdate -expand -group Instructions /testbench/dut/core/reset
add wave -noupdate -expand -group Instructions -color {Orange Red} /testbench/dut/core/PCF
add wave -noupdate -expand -group Instructions -color Orange /testbench/dut/core/InstrF
add wave -hex -color Blue /testbench/tdovector
add wave -noupdate -divider -height 32 "Datapath"
add wave -hex /testbench/dut/core/dp/*
add wave -noupdate -divider -height 32 "Control"
add wave -hex /testbench/dut/core/c/*
add wave -noupdate -divider -height 32 "Main Decoder"
add wave -hex /testbench/dut/core/c/md/*
add wave -noupdate -divider -height 32 "ALU Decoder"
add wave -hex /testbench/dut/core/c/ad/*
add wave -noupdate -divider -height 32 "Data Memory"
add wave -hex /testbench/dut/dmem/*
add wave -noupdate -divider -height 32 "Instruction Memory"
add wave -hex /testbench/dut/imem/*
add wave -noupdate -divider -height 32 "Register File"
add wave -hex /testbench/dut/core/dp/rf/*
add wave -hex /testbench/dut/core/dp/rf/rf

add wave -noupdate -divider -height 32 "TAP controller"
add wave -hex /testbench/dut/jtag/fsm/*

add wave -noupdate -divider -height 32 "instruction register"
add wave -hex /testbench/dut/jtag/ir/*

add wave -noupdate -divider -height 32 "JTAG block"
add wave -hex /testbench/dut/jtag/*

add wave -noupdate -divider -height 32 "PCF_bsr"
add wave -hex /testbench/dut/PCF_bsr/*

add wave -noupdate -divider -height 32 "InstrF_bsr"
add wave -hex /testbench/dut/InstrF_bsr/*

add wave -noupdate -divider -height 32 "MemWriteM_bsr"
add wave -hex /testbench/dut/MemWriteM_bsr/*

add wave -noupdate -divider -height 32 "DataAdrM_bsr"
add wave -hex /testbench/dut/DataAdrM_bsr/*

add wave -noupdate -divider -height 32 "WriteDataM_bsr"
add wave -hex /testbench/dut/WriteDataM_bsr/*

add wave -noupdate -divider -height 32 "ReadDataM_bsr"
add wave -hex /testbench/dut/ReadDataM_bsr/*

# add wave -noupdate -divider -height 32 "All Signals"
# Diplays All Signals recursivelya
# add wave -hex -r /testbench/*
# add wave -noupdate -divider -height 32 "Title"

-- Set Wave Output Items 
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

-- Run the Simulation
run 10000 ns

if {[info exists gui] && $gui} {
    wave sort ascending
}

-- Add schematic
# add schematic -full sim:/testbench/dut

-- Save memory for checking (if needed)
# mem save -outfile memory.dat -wordsperline 1 /testbench/dut/dmem/RAM