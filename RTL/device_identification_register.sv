// See 1149.1 - 12.1.1 for details on providing optional USERCODE instruction support
module device_identification_register 
  (`include "defines.sv"
   input logic  tdi,
   input logic  clockDR,
   input logic  captureDR,
   output logic tdo);
   
   localparam device_id = `DEVICE_ID;
   logic [32:0] shift_reg;
   assign shift_reg[32] = tdi;
   assign tdo = shift_reg[0];
   
   genvar 	i;
   for (i = 0; i < 32; i = i + 1) begin
      always @(posedge clockDR) begin
         shift_reg[i] <= captureDR ? device_id[i] : shift_reg[i+1];
      end
   end

   assert property (@(negedge clockDR) 
		    captureDR |-> shift_reg[0] == 1'b1) 
     else $error("Violation IEEE 1149.1-2013 12.1.1: LSB of identification code must be 1.");

endmodule // device_identification_register
