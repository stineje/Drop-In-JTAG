# refresh_sources.tcl
# Source this inside Vivado from the jtag1 project:
#   source refresh_sources.tcl

set proj_dir [file normalize [pwd]]
set jtag_hdl_dir [file normalize [file join $proj_dir .. JTAG-HDL]]
set riscv_pipe_dir [file normalize [file join $proj_dir .. RISCV_pipe]]

puts "Project dir      : $proj_dir"
puts "JTAG HDL dir     : $jtag_hdl_dir"
puts "RISCV pipe dir   : $riscv_pipe_dir"

set srcset [get_filesets sources_1]

# Collect current project source files that came from these directories
set files_to_remove {}
foreach f [get_files -of_objects $srcset] {
    set n [file normalize $f]
    if {[string first $jtag_hdl_dir $n] == 0 || [string first $riscv_pipe_dir $n] == 0} {
        lappend files_to_remove $f
    }
}

if {[llength $files_to_remove] > 0} {
    puts "Removing old source references:"
    foreach f $files_to_remove {
        puts "  $f"
    }
    remove_files -fileset $srcset $files_to_remove
} else {
    puts "No existing sources from ../JTAG-HDL or ../RISCV_pipe were found in sources_1."
}

# Gather HDL files
set new_files {}

foreach pattern {
    *.sv
    *.v
    *.vh
    *.svh
    *.vhd
    *.vhdl
} {
    foreach f [glob -nocomplain -directory $jtag_hdl_dir $pattern] {
        lappend new_files [file normalize $f]
    }
    foreach f [glob -nocomplain -directory $riscv_pipe_dir $pattern] {
        lappend new_files [file normalize $f]
    }
}

# Remove duplicates
set new_files [lsort -unique $new_files]

if {[llength $new_files] == 0} {
    error "No HDL files found in $jtag_hdl_dir or $riscv_pipe_dir"
}

puts "Adding source files:"
foreach f $new_files {
    puts "  $f"
}

add_files -fileset $srcset $new_files
update_compile_order -fileset $srcset

puts "Done refreshing sources."
