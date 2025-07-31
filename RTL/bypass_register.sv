///////////////////////////////////////////
// bypass_register.sv
//
// Written: james.stine@okstate.edu 28 July 2025
// Modified: 
//
// Purpose: Bypass Register for 1149.1
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

module bypass_register 
  (input logic  tdi, 
   input logic 	clockDR, 
   input logic 	shiftDR,
   output logic tdo);

   always @(posedge clockDR) begin
      tdo <= tdi & shiftDR;   // 10.1.1 (b)
   end
   
endmodule // bypass_register
