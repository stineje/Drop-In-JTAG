///////////////////////////////////////////
// top.sv
//
// Written: james.stine@okstate.edu, jacob.pease@okstate.edu, matotto@okstate.edu 28 July 2025
// Modified: Added MMCM to divide 100MHz board clock to 25MHz
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
   // dut logic — sysclk is now the raw 100MHz board clock
   input logic  sysclk,
   input logic  sys_reset,
   output logic success, fail  // PHY DEBUG
);

   // -------------------------------------------------------
   // MMCM: divide 100MHz board clock down to 25MHz
   //   VCO = 100MHz * CLKFBOUT_MULT_F(8) = 800MHz
   //   CLKOUT0 = 800MHz / CLKOUT0_DIVIDE_F(32) = 25MHz
   //   Both within Artix-7 MMCM VCO range (600–1200MHz)
   // -------------------------------------------------------
   logic clk_fb;          // MMCM feedback
   logic clk_25_unbuf;    // raw MMCM output (before BUFG)
   logic clk_locked;      // MMCM lock indicator
   logic sysclk_25;       // 25MHz clock used everywhere in design

   MMCME2_BASE #(
      .CLKIN1_PERIOD     (10.0),   // 100MHz input = 10ns period
      .CLKFBOUT_MULT_F   (8.0),    // VCO = 100 * 8 = 800MHz
      .CLKOUT0_DIVIDE_F  (32.0),   // 800 / 32 = 25MHz
      .CLKOUT0_DUTY_CYCLE(0.5),
      .CLKOUT0_PHASE     (0.0),
      .DIVCLK_DIVIDE     (1),
      .REF_JITTER1       (0.01),
      .STARTUP_WAIT      ("FALSE")
   ) mmcm_inst (
      .CLKIN1   (sysclk),
      .CLKFBIN  (clk_fb),
      .CLKFBOUT (clk_fb),
      .CLKOUT0  (clk_25_unbuf),
      .LOCKED   (clk_locked),
      // unused outputs
      .CLKOUT0B (), .CLKOUT1  (), .CLKOUT1B (),
      .CLKOUT2  (), .CLKOUT2B (), .CLKOUT3  (),
      .CLKOUT3B (), .CLKOUT4  (), .CLKOUT5  (),
      .CLKOUT6  (), .CLKFBOUTB(),
      .PWRDWN   (1'b0),
      .RST      (sys_reset)
   );

   // Route 25MHz through a global clock buffer
   BUFG bufg_25 (.I(clk_25_unbuf), .O(sysclk_25));

   // Hold design in reset until MMCM locks
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
   assign bsr_tdo = bsr_chain6;

   // PHY DEBUG
   always @(posedge sysclk_25 or posedge reset) begin
      if (reset) begin
         success <= 0;
         fail <= 0;
      end else if (MemWriteM) begin
         if(DataAdrM === 100 & WriteDataM === 25) begin
            success <= 1;
         end else if (DataAdrM === 100 & WriteDataM !== 25) begin
            fail <= 1;
         end
      end
   end
   // end PHY DEBUG

   // test logic ////////////////////////////////////////////////////
   jtag_test_logic jtag (.tck(tck),
          .tms(tms),
          .tdi(tdi),
          .trst(trst),
          .tdo(tdo),
          .bsr_tdi(bsr_tdi),
          .bsr_clk(bsr_clk),
          .bsr_update(bsr_update),
          .bsr_shift(bsr_shift),
          .bsr_mode(bsr_mode),
          .bsr_tdo(bsr_tdo),
          .sys_clk(sysclk_25),
          .dbg_clk(dbgclk),
          .dm_reset(dm_reset));

   // RISC-V Core ///////////////////////////////////////////////////
   riscv core (.clk(dbgclk),
          .reset(reset),
          .PCF(PCF_internal),
          .InstrF(InstrF_internal),
          .MemWriteM(MemWriteM_internal),
          .ALUResultM(DataAdrM_internal),
          .WriteDataM(WriteDataM_internal),
          .ReadDataM(ReadDataM_internal));

   // Core memory
   imem #(.MEM_INIT_FILE(IMEM_INIT_FILE)) imem (PCF, InstrF);
   dmem dmem (dbgclk, MemWriteM, DataAdrM, WriteDataM, ReadDataM);

   // boundary scan registers ///////////////////////////////////////
   bsr #(.WIDTH(32)) PCF_bsr (.clk(bsr_clk),
               .update_dr(bsr_update),
               .shift_dr(bsr_shift),
               .mode(bsr_mode),
               .tdi(bsr_chain0),
               .tdo(bsr_chain1),
               .parallel_in(PCF_internal),
               .parallel_out(PCF));

   bsr #(.WIDTH(32)) InstrF_bsr (.clk(bsr_clk),
             .update_dr(bsr_update),
             .shift_dr(bsr_shift),
             .mode(bsr_mode),
             .tdi(bsr_chain1),
             .tdo(bsr_chain2),
             .parallel_in(InstrF),
             .parallel_out(InstrF_internal));

   bsr #(.WIDTH(1)) MemWriteM_bsr (.clk(bsr_clk),
               .update_dr(bsr_update),
               .shift_dr(bsr_shift),
               .mode(bsr_mode),
               .tdi(bsr_chain2),
               .tdo(bsr_chain3),
               .parallel_in(MemWriteM_internal),
               .parallel_out(MemWriteM));

   bsr #(.WIDTH(32)) DataAdrM_bsr (.clk(bsr_clk),
               .update_dr(bsr_update),
               .shift_dr(bsr_shift),
               .mode(bsr_mode),
               .tdi(bsr_chain3),
               .tdo(bsr_chain4),
               .parallel_in(DataAdrM_internal),
               .parallel_out(DataAdrM));

   bsr #(.WIDTH(32)) WriteDataM_bsr (.clk(bsr_clk),
                 .update_dr(bsr_update),
                 .shift_dr(bsr_shift),
                 .mode(bsr_mode),
                 .tdi(bsr_chain4),
                 .tdo(bsr_chain5),
                 .parallel_in(WriteDataM_internal),
                 .parallel_out(WriteDataM));

   bsr #(.WIDTH(32)) ReadDataM_bsr (.clk(bsr_clk),
                .update_dr(bsr_update),
                .shift_dr(bsr_shift),
                .mode(bsr_mode),
                .tdi(bsr_chain5),
                .tdo(bsr_chain6),
                .parallel_in(ReadDataM),
                .parallel_out(ReadDataM_internal));

endmodule // top
