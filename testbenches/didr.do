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
vlog ../testbenches/tb_didr.sv device_identification_register.sv

# start and run simulation
vsim +nowarn3829 -error 3015 -voptargs=+acc -l transcript.txt work.testbench

# view list
# view wave

-- display input and output signals as hexidecimal values
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
run 10000000 ns