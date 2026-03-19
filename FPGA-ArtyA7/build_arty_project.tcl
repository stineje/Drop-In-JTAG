# build_arty_project.tcl
#
# Usage inside Vivado:
#   source build_arty_project.tcl
#
# Or from command line:
#   vivado -mode batch -source build_arty_project.tcl
#
# This script:
#   - creates a Vivado project for Arty A7-100T
#   - adds SystemVerilog/Verilog/VHDL sources from:
#         ../RISCV_pipe
#         ../JTAG-HDL
#   - adds Arty_Master.xdc from the current directory
#   - sets the top module
#   - runs synthesis and implementation
#   - writes a bitstream

# ------------------------------------------------------------
# User settings
# ------------------------------------------------------------
set PROJECT_NAME "arty_jtag_riscv"
set PROJECT_DIR  "./Drop-In-JTAG"
set TOP_MODULE   "top"
set PART_NAME    "xc7a100tcsg324-1"

# If your Vivado install has Digilent board files installed, you can use:
# set BOARD_PART "digilentinc.com:arty-a7-100:part0:1.1"
# Otherwise leave BOARD_PART empty and only PART_NAME will be used.
set BOARD_PART   ""

# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------
set CUR_DIR        [file normalize [pwd]]
set RISCV_PIPE_DIR [file normalize [file join $CUR_DIR .. RISCV_pipe]]
set JTAG_HDL_DIR   [file normalize [file join $CUR_DIR .. JTAG-HDL]]
set XDC_FILE       [file normalize [file join $CUR_DIR Arty_Master.xdc]]

puts "Current directory : $CUR_DIR"
puts "RISCV_pipe dir    : $RISCV_PIPE_DIR"
puts "JTAG-HDL dir      : $JTAG_HDL_DIR"
puts "Constraint file   : $XDC_FILE"

# ------------------------------------------------------------
# Checks
# ------------------------------------------------------------
if {![file isdirectory $RISCV_PIPE_DIR]} {
    error "Directory not found: $RISCV_PIPE_DIR"
}
if {![file isdirectory $JTAG_HDL_DIR]} {
    error "Directory not found: $JTAG_HDL_DIR"
}
if {![file exists $XDC_FILE]} {
    error "Constraint file not found: $XDC_FILE"
}

# ------------------------------------------------------------
# Helper: recursively collect HDL files
# ------------------------------------------------------------
proc collect_files_recursive {dir patterns} {
    set result {}
    foreach item [glob -nocomplain -directory $dir *] {
        if {[file isdirectory $item]} {
            set subfiles [collect_files_recursive $item $patterns]
            set result [concat $result $subfiles]
        } else {
            foreach pat $patterns {
                if {[string match $pat [file tail $item]]} {
                    lappend result [file normalize $item]
                    break
                }
            }
        }
    }
    return $result
}

# ------------------------------------------------------------
# Collect source files
# ------------------------------------------------------------
set sv_files_1 [collect_files_recursive $RISCV_PIPE_DIR [list "*.sv" "*.svh" "*.v" "*.vh" "*.vhd" "*.vhdl"]]
set sv_files_2 [collect_files_recursive $JTAG_HDL_DIR   [list "*.sv" "*.svh" "*.v" "*.vh" "*.vhd" "*.vhdl"]]

set all_files [concat $sv_files_1 $sv_files_2]
set all_files [lsort -unique $all_files]

if {[llength $all_files] == 0} {
    error "No HDL files found in $RISCV_PIPE_DIR or $JTAG_HDL_DIR"
}

puts "Found [llength $all_files] HDL files."

# ------------------------------------------------------------
# Recreate project directory
# ------------------------------------------------------------
if {[file exists $PROJECT_DIR]} {
    puts "Removing existing project directory: $PROJECT_DIR"
    file delete -force $PROJECT_DIR
}

create_project $PROJECT_NAME $PROJECT_DIR -part $PART_NAME -force

if {$BOARD_PART ne ""} {
    catch {set_property board_part $BOARD_PART [current_project]} board_result
    puts "Board part set attempt: $board_result"
}

# ------------------------------------------------------------
# Add source files
# ------------------------------------------------------------
set srcset [get_filesets sources_1]

# Add sources
add_files -norecurse -fileset $srcset $all_files

# Add include directories for SystemVerilog headers
set include_dirs [list $RISCV_PIPE_DIR $JTAG_HDL_DIR]
set_property include_dirs $include_dirs $srcset

# Treat .sv explicitly as SystemVerilog
foreach f $all_files {
    set ext [string tolower [file extension $f]]
    if {$ext eq ".sv" || $ext eq ".svh"} {
        catch {set_property file_type SystemVerilog [get_files $f]}
    }
}

# ------------------------------------------------------------
# Add constraints
# ------------------------------------------------------------
set constrset [get_filesets constrs_1]
add_files -fileset $constrset $XDC_FILE

# ------------------------------------------------------------
# Set top
# ------------------------------------------------------------
set_property top $TOP_MODULE $srcset
update_compile_order -fileset $srcset

# ------------------------------------------------------------
# Optional project settings
# ------------------------------------------------------------
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# ------------------------------------------------------------
# Report compile order
# ------------------------------------------------------------
puts "Top module set to: $TOP_MODULE"
puts "Updating compile order..."
update_compile_order -fileset $srcset

# ------------------------------------------------------------
# Launch synthesis
# ------------------------------------------------------------
puts "Launching synthesis..."
launch_runs synth_1 -jobs 8
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
puts "Synthesis status: $synth_status"

if {[string first "ERROR" $synth_status] >= 0} {
    error "Synthesis failed."
}

# ------------------------------------------------------------
# Launch implementation through bitstream
# ------------------------------------------------------------
puts "Launching implementation..."
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
puts "Implementation status: $impl_status"

if {[string first "ERROR" $impl_status] >= 0} {
    error "Implementation failed."
}

# ------------------------------------------------------------
# Open implemented design and write reports
# ------------------------------------------------------------
open_run impl_1

report_timing_summary -file [file join $PROJECT_DIR timing_summary.rpt]
report_utilization     -file [file join $PROJECT_DIR utilization.rpt]
report_power           -file [file join $PROJECT_DIR power.rpt]

puts ""
puts "Build complete."
puts "Project directory : $PROJECT_DIR"
puts "Bitstream         : [glob -nocomplain [file join $PROJECT_DIR $PROJECT_NAME.runs impl_1 *.bit]]"
puts ""
