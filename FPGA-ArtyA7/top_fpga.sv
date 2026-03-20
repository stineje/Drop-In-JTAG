///////////////////////////////////////////
// top.sv
//
// Written: james.stine@okstate.edu, jacob.pease@okstate.edu, matotto@okstate.edu 28 July 2025
// Modified: Refactored MMCM into clk_gen module
//
// Purpose: top-level design for JTAG Drop-in-Test (Arty A7-100T)
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
//
// Copyright (C) 2021-25 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may not use this file
// except in compliance with the License, or, at your option, the Apache License version 2.0. You
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the
// License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
// either express or implied. See the License for the specific language governing permissions
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module top #(parameter IMEM_INIT_FILE="riscvtest.mem")
   (// jtag logic
   input logic  tck, tdi, tms, trst,
   output logic tdo,
   // dut logic - sysclk is the raw 100MHz board clock from Arty A7-100T
   input logic  sysclk,
   input logic  sys_reset,
   output logic success, fail  // PHY DEBUG
);

   logic sysclk_25;
   logic clk_locked;

   // Allowable output frequencies are determined by the MMCM VCO frequency and the
   // DIVIDE_F parameter.  The VCO frequency is fixed by CLKIN_PERIOD and MULT_F
   // (default: 100MHz * 8 = 800MHz) and must stay within the Artix-7 legal range of
   // 600-1200MHz.  DIVIDE_F then divides the VCO down to the target output frequency
   // and must be between 1.0 and 128.0 in increments of 0.125.  The output frequency
   // must also stay within 4.69MHz (MMCM minimum) and 464MHz (practical BUFG/routing
   // maximum on Artix-7).
   //
   // With the default VCO of 800MHz, common round-number output frequencies are:
   //
   //   DIVIDE_F  |  Output Frequency
   //   ----------+------------------
   //      4.0    |    200 MHz
   //      5.0    |    160 MHz
   //      8.0    |    100 MHz
   //     10.0    |     80 MHz
   //     16.0    |     50 MHz
   //     20.0    |     40 MHz
   //     25.0    |     32 MHz
   //     32.0    |     25 MHz   (default)
   //     40.0    |     20 MHz
   //     50.0    |     16 MHz
   //     64.0    |   12.5 MHz
   //     80.0    |     10 MHz
   //    100.0    |      8 MHz
   //    128.0    |   6.25 MHz
   //
   // For frequencies not in this table, adjust MULT_F to target a different VCO
   // frequency (keeping it within 600-1200MHz) and choose DIVIDE_F accordingly.
   clk_gen #(
      .CLKIN_PERIOD (10.0),   // 100MHz board clock = 10ns
      .MULT_F       (8.0),    // VCO = 800MHz (within Artix-7 600-1200MHz range)
      .DIVIDE_F     (32.0)    // Fout = 800MHz / 32 = 25MHz
   ) clk_inst (
      .clk_in  (sysclk),
      .reset   (sys_reset),
      .clk_out (sysclk_25),
      .locked  (clk_locked)
   );

   // Hold entire design in reset until MMCM has locked
   logic internal_reset;
   assign internal_reset = sys_reset | ~clk_locked;

   // -------------------------------------------------------

   logic bsr_chain0;
   logic bsr_chain1;
   logic bsr_chain2;
   logic bsr_chain3;
   logic bsr_chain4;
   logic bsr_chain5;
   logic bsr_chain6;

   logic bsr_tdi, bsr_clk, bsr_update, bsr_shift, bsr_mode, bsr_tdo;

   logic dbgclk;
   logic dm_reset;
   logic reset;

   logic [31:0] PCF;
   logic [31:0] InstrF;
   logic        MemWriteM;
   logic [31:0] DataAdrM;
   logic [31:0] WriteDataM;
   logic [31:0] ReadDataM;

   logic [31:0] PCF_internal;
   logic [31:0] InstrF_internal;
   logic        MemWriteM_internal;
   logic [31:0] DataAdrM_internal;
   logic [31:0] WriteDataM_internal;
   logic [31:0] ReadDataM_internal;

   assign reset = internal_reset | dm_reset;

   assign bsr_chain0 = bsr_tdi;
   assign bsr_tdo    = bsr_chain6;

   // PHY DEBUG
   always @(posedge sysclk_25 or posedge reset) begin
      if (reset) begin
         success <= 0;
         fail    <= 0;
      end else if (MemWriteM) begin
         if (DataAdrM === 100 & WriteDataM === 25)
            success <= 1;
         else if (DataAdrM === 100 & WriteDataM !== 25)
            fail <= 1;
      end
   end
   // end PHY DEBUG

   // test logic ////////////////////////////////////////////////////
   jtag_test_logic jtag (
      .tck       (tck),
      .tms       (tms),
      .tdi       (tdi),
      .trst      (trst),
      .tdo       (tdo),
      .bsr_tdi   (bsr_tdi),
      .bsr_clk   (bsr_clk),
      .bsr_update(bsr_update),
      .bsr_shift (bsr_shift),
      .bsr_mode  (bsr_mode),
      .bsr_tdo   (bsr_tdo),
      .sys_clk   (sysclk_25),
      .dbg_clk   (dbgclk),
      .dm_reset  (dm_reset)
   );

   // RISC-V Core ///////////////////////////////////////////////////
   riscv core (
      .clk        (dbgclk),
      .reset      (reset),
      .PCF        (PCF_internal),
      .InstrF     (InstrF_internal),
      .MemWriteM  (MemWriteM_internal),
      .ALUResultM (DataAdrM_internal),
      .WriteDataM (WriteDataM_internal),
      .ReadDataM  (ReadDataM_internal)
   );

   // Core memory ///////////////////////////////////////////////////
   imem #(.MEM_INIT_FILE(IMEM_INIT_FILE)) imem (PCF, InstrF);
   dmem dmem (dbgclk, MemWriteM, DataAdrM, WriteDataM, ReadDataM);

   // boundary scan registers ///////////////////////////////////////
   bsr #(.WIDTH(32)) PCF_bsr (
      .clk         (bsr_clk),
      .update_dr   (bsr_update),
      .shift_dr    (bsr_shift),
      .mode        (bsr_mode),
      .tdi         (bsr_chain0),
      .tdo         (bsr_chain1),
      .parallel_in (PCF_internal),
      .parallel_out(PCF)
   );

   bsr #(.WIDTH(32)) InstrF_bsr (
      .clk         (bsr_clk),
      .update_dr   (bsr_update),
      .shift_dr    (bsr_shift),
      .mode        (bsr_mode),
      .tdi         (bsr_chain1),
      .tdo         (bsr_chain2),
      .parallel_in (InstrF),
      .parallel_out(InstrF_internal)
   );

   bsr #(.WIDTH(1)) MemWriteM_bsr (
      .clk         (bsr_clk),
      .update_dr   (bsr_update),
      .shift_dr    (bsr_shift),
      .mode        (bsr_mode),
      .tdi         (bsr_chain2),
      .tdo         (bsr_chain3),
      .parallel_in (MemWriteM_internal),
      .parallel_out(MemWriteM)
   );

   bsr #(.WIDTH(32)) DataAdrM_bsr (
      .clk         (bsr_clk),
      .update_dr   (bsr_update),
      .shift_dr    (bsr_shift),
      .mode        (bsr_mode),
      .tdi         (bsr_chain3),
      .tdo         (bsr_chain4),
      .parallel_in (DataAdrM_internal),
      .parallel_out(DataAdrM)
   );

   bsr #(.WIDTH(32)) WriteDataM_bsr (
      .clk         (bsr_clk),
      .update_dr   (bsr_update),
      .shift_dr    (bsr_shift),
      .mode        (bsr_mode),
      .tdi         (bsr_chain4),
      .tdo         (bsr_chain5),
      .parallel_in (WriteDataM_internal),
      .parallel_out(WriteDataM)
   );

   bsr #(.WIDTH(32)) ReadDataM_bsr (
      .clk         (bsr_clk),
      .update_dr   (bsr_update),
      .shift_dr    (bsr_shift),
      .mode        (bsr_mode),
      .tdi         (bsr_chain5),
      .tdo         (bsr_chain6),
      .parallel_in (ReadDataM),
      .parallel_out(ReadDataM_internal)
   );

endmodule // top
