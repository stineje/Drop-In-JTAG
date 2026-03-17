// `timescale 1ns/1ps
module testbench();

   integer       i;
   integer 	 errors;

   logic 	 tck;
   logic 	 trst;
   logic 	 tms;
   logic 	 tdi;
   logic 	 tdo;

   logic 	 tdo_ref;
   logic 	 tdo_sample;
   logic 	 clk;
   logic 	 reset;
   logic [160:0] tdovector;

   top dut (.tck(tck), .tdi(tdi), .tms(tms), .trst(trst), .tdo(tdo),
	    .sysclk(clk), .sys_reset(reset), .success(), .fail());

   // clocks
   initial begin
      clk = 1'b1;
      forever #1 clk = ~clk;
   end

   initial begin
      tck = 1'b1;
      forever #10 tck = ~tck;
   end

   // initialize test
   initial begin
      tms = 1'b1;
      tdi = 1'b1;

      reset <= 1;
      trst <= 0;
      # 22;
      reset <= 0;
      trst <= 1;
   end

   initial begin

      // Performs an IR scan (loads an instruction)
      // Assuming TAP starts in Test-Logic-Reset:      
      // Explanation 
      // 0 -> Run-Test/Idle
      // 1 -> Select-DR-Scan
      // 1 -> Select-IR-Scan
      // 0 -> Capture-IR
      // 0 -> Shift-IR
      // 0 -> Shift-IR
      // 0 -> Shift-IR
      // 0 -> Shift-IR
      // 1 -> Exit1-IR
      // 1 -> Update-IR
      // 0 -> Run-Test/Idle
      // 1 -> Select-DR-Scan      
      //
      // This sequence effectively initializes and positions
      // the TAP into a known "halted / ready" configuration.
      
      static logic [11:0] halt_tmsvector = 'b101100_0001_10;
      static logic [11:0] halt_tdivector = 'b000000_0110_00; // LSB first

      // Positions the TAP (navigation only, no shifting)
      // ============================================================
      // Shift Path Entry (Edit Mode)
      // ============================================================
      // This sequence drives TAP into Shift-DR or Shift-IR
      // where scan data can be inserted/extracted.
      // Explanation:
      // LSB-first TMS sequence: 0,0,1,1,1,0,0,0,0,0,1,1
      //
      // Assuming TAP starts in Test-Logic-Reset, this drives: 
      //   0 -> Run-Test/Idle
      //   0 -> Run-Test/Idle
      //   1 -> Select-DR-Scan
      //   1 -> Select-IR-Scan
      //   1 -> Test-Logic-Reset
      //   0 -> Run-Test/Idle
      //   0 -> Run-Test/Idle
      //   0 -> Run-Test/Idle
      //   0 -> Run-Test/Idle
      //   0 -> Run-Test/Idle
      //   1 -> Select-DR-Scan
      //   1 -> Select-IR-Scan
      //
      // Final TAP state: Select-IR-Scan

      static logic [11:0] sp_tmsvector = 'b1100_0001_1100;
      static logic [11:0] sp_tdivector = 'b0000_0100_0000; // LSB first

      while (1) begin
         @(negedge clk) begin
            if (dut.MemWriteM) begin
               if(dut.DataAdrM === 100 & dut.WriteDataM === 25) begin
                  $display("Simulation succeeded");
                  break;
               end else if (dut.DataAdrM != 96) begin
                  $display("Simulation failed");
                  break;
               end
            end
         end
      end // while (1)

      $display("HALTing system logic");
      for (i=11; i >= 0; i=i-1) begin
         @(negedge tck) begin
            tms <= halt_tmsvector[i];
            tdi <= halt_tdivector[i];
         end
      end

      $display("putting TAP in SAMPLE/PRELOAD");
      for (i=11; i >= 0; i=i-1) begin
         @(negedge tck) begin
            tms <= sp_tmsvector[i];
            tdi <= sp_tdivector[i];
         end
      end

      $display("Scanning DR register");
      for (i=0; i < 161; i=i+1) begin
         @(negedge tck) begin
            tdovector[i] <= tdo;
         end
      end

      $display("Returning to test-logic reset");
      for (i=0; i<10; i=i+1) begin
         @(negedge tck) begin
            tdi <= 1;
         end
      end

      $display("ReadDataM: %08h | WriteDataM: %08h | DataAdrM: %08h | MemWriteM: %b | InstrF: %08h | PCF: %08h",
               tdovector[31:0], tdovector[63:32], tdovector[95:64], tdovector[96], tdovector[128:97],
                tdovector[160:129]);
      $stop;
   end

endmodule // testbench
