# Drop-In-JTAG — 8-bit Accumulator Example

This directory contains a self-contained demonstration of the Drop-In-JTAG
infrastructure using a simple 8-bit accumulator/ALU as the device under test
(DUT), in place of the RISC-V core used in the main project.  It requires no
memory initialization file and is designed to be easy to follow, simulate, and
modify.

## Files

| File | Purpose |
|------|---------|
| `top_accum.sv` | Top-level wrapper: accumulator DUT + JTAG test logic + BSR chain |
| `tb_top_accum.sv` | QuestaSim testbench |
| `top_accum_complete.do` | ModelSim/QuestaSim run script |

The JTAG infrastructure itself (`jtag_test_logic.sv`, `tap_controller.sv`,
`bsr.sv`, etc.) lives in `../JTAG-HDL/` and is shared with the main project.

## The DUT — 8-bit Accumulator

The accumulator performs one ALU operation per `dbgclk` rising edge,
accumulating the result back into itself each cycle.

```
op  operand
 |    |
 v    v
[  ALU  ] --> result (combinational)
    |
    v
[  acc  ] <-- clocked on dbgclk
    |
    +------> acc (registered output)
```

The ALU operation is selected by `op`:

| `op` | Operation |
|------|-----------|
| `2'b00` | ADD — `acc <= acc + operand` |
| `2'b01` | SUB — `acc <= acc - operand` |
| `2'b10` | AND — `acc <= acc & operand` |
| `2'b11` | OR  — `acc <= acc \| operand` |

In this example both `op` and `operand` are hardwired constants inside
`top_accum.sv`:

```systemverilog
assign op_internal      = 2'b00;   // ADD
assign operand_internal = 8'h06;   // +6 every cycle
```

Starting from reset (`acc=0x00`), the accumulator reaches `0x2A` (42) after
exactly 7 `dbgclk` cycles: 7 × 6 = 42.

## The BSR Chain

Five boundary scan registers (BSRs) wrap the DUT's inputs and outputs,
forming a 29-bit serial chain:

```
bsr_tdi
   |
   v
[op_bsr    2b] --> op_internal (DUT input)
   |
   v
[operand_bsr 8b] --> operand_internal (DUT input)
   |
   v
[acc_bsr    8b] <-- acc_internal (DUT output, observe only)
   |
   v
[result_bsr 8b] <-- result_internal (combinational, observe only)
   |
   v
[flags_bsr  3b] <-- {overflow, carry, zero} (observe only)
   |
   v
bsr_tdo --> TDO
```

Total chain length: 2 + 8 + 8 + 8 + 3 = **29 bits**.

During `SAMPLE_PRELOAD`, the BSR cells capture the live pin values on
`Capture-DR` and shift them out LSB-first through `TDO` during `Shift-DR`.
Because `flags_bsr` is at the end of the chain (closest to `TDO`), its bits
exit first.

### Scan readback layout

Bits are captured into `tdovector` with `tdovector[0]` = first bit out of TDO:

```
tdovector[0]     = zero flag
tdovector[1]     = carry flag
tdovector[2]     = overflow flag
tdovector[10:3]  = result[7:0]
tdovector[18:11] = acc[7:0]
tdovector[26:19] = operand[7:0]
tdovector[28:27] = op[1:0]
```

## How `bsr_clk` Works

Understanding `bsr_clk` is key to getting the scan right:

```systemverilog
assign bsr_clk = (tck & clk_dr) | ~bsr_enable;
assign bsr_enable = sample_preload | extest | intest | clamp;
```

When no BSR instruction is loaded (`bsr_enable=0`), `bsr_clk` is stuck
**HIGH**.  Since `bsr_cell` registers on `posedge bsr_clk`, a stuck-high clock
produces no rising edges — the BSR shift registers never move.

**The BSR only clocks when a BSR instruction (SAMPLE_PRELOAD, EXTEST, etc.) is
active.**  This means `SAMPLE_PRELOAD` must be loaded into the IR *before*
entering `Capture-DR`, not after.

