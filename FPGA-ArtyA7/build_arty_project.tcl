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
#   - adds Drop-In-JTAG.xdc from the current directory
#   - sets the top module
#   - runs synthesis and implementation
#   - writes a bitstream

# ------------------------------------------------------------
# User settings
# ------------------------------------------------------------
set PROJECT_NAME "Drop-In-JTAG"
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
set XDC_FILE       [file normalize [file join $CUR_DIR Drop-In-JTAG.xdc]]
set MEM_FILE       [file normalize [file join $CUR_DIR .. riscvtest riscvtest.mem]]

puts "Current directory : $CUR_DIR"
puts "RISCV_pipe dir    : $RISCV_PIPE_DIR"
puts "JTAG-HDL dir      : $JTAG_HDL_DIR"
puts "Constraint file   : $XDC_FILE"
puts "Memory init file  : $MEM_FILE"

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
if {![file exists $MEM_FILE]} {
    error "Memory init file not found: $MEM_FILE"
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
# Add memory init file
# ------------------------------------------------------------
add_files -norecurse -fileset $srcset $MEM_FILE
set_property file_type {Memory Initialization Files} [get_files $MEM_FILE]
puts "Added memory init file: $MEM_FILE"

# When clk_wiz_0 is present, generated clocks appear after IP elaboration.
# Add a separate late XDC to cut async TCK <-> core-clock crossings explicitly.
# Set NEED_CLK_WIZ 1 in the User settings block above if using a clk_wiz IP.
if {[info exists NEED_CLK_WIZ] && $NEED_CLK_WIZ} {
    add_late_async_constraints_for_clk_wiz $constrset $CUR_DIR
}

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
report_utilization    -file [file join $PROJECT_DIR utilization.rpt]
report_power          -file [file join $PROJECT_DIR power.rpt]

# ------------------------------------------------------------
# Hierarchical utilization breakdown by top-level instance
#
# Instance hierarchy under top:
#   jtag         - jtag_test_logic (TAP controller + IR/DR + debug FSM)
#   core         - riscv pipelined core
#   imem         - instruction memory
#   dmem         - data memory
#   clk_inst     - clk_gen MMCM clock generator
#   BSR chain    - six boundary scan register instances
# ------------------------------------------------------------
set rpt_dir [file join $PROJECT_DIR utilization_breakdown]
file mkdir $rpt_dir

puts "Writing hierarchical utilization reports to: $rpt_dir"

# Helper: report utilization for a cell, catch gracefully if not found
proc report_cell_util {inst_path rpt_file} {
    set cells [get_cells -quiet -hierarchical -filter "NAME =~ $inst_path"]
    if {[llength $cells] == 0} {
        puts "  WARNING: No cells found matching '$inst_path' -- skipping"
        return
    }
    report_utilization -cells $cells -file $rpt_file
    puts "  Written: $rpt_file"
}

# JTAG test logic (TAP FSM + IR + DR registers + debug FSM)
report_cell_util "jtag"     [file join $rpt_dir util_jtag.rpt]

# JTAG sub-blocks for finer breakdown
report_cell_util "jtag/fsm" [file join $rpt_dir util_jtag_tap_fsm.rpt]

# RISC-V core
report_cell_util "core"     [file join $rpt_dir util_riscv_core.rpt]

# Memories
report_cell_util "imem"     [file join $rpt_dir util_imem.rpt]
report_cell_util "dmem"     [file join $rpt_dir util_dmem.rpt]

# Clock generator
report_cell_util "clk_inst" [file join $rpt_dir util_clk_gen.rpt]

# BSR chain — report all six together and individually
report_cell_util "*_bsr"          [file join $rpt_dir util_bsr_all.rpt]
report_cell_util "PCF_bsr"        [file join $rpt_dir util_bsr_PCF.rpt]
report_cell_util "InstrF_bsr"     [file join $rpt_dir util_bsr_InstrF.rpt]
report_cell_util "MemWriteM_bsr"  [file join $rpt_dir util_bsr_MemWriteM.rpt]
report_cell_util "DataAdrM_bsr"   [file join $rpt_dir util_bsr_DataAdrM.rpt]
report_cell_util "WriteDataM_bsr" [file join $rpt_dir util_bsr_WriteDataM.rpt]
report_cell_util "ReadDataM_bsr"  [file join $rpt_dir util_bsr_ReadDataM.rpt]

# Summary table printed to stdout for quick reference in the build log
puts ""
puts "============================================================"
puts " Utilization Summary by Block"
puts "============================================================"
foreach {label pattern} {
    "JTAG (total)"   "jtag"
    "RISC-V core"    "core"
    "imem"           "imem"
    "dmem"           "dmem"
    "clk_gen"        "clk_inst"
    "BSR chain"      "*_bsr"
} {
    set cells [get_cells -quiet -hierarchical -filter "NAME =~ $pattern"]
    if {[llength $cells] > 0} {
        set luts  [get_property -quiet PRIMITIVE_COUNT [get_cells -quiet -hierarchical \
                      -filter "NAME =~ $pattern && REF_NAME =~ LUT*"]]
        set ffs   [get_property -quiet PRIMITIVE_COUNT [get_cells -quiet -hierarchical \
                      -filter "NAME =~ $pattern && REF_NAME =~ FD*"]]
        # Use report_utilization -return_string for a clean one-liner per block
        set util_str [report_utilization -cells $cells -return_string]
        # Extract LUT and FF totals from the report string
        set lut_count "?"
        set ff_count  "?"
        regexp {Slice LUTs\s*\|\s*(\d+)} $util_str -> lut_count
        regexp {Slice Registers\s*\|\s*(\d+)} $util_str -> ff_count
        puts [format "  %-20s  LUTs: %6s   FFs: %6s" $label $lut_count $ff_count]
    } else {
        puts [format "  %-20s  (not found)" $label]
    }
}
puts "============================================================"
puts ""

puts ""
puts "Build complete."
puts "Project directory    : $PROJECT_DIR"
puts "Bitstream            : [glob -nocomplain [file join $PROJECT_DIR $PROJECT_NAME.runs impl_1 *.bit]]"
puts "Utilization reports  : $rpt_dir"
puts ""
