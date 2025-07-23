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
vlog tap_controller.sv tb_tap_controller.sv

# start and run simulation
vsim +nowarn3829 -error 3015 -voptargs=+acc -l transcript.txt work.testbench

# view list
# view wave

-- display input and output signals as hexidecimal values
# Diplays All Signals recursively
add wave -hex -r /testbench/dut/tck
add wave -hex -r /testbench/dut/trst
add wave -hex -r /testbench/dut/tms
add wave -hex -r /testbench/dut/state
add wave -hex -r /testbench/dut/reset
add wave -hex -r /testbench/dut/clockIR
add wave -hex -r /testbench/dut/captureIR
add wave -hex -r /testbench/dut/shiftIR
add wave -hex -r /testbench/dut/updateIR
add wave -hex -r /testbench/dut/clockDR
add wave -hex -r /testbench/dut/captureDR
add wave -hex -r /testbench/dut/shiftDR
add wave -hex -r /testbench/dut/updateDR
add wave -hex -r /testbench/dut/select
add wave -hex -r /testbench/dut/tdo_en
add wave -hex -r /testbench/dut/updateDRstate
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
run 10000000 ns