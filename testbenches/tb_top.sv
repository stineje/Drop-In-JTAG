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
   logic [160:0] tdovector; // moved on top for easy viewing

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

   // Scan chains are fundamentally bit-serial:  Scan chains are built from individual flip-flops.
   // Each flip-flop shifts one bit, and there is no concept of “32-bit word ordering” inside the chain.
   // So the scan chain naturally behaves like: bit0 -> bit1 -> bit2 -> ... -> bitN
   // So when a 32-bit signal is scanned, it just becomes 32 individual bits in the chain, and 
   // whichever bit happens to be closest to TDO comes out first.  
   function automatic [31:0] bitrev32(input [31:0] x);
      integer k;
      begin
	 for (k = 0; k < 32; k = k + 1)
           bitrev32[k] = x[31-k];
      end
   endfunction   
   
   initial begin
      // logic [160:0] tdovector;

      // Puts TAP in modesl starting from reset
      static logic [11:0] halt_tmsvector = 'b101100_0001_10;
      static logic [11:0] halt_tdivector = 'b000000_0110_00; // LSB first
      
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
      for (i=160; i >= 0; i=i-1) begin
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
               bitrev32(tdovector[160:129]), bitrev32(tdovector[128:97]), bitrev32(tdovector[96:65]),
               tdovector[64], bitrev32(tdovector[63:32]), bitrev32(tdovector[31:0]));      
      $stop;
   end
   
endmodule // testbench
