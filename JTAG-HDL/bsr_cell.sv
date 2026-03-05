///////////////////////////////////////////
// bsr_cell.sv
//
// Written: james.stine@okstate.edu, jacob.pease@okstate.edu, matotto@okstate.edu 28 July 2025
// Modified: 
//
// Purpose: IEEE 1149.1 - 8.5.1 example boundary scan register
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

module bsr_cell (
    input logic  clk,
    input logic	 update_dr, 
    input logic  shift_dr, 
    input logic  mode,
    input logic  parallel_in, 
    input logic  sequential_in,
    output logic parallel_out, 
    output logic sequential_out
);

   logic 	 state_in, state_out;
   
   assign state_in = shift_dr ? sequential_in : parallel_in;
   
   always @(posedge clk)
     sequential_out <= state_in;
   
   always @(posedge update_dr)  // 11.3.1 (b)
     state_out <= sequential_out;
   
   assign parallel_out = mode ? state_out : parallel_in;
   
endmodule // bsr_cell
