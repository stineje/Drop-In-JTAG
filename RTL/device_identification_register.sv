///////////////////////////////////////////
// device_identification_register.sv
//
// Written: james.stine@okstate.edu, jacob.pease@okstate.edu, matotto@okstate.edu 28 July 2025
// Modified: 
//
// Purpose: Device ID register for 1149.1 (12.1.1)
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