## Simulation — Correct JTAG Sequence

The testbench follows this sequence:

```
1. Free-run accumulator until acc_internal == 0x2A
2. HALT IR scan    — gates dbgclk, freezes the accumulator
3. TLR flush       — 5× tms=1, resets TAP to Test-Logic-Reset
4. SAMPLE_PRELOAD IR scan — loads SP instruction, arms bsr_enable
5. Capture-DR      — BSR cells latch live (frozen) pin values
6. Shift-DR × 29   — clock out the 29-bit chain into tdovector
7. Decode and check
```

### Why HALT before SAMPLE_PRELOAD?

If SAMPLE_PRELOAD is loaded first, the accumulator continues running during
the HALT IR scan (~12 TCK cycles ≈ 240 ns), so the value captured by the BSR
is not the one that triggered the halt condition.  Loading HALT first freezes
`dbgclk` via the debug FSM synchronizer chain, then SAMPLE_PRELOAD arms the
BSR for a clean snapshot of the frozen state.

### IR scan vector format

The IR is 4 bits wide.  Each IR scan uses a 12-bit TMS/TDI vector driven
MSB-first (bit 11 first) on each falling edge of TCK:

```
bit[11]=0  Test-Logic-Reset -> Run-Test/Idle
bit[10]=1  RTI              -> Select-DR
bit[ 9]=1  Select-DR        -> Select-IR
bit[ 8]=0  Select-IR        -> Capture-IR
bit[ 7]=0  Capture-IR       -> Shift-IR        (don't-care on TDI)
bit[ 6]=0  Shift-IR         -> Shift-IR        (opcode bit 0, LSB first)
bit[ 5]=0  Shift-IR         -> Shift-IR        (opcode bit 1)
bit[ 4]=0  Shift-IR         -> Shift-IR        (opcode bit 2)
bit[ 3]=1  Shift-IR         -> Exit1-IR        (opcode bit 3)
bit[ 2]=1  Exit1-IR         -> Update-IR
bit[ 1]=0  Update-IR        -> Run-Test/Idle
bit[ 0]=1  RTI              -> Select-DR       <- TAP rests here
```

The opcode occupies TDI bits **[6:3]**, shifted LSB-first:

| Instruction | Opcode | TDI vector |
|-------------|--------|------------|
| HALT | `4'b0110` | `12'b000000110000` |
| SAMPLE_PRELOAD | `4'b0010` | `12'b000000100000` |
| EXTEST | `4'b0011` | `12'b000000110000` |
| RESUME | `4'b1000` | `12'b000010000000` |

## Expected Output

```
Reset deasserted - accumulator free-running
acc = 0x2A - halting
HALTing system logic
Loading SAMPLE/PRELOAD
Scanning DR (29 bits)
Returning to Test-Logic-Reset
------------------------------------------------------------
BSR Scan Readback
  op       : 00
  operand  : 0x06  (6)
  acc      : 0xXX  (some value >= 0x2A)
  result   : 0xXX  (acc + 0x06)
  flags    : zero=0  carry=0  overflow=0
------------------------------------------------------------
All checks PASSED
```

The captured `acc` will typically be a few steps past `0x2A` because the
accumulator advances during the HALT IR scan before `dbgclk` gates.  The
testbench verifies `result == acc + operand` rather than an exact `acc` value.

## PHY Debug Indicators

The top-level exposes `success` and `fail` output signals that can be probed
on an FPGA without a JTAG connection:

| Signal | Condition |
|--------|-----------|
| `success` | `acc_internal` reached `0x2A` |
| `fail` | `acc_internal` reached `0xFF` (unexpected wraparound) |

## Running the Simulation

```bash
cd Drop-In-JTAG/accum
vsim -do top_accum_complete.do -c      # batch mode
vsim -do top_accum_complete.do         # GUI mode
```