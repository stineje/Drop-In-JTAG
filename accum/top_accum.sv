///////////////////////////////////////////
// top_accum.sv
//
// Purpose: Drop-In-JTAG demonstration using a simple 8-bit accumulator DUT.
//
// The accumulator runs ADD 0x06 every dbgclk cycle, reaching 0x2A after 7 steps.
// op and operand are hardwired constants inside the accumulator module so the
// BSR always captures known, predictable values for those fields.
//
// BSR scan chain (tdi -> ... -> tdo), 29 bits total:
//   chain0 -> op_bsr(2)      -> chain1
//   chain1 -> operand_bsr(8) -> chain2
//   chain2 -> acc_bsr(8)     -> chain3
//   chain3 -> result_bsr(8)  -> chain4
//   chain4 -> flags_bsr(3)   -> chain5 -> tdo
//
// TDO exits flags first, op last.
// Capture order (tdovector LSB = first bit out):
//   [2:0]   flags  {overflow, carry, zero}  parallel_in[0]=zero
//   [10:3]  result [7:0]
//   [18:11] acc    [7:0]
//   [26:19] operand[7:0]
//   [28:27] op     [1:0]
//
// Copyright (C) 2021-25 Harvey Mudd College & Oklahoma State University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
////////////////////////////////////////////////////////////////////////////////////////////////

module top_accum (
   input  logic tck, tdi, tms, trst,
   output logic tdo,
   input  logic sysclk,
   input  logic sys_reset,
   output logic success, fail
);

   logic bsr_chain0, bsr_chain1, bsr_chain2,
         bsr_chain3, bsr_chain4, bsr_chain5;
   logic bsr_tdi, bsr_clk, bsr_update, bsr_shift, bsr_mode, bsr_tdo;
   logic dbgclk, dm_reset, reset;

   assign reset      = sys_reset || dm_reset;
   assign bsr_chain0 = bsr_tdi;
   assign bsr_tdo    = bsr_chain5;

   // DUT outputs (observe-only BSR inputs)
   logic [7:0] acc_internal;
   logic [7:0] result_internal;
   logic       zero_internal, carry_internal, overflow_internal;

   // DUT inputs — hardwired constants, also fed into input BSRs as parallel_in
   // so SAMPLE/PRELOAD captures the known values for op and operand.
   logic [1:0] op_internal;
   logic [7:0] operand_internal;
   assign op_internal      = 2'b00;   // ADD
   assign operand_internal = 8'h06;   // +6 each cycle -> 0x2A in 7 steps

   // BSR parallel_out (not fed back — observe only)
   logic [1:0] op_bsr_out;
   logic [7:0] operand_bsr_out;
   logic [7:0] acc_bsr_out;
   logic [7:0] result_bsr_out;
   logic [2:0] flags_bsr_out;

   // JTAG test logic
   jtag_test_logic jtag (
      .tck(tck), .tms(tms), .tdi(tdi), .trst(trst), .tdo(tdo),
      .bsr_tdi(bsr_tdi), .bsr_clk(bsr_clk),
      .bsr_update(bsr_update), .bsr_shift(bsr_shift),
      .bsr_mode(bsr_mode), .bsr_tdo(bsr_tdo),
      .sys_clk(sysclk), .dbg_clk(dbgclk), .dm_reset(dm_reset)
   );

   // Accumulator DUT
   accumulator dut (
      .clk(dbgclk), .reset(reset),
      .op(op_internal), .operand(operand_internal),
      .acc(acc_internal), .result(result_internal),
      .zero(zero_internal), .carry(carry_internal), .overflow(overflow_internal)
   );

   // PHY debug: success when acc reaches 0x2A
   always @(posedge sysclk or posedge reset) begin
      if (reset) begin success <= 0; fail <= 0; end
      else begin
         if (acc_internal === 8'h2A) success <= 1;
         if (acc_internal === 8'hFF) fail    <= 1;
      end
   end

   // Boundary scan registers
   bsr #(.WIDTH(2)) op_bsr (
      .clk(bsr_clk), .update_dr(bsr_update), .shift_dr(bsr_shift), .mode(bsr_mode),
      .tdi(bsr_chain0), .tdo(bsr_chain1),
      .parallel_in(op_internal), .parallel_out(op_bsr_out)
   );

   bsr #(.WIDTH(8)) operand_bsr (
      .clk(bsr_clk), .update_dr(bsr_update), .shift_dr(bsr_shift), .mode(bsr_mode),
      .tdi(bsr_chain1), .tdo(bsr_chain2),
      .parallel_in(operand_internal), .parallel_out(operand_bsr_out)
   );

   bsr #(.WIDTH(8)) acc_bsr (
      .clk(bsr_clk), .update_dr(bsr_update), .shift_dr(bsr_shift), .mode(bsr_mode),
      .tdi(bsr_chain2), .tdo(bsr_chain3),
      .parallel_in(acc_internal), .parallel_out(acc_bsr_out)
   );

   bsr #(.WIDTH(8)) result_bsr (
      .clk(bsr_clk), .update_dr(bsr_update), .shift_dr(bsr_shift), .mode(bsr_mode),
      .tdi(bsr_chain3), .tdo(bsr_chain4),
      .parallel_in(result_internal), .parallel_out(result_bsr_out)
   );

   bsr #(.WIDTH(3)) flags_bsr (
      .clk(bsr_clk), .update_dr(bsr_update), .shift_dr(bsr_shift), .mode(bsr_mode),
      .tdi(bsr_chain4), .tdo(bsr_chain5),
      .parallel_in({overflow_internal, carry_internal, zero_internal}),
      .parallel_out(flags_bsr_out)
   );

endmodule // top_accum


///////////////////////////////////////////
// accumulator
//
// op encoding: 2'b00=ADD  2'b01=SUB  2'b10=AND  2'b11=OR
///////////////////////////////////////////
module accumulator (
   input  logic       clk,
   input  logic       reset,
   input  logic [1:0] op,
   input  logic [7:0] operand,
   output logic [7:0] acc,
   output logic [7:0] result,
   output logic       zero,
   output logic       carry,
   output logic       overflow
);
   logic [8:0] full_result;

   always_comb begin
      case (op)
         2'b00: full_result = {1'b0, acc} + {1'b0, operand};
         2'b01: full_result = {1'b0, acc} - {1'b0, operand};
         2'b10: full_result = {1'b0, acc  & operand};
         2'b11: full_result = {1'b0, acc  | operand};
         default: full_result = 9'b0;
      endcase
      result   = full_result[7:0];
      carry    = full_result[8];
      zero     = (result == 8'h00);
      overflow = (op == 2'b00) ? (~acc[7] & ~operand[7] &  result[7])
                                | ( acc[7] &  operand[7] & ~result[7])
               : (op == 2'b01) ? (~acc[7] &  operand[7] &  result[7])
                                | ( acc[7] & ~operand[7] & ~result[7])
               : 1'b0;
   end

   always_ff @(posedge clk or posedge reset) begin
      if (reset) acc <= 8'h00;
      else       acc <= result;
   end

endmodule // accumulator

