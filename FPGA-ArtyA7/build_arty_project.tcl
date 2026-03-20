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
#   - optionally creates/adds clk_wiz_0 IP if the RTL instantiates it
#   - adds Arty_Master.xdc from the current directory
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

# Clock Wizard settings (used only if clk_wiz_0 is instantiated in RTL)
set CLK_WIZ_MODULE_NAME     "clk_wiz_0"
set CLK_WIZ_INPUT_FREQ_MHZ  "100.000"
set CLK_WIZ_OUTPUT_FREQ_MHZ "25.000"

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
# Helpers
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

proc file_contains_string {path needle} {
    if {![file exists $path]} {
        return 0
    }
    set fh [open $path r]
    set data [read $fh]
    close $fh
    return [expr {[string first $needle $data] >= 0}]
}

proc create_or_add_clk_wiz_ip {srcset module_name in_freq_mhz out_freq_mhz} {
    # Reuse existing IP in the project if it already exists.
    set existing_ip [get_ips -quiet $module_name]
    if {[llength $existing_ip] > 0} {
        puts "Reusing existing Clock Wizard IP '$module_name'"
        generate_target all $existing_ip
        export_ip_user_files -of_objects $existing_ip -no_script -sync -force
        return
    }

    puts "Creating Clock Wizard IP '$module_name' (${in_freq_mhz} MHz -> ${out_freq_mhz} MHz)"
    create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name $module_name

    set ip_obj [get_ips $module_name]

    # Configure a single output clock with reset + locked ports enabled.
    # Let Vivado derive the MMCM parameters from the requested frequencies.
    set_property -dict [list \
        CONFIG.PRIMITIVE {MMCM} \
        CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} \
        CONFIG.PRIM_IN_FREQ $in_freq_mhz \
        CONFIG.CLKIN1_JITTER_PS {100.0} \
        CONFIG.NUM_OUT_CLKS {1} \
        CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $out_freq_mhz \
        CONFIG.CLKOUT1_REQUESTED_PHASE {0.000} \
        CONFIG.CLKOUT1_REQUESTED_DUTY_CYCLE {50.000} \
        CONFIG.RESET_TYPE {ACTIVE_HIGH} \
        CONFIG.USE_LOCKED {true} \
        CONFIG.USE_RESET {true} \
    ] $ip_obj

    generate_target all $ip_obj
    create_ip_run $ip_obj
    launch_runs ${module_name}_synth_1 -jobs 8
    wait_on_run ${module_name}_synth_1
    export_ip_user_files -of_objects $ip_obj -no_script -sync -force
}

# ------------------------------------------------------------
# Collect source files
# ------------------------------------------------------------
set hdl_patterns [list "*.sv" "*.svh" "*.v" "*.vh" "*.vhd" "*.vhdl"]
set sv_files_1 [collect_files_recursive $RISCV_PIPE_DIR $hdl_patterns]
set sv_files_2 [collect_files_recursive $JTAG_HDL_DIR   $hdl_patterns]

set all_files [concat $sv_files_1 $sv_files_2]
set all_files [lsort -unique $all_files]

if {[llength $all_files] == 0} {
    error "No HDL files found in $RISCV_PIPE_DIR or $JTAG_HDL_DIR"
}

puts "Found [llength $all_files] HDL files."

# Determine whether top-level RTL instantiates clk_wiz_0.
set top_sv_candidate [file normalize [file join $JTAG_HDL_DIR ${TOP_MODULE}.sv]]
set NEED_CLK_WIZ 0
set clk_wiz_pat1 "${CLK_WIZ_MODULE_NAME} "
set clk_wiz_pat2 "${CLK_WIZ_MODULE_NAME}("
if {[file_contains_string $top_sv_candidate $clk_wiz_pat1]} {
    set NEED_CLK_WIZ 1
}
if {[file_contains_string $top_sv_candidate $clk_wiz_pat2]} {
    set NEED_CLK_WIZ 1
}
puts "Clock Wizard required: $NEED_CLK_WIZ"

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

# Add design sources
add_files -norecurse -fileset $srcset $all_files

# Add include directories for SystemVerilog headers
set include_dirs [list $RISCV_PIPE_DIR $JTAG_HDL_DIR]
set_property include_dirs $include_dirs $srcset

# Treat .sv and .svh explicitly as SystemVerilog
foreach f $all_files {
    set ext [string tolower [file extension $f]]
    if {$ext eq ".sv" || $ext eq ".svh"} {
        catch {set_property file_type SystemVerilog [get_files $f]}
    }
}

# Create/add Clock Wizard IP if required by the RTL
if {$NEED_CLK_WIZ} {
    create_or_add_clk_wiz_ip $srcset $CLK_WIZ_MODULE_NAME $CLK_WIZ_INPUT_FREQ_MHZ $CLK_WIZ_OUTPUT_FREQ_MHZ
}

# ------------------------------------------------------------
# Add constraints
# ------------------------------------------------------------
set constrset [get_filesets constrs_1]
add_files -fileset $constrset $XDC_FILE

# ------------------------------------------------------------
# Set top / project settings
# ------------------------------------------------------------
set_property top $TOP_MODULE $srcset
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

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

if {[string first "ERROR" $synth_status] >= 0 || [string first "failed" [string tolower $synth_status]] >= 0} {
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

if {[string first "ERROR" $impl_status] >= 0 || [string first "failed" [string tolower $impl_status]] >= 0} {
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
report_cell_util "*_bsr"    [file join $rpt_dir util_bsr_all.rpt]
report_cell_util "PCF_bsr"       [file join $rpt_dir util_bsr_PCF.rpt]
report_cell_util "InstrF_bsr"    [file join $rpt_dir util_bsr_InstrF.rpt]
report_cell_util "MemWriteM_bsr" [file join $rpt_dir util_bsr_MemWriteM.rpt]
report_cell_util "DataAdrM_bsr"  [file join $rpt_dir util_bsr_DataAdrM.rpt]
report_cell_util "WriteDataM_bsr"[file join $rpt_dir util_bsr_WriteDataM.rpt]
report_cell_util "ReadDataM_bsr" [file join $rpt_dir util_bsr_ReadDataM.rpt]

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
