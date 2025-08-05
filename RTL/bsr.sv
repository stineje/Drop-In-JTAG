///////////////////////////////////////////
// bsr.sv
//
// Written: james.stine@okstate.edu, jacob.pease@okstate.edu, matotto@okstate.edu 28 July 2025
// Modified: 
//
// Purpose: Boundary Scan Register
// 
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-25 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module bsr #(parameter WIDTH) (
    input logic 	     clk,
    input logic 	     update_dr,
    input logic 	     shift_dr,
    input logic 	     mode,			       
    input logic 	     tdi,
    output logic 	     tdo,			       
    input logic [WIDTH-1:0]  parallel_in,
    output logic [WIDTH-1:0] parallel_out
);

   logic [WIDTH:0] 	     shift_reg;
   
   assign shift_reg[WIDTH] = tdi;
   assign tdo = shift_reg[0];
   
   genvar 		     i;
   for (i=0; i<WIDTH; i=i+1) begin
      bsr_cell bsr_cell (.clk(clk),
			 .update_dr(update_dr),
			 .shift_dr(shift_dr),
			 .mode(mode),
			 .parallel_in(parallel_in[i]),
			 .parallel_out(parallel_out[i]),
			 .sequential_in(shift_reg[i+1]),
			 .sequential_out(shift_reg[i]));
   end

endmodule  // bsr
