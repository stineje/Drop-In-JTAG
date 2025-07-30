module bypass_register 
  (input logic  tdi, 
   input logic 	clockDR, 
   input logic 	shiftDR,
   output logic tdo);

   always @(posedge clockDR) begin
      tdo <= tdi & shiftDR;   // 10.1.1 (b)
   end
   
endmodule // bypass_register
