#!/bin/bash
################################################################################
# swap_top.sh
#
# Written: james.stine@okstate.edu 2025
#
# Purpose: Swaps top.sv in ../JTAG-HDL between the original simulation version
#          and the FPGA version (with MMCM clock generation for Arty A7-100T).
#          When installing the FPGA version, clk_gen.sv is also copied across.
#          When restoring the original, clk_gen.sv is removed from the target.
#
# Usage:   ./swap_top.sh
#          ./swap_top.sh --fpga       (non-interactive)
#          ./swap_top.sh --orig       (non-interactive)
#          ./swap_top.sh --status     (show which version is currently active)
################################################################################

DEST="../JTAG-HDL/top.sv"
DEST_CLKGEN="../JTAG-HDL/clk_gen.sv"
ORIG="top_orig.sv"
FPGA="top_fpga.sv"
CLKGEN="clk_gen.sv"

# ── helpers ──────────────────────────────────────────────────────────────────

die() { echo "ERROR: $1" >&2; exit 1; }

check_sources() {
    [[ -f "$ORIG" ]]   || die "Cannot find $ORIG in $(pwd)"
    [[ -f "$FPGA" ]]   || die "Cannot find $FPGA in $(pwd)"
    [[ -f "$CLKGEN" ]] || die "Cannot find $CLKGEN in $(pwd)"
}

check_dest_dir() {
    local dir
    dir=$(dirname "$DEST")
    [[ -d "$dir" ]] || die "Destination directory $dir does not exist"
}

# Detect which version is currently active by checking for the clk_gen
# instantiation that only exists in the FPGA version
current_version() {
    if [[ ! -f "$DEST" ]]; then
        echo "none"
    elif grep -q "clk_gen" "$DEST" 2>/dev/null; then
        echo "fpga"
    else
        echo "orig"
    fi
}

show_status() {
    local ver
    ver=$(current_version)
    case "$ver" in
        fpga) echo "Active version: FPGA  (top_fpga.sv + clk_gen.sv  ->  ../JTAG-HDL/)" ;;
        orig) echo "Active version: ORIG  (top_orig.sv               ->  ../JTAG-HDL/)" ;;
        none) echo "Active version: none  ($DEST does not exist)" ;;
    esac
}

do_fpga() {
    cp "$FPGA"   "$DEST"        || die "Failed to copy $FPGA to $DEST"
    cp "$CLKGEN" "$DEST_CLKGEN" || die "Failed to copy $CLKGEN to $DEST_CLKGEN"
    echo "Installed: $FPGA   ->  $DEST"
    echo "Installed: $CLKGEN ->  $DEST_CLKGEN"
    echo "[FPGA / Arty A7-100T]"
}

do_orig() {
    cp "$ORIG" "$DEST" || die "Failed to copy $ORIG to $DEST"
    echo "Installed: $ORIG  ->  $DEST"
    if [[ -f "$DEST_CLKGEN" ]]; then
        rm "$DEST_CLKGEN" && echo "Removed:   $DEST_CLKGEN"
    fi
    echo "[simulation / original]"
}

# ── non-interactive flags ─────────────────────────────────────────────────────

case "$1" in
    --fpga)
        check_sources; check_dest_dir
        do_fpga
        exit 0 ;;
    --orig)
        check_sources; check_dest_dir
        do_orig
        exit 0 ;;
    --status)
        show_status
        exit 0 ;;
    "")
        ;; # fall through to interactive menu
    *)
        echo "Usage: $0 [--fpga | --orig | --status]"
        exit 1 ;;
esac

# ── interactive menu ──────────────────────────────────────────────────────────

check_sources
check_dest_dir

echo "============================================"
echo "  top.sv swap utility"
echo "  Target dir: $(dirname "$DEST")"
echo "============================================"
show_status
echo ""
echo "  1) Install FPGA version  (top_fpga.sv + clk_gen.sv)"
echo "  2) Install ORIG version  (top_orig.sv, removes clk_gen.sv)"
echo "  3) Show status"
echo "  q) Quit"
echo ""
read -rp "Choice: " choice

case "$choice" in
    1) do_fpga ;;
    2) do_orig ;;
    3) show_status ;;
    q|Q) echo "Bye." ;;
    *) echo "Unknown choice: $choice" ; exit 1 ;;
esac
