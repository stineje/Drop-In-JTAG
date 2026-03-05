///////////////////////////////////////////
// instruction_register.sv
//
// Written: james.stine@okstate.edu, jacob.pease@okstate.edu, matotto@okstate.edu 28 July 2025
// Modified: 
//
// Purpose: IR device
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

module instruction_register 
  (`include "defines.sv"
   input logic  tck_ir,
   input logic  tdi,
   input logic  tl_reset, 
   input logic  captureIR,
   input logic  updateIR,
   output logic tdo,
   output logic [`INST_COUNT-1:0] instructions);

   logic [`INST_REG_WIDTH:0] 	  shift_reg;
   logic [`INST_COUNT-1:0] 	  decoded;   
   
   assign shift_reg[`INST_REG_WIDTH] = tdi;
   assign tdo = shift_reg[0];
   
   // Shift register
   always @(posedge tck_ir) begin
      shift_reg[0] <= shift_reg[1] || captureIR;  // 7.1.1 (d)
   end
   genvar i;
   for (i = `INST_REG_WIDTH; i > 1; i = i - 1) begin
      always @(posedge tck_ir) begin
         shift_reg[i-1] <= shift_reg[i] && ~captureIR;  // 7.1.1 (e)
      end
    end
   
   // Instruction decoder
   // 8.1.1 (e)
   always_comb begin
      unique0 case (shift_reg[`INST_REG_WIDTH-1:0]) // TODO: check spec for default case behavior
        `E_BYPASS         : decoded <= `D_BYPASS;
        `E_SAMPLE_PRELOAD : decoded <= `D_SAMPLE_PRELOAD;
        `E_EXTEST         : decoded <= `D_EXTEST;
        `E_INTEST         : decoded <= `D_INTEST;
        `E_IDCODE         : decoded <= `D_IDCODE;
        `E_CLAMP          : decoded <= `D_CLAMP;
        `E_HALT           : decoded <= `D_HALT;
        `E_STEP           : decoded <= `D_STEP;
        `E_RESUME         : decoded <= `D_RESUME;
        `E_RESET          : decoded <= `D_RESET;
        default           : decoded <= 'bx;
      endcase
   end
   
   // Instruction reg
   always @(posedge updateIR or negedge tl_reset) begin
      if (~tl_reset)
        instructions <= `D_IDCODE;  // 7.2.1 (e,f)
      else if (updateIR)
        instructions <= decoded;
   end
   
endmodule // instruction_register
