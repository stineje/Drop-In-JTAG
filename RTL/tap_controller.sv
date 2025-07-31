///////////////////////////////////////////
// tap_conntroller.sv
//
// Written: matotto@okstate.edu 13 Novemeber 2023
// Modified: 
//
// Purpose: IEEE 1149.1 tap controller based on standard
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

module tap_controller 
  (input  logic tck, trst, tms,
   output logic reset,
   output logic tdo_en,
   output logic shiftIR,
   output logic captureIR,
   output logic clockIR,
   output logic updateIR,
   output logic shiftDR,
   output logic captureDR,
   output logic clockDR,
   output logic updateDR,
//   output logic updateDRstate,
   output logic select);

   (* mark_debug = "true" *) logic [3:0] state;

   always @(posedge tck, negedge trst) begin
      if (~trst) begin
         state <= 4'b1111;
      end else begin
         state[0] <= ~tms && ~state[2] && state[0] || tms && ~state[1] || tms && ~state[0] || tms && state[3] && state[2];
         state[1] <= ~tms && state[1] && ~state[0] || 
		     ~tms && ~state[2] || ~tms && ~state[3] && state[1] || ~tms && ~state[3] && ~state[0] || 
		     tms && state[2] && ~state[1] || tms && state[3] && state[2] && state[0];
         state[2] <= state[2] && ~state[1] || state[2] && state[0] || tms && ~state[1];
         state[3] <= state[3] && ~state[2] || state[3] && state[1] || ~tms && state[2] && ~state[1] || 
		     ~state[3] && state[2] && ~state[1] && ~state[0];
      end
   end

   always @(negedge tck, negedge trst) begin
      if (~trst) begin
         reset <= 1'b0;
         tdo_en <= 1'b0;
         shiftIR <= 1'b0;
         captureIR <= 1'b0;
         shiftDR <= 1'b0;
         captureDR <= 1'b0;
      end else begin
         reset <= ~&state;
         tdo_en <= ~state[0] && state[1] && ~state[2] && state[3] || ~state[0] && state[1] && ~state[2] && ~state[3]; // shiftIR || shiftDR;
         shiftIR <= ~state[0] && state[1] && ~state[2] && state[3];
         captureIR <= ~state[0] && state[1] && state[2] && state[3];
         shiftDR <= ~state[0] && state[1] && ~state[2] && ~state[3];
         captureDR <= ~state[0] && state[1] && state[2] && ~state[3]; // TODO: && this with tck unless needed for one cycle
      end
   end

   assign clockIR = tck || state[0] || ~state[1] || ~state[3];
   assign updateIR = ~tck && state[0] && ~state[1] && state[2] && state[3];
   assign clockDR = tck || state[0] || ~state[1] || state[3];
   //assign updateDR = ~tck && updateDRstate;
   assign updateDR = ~tck && state[0] && ~state[1] && state[2] && ~state[3];
   //assign updateDRstate = state[0] && ~state[1] && state[2] && ~state[3];
   assign select = state[3];

endmodule  // tap_controller
