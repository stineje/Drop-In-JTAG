///////////////////////////////////////////
// tb_top_accum.sv
//
// Purpose: Testbench for top_accum.sv (Drop-In-JTAG accumulator demo)
//
// Sequence:
//   1. Wait for acc_internal == 0x2A
//   2. HALT -> freezes dbgclk
//   3. SAMPLE/PRELOAD IR scan -> arms bsr_enable
//   4. Capture-DR + Shift-DR, scan out 29 bits
//   5. Decode and check
//
// BSR chain exits TDO flags(3) first, op(2) last. LSB of each field first.
// tdovector decode (no offset, 29 bits):
//   [2:0]   flags: zero=[0], carry=[1], overflow=[2]
//   [10:3]  result[7:0]
//   [18:11] acc[7:0]
//   [26:19] operand[7:0]
//   [28:27] op[1:0]
//
// Note: acc captured will not be 0x2A exactly (accumulator advances
// during the HALT IR scan ~12 TCK cycles). We verify result=acc+operand instead.
//
// IR scan TDI vectors (12 bits, bit[11] first):
//   TMS: [11]=0 RTI,[10]=1 SelDR,[9]=1 SelIR,[8]=0 CapIR,
//        [7:4]=don't care,[6:3]=opcode LSB-first (4 ShiftIR clocks),
//        [3]=1 Exit1IR,[2]=1 UpdIR,[1]=0 RTI,[0]=1 SelDR
//   HALT=4'b0110 LSB-first -> bits[6:3]=0,1,1,0 -> 12'b000000110000
//   SP  =4'b0010 LSB-first -> bits[6:3]=0,1,0,0 -> 12'b000000100000
///////////////////////////////////////////

// `timescale 1ns/1ps
module tb_top_accum();

   integer i;
   integer errors;

   logic tck, trst, tms, tdi, tdo;
   logic clk, reset;

   logic [28:0] tdovector;

   logic [1:0] rb_op;
   logic [7:0] rb_operand, rb_acc, rb_result;
   logic       rb_zero, rb_carry, rb_overflow;

   top_accum dut (
      .tck(tck), .tdi(tdi), .tms(tms), .trst(trst), .tdo(tdo),
      .sysclk(clk), .sys_reset(reset),
      .success(), .fail()
   );

   initial begin clk = 1; forever #1  clk = ~clk; end
   initial begin tck = 1; forever #10 tck = ~tck;  end

   initial begin
      tms = 1; tdi = 1;
      reset <= 1; trst <= 1;
      #22;
      reset <= 0; trst <= 0;
   end

   initial begin

      static logic [11:0] halt_tmsvector = 12'b011000001101;
      static logic [11:0] halt_tdivector = 12'b000000110000; // HALT=4'b0110
      static logic [11:0] sp_tmsvector   = 12'b011000001101;
      static logic [11:0] sp_tdivector   = 12'b000000100000; // SP=4'b0010

      // Step 1: wait for acc_internal = 0x2A
      @(negedge reset);
      $display("Reset deasserted - accumulator free-running");
      while (1) begin
         @(negedge clk) begin
            if (dut.acc_internal === 8'h2A) begin
               $display("acc = 0x2A - halting"); break;
            end
         end
      end

      // Step 2: HALT - freeze dbgclk. TAP ends at Select-DR-Scan.
      $display("HALTing system logic");
      for (i = 11; i >= 0; i = i-1)
         @(negedge tck) begin tms <= halt_tmsvector[i]; tdi <= halt_tdivector[i]; end

      // Return to TLR before SP scan
      tms = 1; repeat(5) @(negedge tck);

      // Step 3: SAMPLE/PRELOAD IR scan. TAP ends at Select-DR-Scan.
      $display("Loading SAMPLE/PRELOAD");
      for (i = 11; i >= 0; i = i-1)
         @(negedge tck) begin tms <= sp_tmsvector[i]; tdi <= sp_tdivector[i]; end

      // Step 4: Capture-DR then Shift-DR, scan 29 bits
      $display("Scanning DR (29 bits)");
      @(negedge tck) tms <= 0;  // -> Capture-DR
      @(negedge tck) tms <= 0;  // -> Shift-DR
      for (i = 0; i < 29; i = i+1)
         @(negedge tck) begin
            tdovector[i] <= tdo;
            tms <= (i == 28) ? 1'b1 : 1'b0;
         end
      @(negedge tck) tms <= 1;  // Update-DR
      @(negedge tck) tms <= 0;  // RTI

      // Return to TLR
      $display("Returning to Test-Logic-Reset");
      tms = 1; repeat(5) @(negedge tck);

      // Step 5: Decode
      rb_zero     = tdovector[0];
      rb_carry    = tdovector[1];
      rb_overflow = tdovector[2];
      rb_result   = tdovector[10:3];
      rb_acc      = tdovector[18:11];
      rb_operand  = tdovector[26:19];
      rb_op       = tdovector[28:27];

      $display("------------------------------------------------------------");
      $display("BSR Scan Readback");
      $display("  op       : %02b", rb_op);
      $display("  operand  : 0x%02h  (%0d)", rb_operand, rb_operand);
      $display("  acc      : 0x%02h  (%0d)", rb_acc,     rb_acc);
      $display("  result   : 0x%02h  (%0d)", rb_result,  rb_result);
      $display("  flags    : zero=%b  carry=%b  overflow=%b",
               rb_zero, rb_carry, rb_overflow);
      $display("------------------------------------------------------------");

      // Step 6: checks
      errors = 0;
      if (rb_op !== 2'b00) begin
         $display("FAIL: op=%02b, expected 00 (ADD)", rb_op); errors++; end
      if (rb_operand !== 8'h06) begin
         $display("FAIL: operand=0x%02h, expected 0x06", rb_operand); errors++; end
      if (rb_result !== ((rb_acc + rb_operand) & 8'hFF)) begin
         $display("FAIL: result=0x%02h, expected acc+operand=0x%02h",
                  rb_result, (rb_acc + rb_operand) & 8'hFF); errors++; end
      if (rb_acc === 8'h00) begin
         $display("FAIL: acc is zero - BSR did not capture"); errors++; end

      if (errors == 0) $display("All checks PASSED");
      else             $display("%0d check(s) FAILED", errors);

      $stop;
   end

endmodule // tb_top_accum

