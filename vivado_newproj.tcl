# ==== USER CONFIGURABLE VARIABLES ====
set project_name      "jtag2"
set project_dir       "./jtag2"
set top_module_name   "top"                              ;# Must match module name inside the top .sv file
set part_name         "xc7a100tcsg324-1"                 ;# target FPGA part
set source_dirs       [list "./RTL" "./RISCV_pipe/hdl"]  ;# HDL files
set xdc_file          "./Arty_Master.xdc"                ;# XDC constraint file

# ==== CREATE PROJECT ====
if {[file exists "$project_dir/$project_name.xpr"]} {
    puts "ERROR: Project already exists at $project_dir/$project_name.xpr"
    exit 1
} else {
    file mkdir $project_dir
    create_project $project_name $project_dir -part $part_name -force
}

# ==== IMPORT SYSTEMVERILOG FILES FROM MULTIPLE DIRECTORIES ====
puts "Importing SystemVerilog files using managed flow..."
set added_files 0
foreach dir $source_dirs {
    puts "  Processing directory: $dir"
    set sv_files [glob -nocomplain "$dir/*.sv"]

    if {[llength $sv_files] == 0} {
        puts "    No .sv files found in $dir"
    } else {
        foreach f $sv_files {
            import_files -fileset sources_1 $f
            puts "    Imported: $f"
            incr added_files
        }
    }
}
if {$added_files == 0} {
    puts "ERROR: No SystemVerilog files found in specified directories."
    exit 1
}

# ==== IMPORT XDC CONSTRAINT FILE ====
if {[file exists $xdc_file]} {
    import_files -fileset constrs_1 $xdc_file
    puts "XDC file imported: $xdc_file"
} else {
    puts "WARNING: XDC file not found at $xdc_file. Skipping constraint file."
}

# ==== SET TOP MODULE ====
puts "Setting top module to: $top_module_name"
set_property top $top_module_name [current_fileset]

# ==== SET FILE TYPES TO SYSTEMVERILOG ====
foreach f [get_files -of_objects [get_filesets sources_1]] {
    if {[string match "*.sv" $f]} {
        set_property file_type SystemVerilog $f
    }
}

# ==== UPDATE COMPILE ORDER ====
update_compile_order -fileset sources_1

# ==== (OPTIONAL) RUN SYNTHESIS AND IMPLEMENTATION ====
# launch_runs synth_1
# wait_on_run synth_1
# launch_runs impl_1
# wait_on_run impl_1

puts "Vivado project setup complete! Files are managed inside top.srcs"
