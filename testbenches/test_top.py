#!/usr/bin/env python3

from pathlib import Path
import shutil

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.clock import Clock
from cocotb.triggers import Timer, ReadOnly, ReadWrite, ClockCycles, RisingEdge, FallingEdge


def extract_bits(val, high, low):
    """Extracts a slice of bits [high:low] from an integer."""
    mask = (1 << (high - low + 1)) - 1
    return (val >> low) & mask



@cocotb.test()
async def jtag_scan_test(dut):
    cocotb.start_soon(Clock(dut.sysclk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.tck, 100, unit="ns").start())

    # Initialize Test
    dut.tms.value = 1
    dut.tdi.value = 1
    dut.sys_reset.value = 1
    dut.trst.value = 0
    await ClockCycles(dut.tck, 5)
    dut.sys_reset.value = 0
    dut.trst.value = 1

    # Simulate the RISCV cpu
    dut._log.info("Waiting for program to complete...")
    while True:
        await FallingEdge(dut.sysclk)
        # Checking for final memwrite
        if dut.MemWriteM.value == 1:
            if dut.DataAdrM.value == 100 and dut.WriteDataM.value == 25:
                dut._log.info("Simulation succeeded")
                break
            elif dut.DataAdrM.value != 96:
                dut._log.info("Simulation failed")
                break


    dut._log.info("HALTing system logic")
    # shifts D_HALT into instruction register
    halt_tmsvector = 0b101100_0001_10
    halt_tdivector = 0b000000_0110_00

    for i in range(11, -1, -1):
        await FallingEdge(dut.tck)
        dut.tms.value = (halt_tmsvector >> i) & 1
        dut.tdi.value = (halt_tdivector >> i) & 1

    dut._log.info("Putting TAP in SAMPLE/PRELOAD, latching BSRs")
    sp_tmsvector = 0b1100_0001_1100
    sp_tdivector = 0b0000_0100_0000

    for i in range(11, -1, -1):
        await FallingEdge(dut.tck)
        dut.tms.value = (sp_tmsvector >> i) & 1
        dut.tdi.value = (sp_tdivector >> i) & 1


    dut._log.info("Scanning DR register")
    tdovector = 0
    for i in range(160):
        await FallingEdge(dut.tck)
        tdo_bit = int(dut.tdo.value)
        tdovector |= (tdo_bit << i)


    dut._log.info("Returning to test-logic reset")
    for i in range(10):
        await FallingEdge(dut.tck)
        dut.tdi.value = 1

    # Extract values, reverse bits, and print results
    read_data_m  = extract_bits(tdovector, 31, 0)
    write_data_m = extract_bits(tdovector, 63, 32)
    data_adr_m   = extract_bits(tdovector, 95, 64)
    mem_write_m  = extract_bits(tdovector, 96, 96)
    instr_f      = extract_bits(tdovector, 128, 97)
    pc_f         = extract_bits(tdovector, 160, 129)

    assert pc_f == 0x50, "Error: pc_f does not match reference value: 0x50"
    assert instr_f == 0x000210063, "Error: instr_f does not match reference value: 0x000210063"
    assert mem_write_m == 0x0, "Error: mem_write_m does not match reference value: 0x0"
    assert data_adr_m == 0x0, "Error: data_adr_m does not match reference value: 0x0"
    assert write_data_m == 0x19, "Error: write_data_m does not match reference value: 0x19"
    assert read_data_m == 0x0, "Error: read_data_m does not match reference value: 0x0"

    dut._log.info(f"\n==== Scan Results ====")
    dut._log.info(f"PCF: 0x{pc_f:08x}")
    dut._log.info(f"InstrF: 0x{instr_f:08x}")
    dut._log.info(f"MemWriteM: 0x{mem_write_m:b}")
    dut._log.info(f"DataAdrM: 0x{data_adr_m:08x}")
    dut._log.info(f"ReadDataM: 0x{read_data_m:08x}")
    dut._log.info(f"WriteDataM: 0x{write_data_m:08x}\n")



def test_runner():
    module_name = "top"
    sim = get_runner("verilator")
    
    sim_dir = Path(__file__).resolve().parent
    base_dir = sim_dir.parent
    rtldir = base_dir / "JTAG-HDL"
    riscv_dir = base_dir / "RISCV_pipe"
    mem_file = sim_dir / "riscvtest.mem"

    # Copying risccv program to sim directory
    build_dir = sim_dir / "sim_build"
    build_dir.mkdir(exist_ok=True)
    if mem_file.exists():
        shutil.copy(mem_file, build_dir)
    else:
        print(f"ERROR: Could not find memory file at {mem_file}")
        quit()

    sources = list(rtldir.glob("*.sv"))
    sources += list(riscv_dir.glob("*.sv"))

    sim.build(
        sources=sources,
        includes=[rtldir],
        hdl_toplevel=module_name,
        always=False,
        waves=True,
        build_args=[
            "-Wno-SELRANGE",
            "-Wno-WIDTH",
            "--trace-fst",
            "--trace-structs",
        ]
    )

    sim.test(
        hdl_toplevel=module_name,
        test_module=Path(__file__).stem,
        waves=True,
        gui=True
    )

if __name__ == "__main__":
    test_runner()