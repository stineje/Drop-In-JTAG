# refresh_sources.tcl
# Run inside Vivado from the jtag1 project:
#   source refresh_sources.tcl

set proj_dir [file normalize [pwd]]
set jtag_hdl_dir [file normalize [file join $proj_dir .. JTAG-HDL]]
set riscv_pipe_dir [file normalize [file join $proj_dir .. RISCV_pipe]]
set srcset [get_filesets sources_1]

puts "Project dir    : $proj_dir"
puts "JTAG HDL dir   : $jtag_hdl_dir"
puts "RISCV pipe dir : $riscv_pipe_dir"

# Remove any existing files from sources_1 that look like HDL/source files
set files_to_remove {}
foreach f [get_files -of_objects $srcset] {
    set ext [string tolower [file extension $f]]
    if {$ext in {".sv" ".v" ".svh" ".vh" ".vhd" ".vhdl"}} {
        lappend files_to_remove $f
    }
}

if {[llength $files_to_remove] > 0} {
    puts "Removing existing HDL files from sources_1:"
    foreach f $files_to_remove { puts "  $f" }
    remove_files -fileset $srcset $files_to_remove
}

# Add source files by reference from parent dirs
set new_srcs {}
foreach dir [list $jtag_hdl_dir $riscv_pipe_dir] {
    foreach pattern [list *.sv *.v *.vhd *.vhdl] {
        foreach f [glob -nocomplain -directory $dir $pattern] {
            lappend new_srcs [file normalize $f]
        }
    }
}
set new_srcs [lsort -unique $new_srcs]

if {[llength $new_srcs] == 0} {
    error "No source HDL files found."
}

puts "Adding source files by reference:"
foreach f $new_srcs { puts "  $f" }
add_files -fileset $srcset $new_srcs

# Add include dirs
set include_dirs [list $jtag_hdl_dir $riscv_pipe_dir]
set_property include_dirs $include_dirs $srcset

# Add headers as global includes if present
set hdrs {}
foreach dir [list $jtag_hdl_dir $riscv_pipe_dir] {
    foreach pattern [list *.svh *.vh] {
        foreach f [glob -nocomplain -directory $dir $pattern] {
            lappend hdrs [file normalize $f]
        }
    }
}
set hdrs [lsort -unique $hdrs]
if {[llength $hdrs] > 0} {
    puts "Adding header files:"
    foreach f $hdrs { puts "  $f" }
    add_files -fileset $srcset $hdrs
    set_property is_global_include true [get_files $hdrs]
}

update_compile_order -fileset $srcset
report_compile_order -fileset $srcset

puts "Final sources_1 contents:"
foreach f [get_files -of_objects $srcset] {
    puts "  $f"
}
