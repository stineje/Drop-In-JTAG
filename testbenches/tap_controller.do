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
vlog ../RTL/tap_controller.sv tb_tap_controller.sv

# start and run simulation
vsim -wlf tap_controlller.wlf +nowarn3829 -error 3015 -voptargs=+acc -l transcript.txt work.testbench

# view list
# view wave

-- display input and output signals as hexidecimal values
# Diplays All Signals recursively
add wave -color gold -hex -r /testbench/dut/tck
add wave -hex -r /testbench/dut/trst
add wave -hex -r /testbench/dut/tms
add wave -hex -r /testbench/dut/tdo_en
add wave -noupdate -divider -height 32 "I/O and Core Logic"
add wave -hex -r /testbench/testvector
add wave -noupdate -divider -height 32 "TAP Controller"
add wave -hex -r /testbench/dut/state
add wave -hex -r /testbench/dut/reset
add wave -noupdate -divider -height 32 "Instruction Register"
add wave -hex -r /testbench/dut/clockIR
add wave -hex -r /testbench/dut/shiftIR
add wave -hex -r /testbench/dut/updateIR
add wave -hex -r /testbench/dut/captureIR
add wave -noupdate -divider -height 32 "Data Register"
add wave -hex -r /testbench/dut/clockDR
add wave -hex -r /testbench/dut/captureDR
add wave -hex -r /testbench/dut/shiftDR
add wave -hex -r /testbench/dut/updateDR
add wave -noupdate -divider -height 32 "Control"
add wave -hex -r /testbench/dut/select


-- Set Wave Output Items 
TreeUpdate [SetDefaultTree]
WaveRestoreZoom {0 ps} {200 ns}
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

-- Run the Simulation
run 10000000 ns