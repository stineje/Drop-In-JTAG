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
vlog ../testbenches/tb_top.sv ../RTL/top.sv ../RTL/jtag_test_logic.sv 
vlog ../RTL/tap_controller.sv ../RTL/instruction_register.sv 
vlog ../RTL/bypass_register.sv ../RTL/bsr.sv
vlog ../RTL/device_identification_register.sv
vlog ../RISCV_pipe/hdl/riscv_pipelined.sv

# start and run simulation
vsim  -voptargs=+acc work.testbench

#+nowarn3829 -error 3015

# view list
# view wave

# Load Decoding
do ../RISCV_pipe/hdl/wave.do

# RISC-V core waves
-- display input and output signals as hexidecimal values
add wave -noupdate -divider -height 32 "Instructions"
add wave -noupdate -expand -group Instructions /testbench/dut/core/reset
add wave -noupdate -expand -group Instructions -color {Orange Red} /testbench/dut/core/PCF
add wave -noupdate -expand -group Instructions -color Orange /testbench/dut/core/InstrF
add wave -noupdate -expand -group Instructions -color Orange -radix Instructions /testbench/dut/core/InstrF
add wave -noupdate -expand -group Instructions -color Orange /testbench/dut/core/dp/InstrF
add wave -noupdate -expand -group Instructions -color Orange -radix Instructions /testbench/dut/core/dp/InstrF
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

add wave -hex /testbench/dut/jtag/ir/instructions
add wave -hex /testbench/tck
add wave -hex /testbench/trst
add wave -hex /testbench/tms
add wave -hex /testbench/tdi
add wave -hex /testbench/tdo
add wave -hex /testbench/tdo_sample
add wave -hex /testbench/tdo_ref
add wave -hex /testbench/dut/jtag/bsr_tdo
add wave -hex /testbench/dut/jtag/tdo_en
add wave -hex /testbench/dut/jtag/select
add wave -hex /testbench/dut/jtag/tdo_ir
add wave -hex /testbench/dut/jtag/tdo_dr
add wave -hex /testbench/dut/bsr_update
add wave -hex /testbench/dut/bsr_clk
add wave -hex /testbench/dut/jtag/shiftDR

add wave -noupdate -divider -height 32 "TAP controller"
add wave -label state -hex /testbench/dut/jtag/fsm/state 
add wave -label tck -hex /testbench/dut/jtag/fsm/tck 
add wave -label trst -hex /testbench/dut/jtag/fsm/trst 
add wave -label tms -hex /testbench/dut/jtag/fsm/tms 
add wave -label reset -hex /testbench/dut/jtag/fsm/reset 
add wave -label tdo_en -hex /testbench/dut/jtag/fsm/tdo_en 
add wave -label shiftIR -hex /testbench/dut/jtag/fsm/shiftIR 
add wave -label captureIR -hex /testbench/dut/jtag/fsm/captureIR 
add wave -label clockIR -hex /testbench/dut/jtag/fsm/clockIR 
add wave -label updateIR -hex /testbench/dut/jtag/fsm/updateIR 
add wave -label shiftDR -hex /testbench/dut/jtag/fsm/shiftDR 
add wave -label captureDR -hex /testbench/dut/jtag/fsm/captureDR 
add wave -label clockDR -hex /testbench/dut/jtag/fsm/clockDR 
add wave -label updateDR -hex /testbench/dut/jtag/fsm/updateDR 
add wave -label updateDRstate -hex /testbench/dut/jtag/fsm/updateDRstate 
add wave -label select -hex /testbench/dut/jtag/fsm/select


add wave -noupdate -divider -height 32 "All Signals"
# Diplays All Signals recursively
add wave -hex -r /testbench/*
#add wave -noupdate -divider -height 32 "Title"


-- Set Wave Output Items 
TreeUpdate [SetDefaultTree]
WaveRestoreZoom {0 ps} {200 ns}
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

-- Run the Simulation
run 10000 ns

-- Add schematic
#add schematic -full sim:/testbench/dut/jtag
#add schematic -full sim:/testbench/dut/core

-- Save memory for checking (if needed)
# mem save -outfile memory.dat -wordsperline 1 /testbench/dut/dmem/RAM