///////////////////////////////////////////
// bypass_register.sv
//
// Written: james.stine@okstate.edu, jacob.pease@okstate.edu, matotto@okstate.edu 28 July 2025
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

module bypass_register (
   input logic 	tdi,
   input logic  tck,
   input logic 	clockDR,
   input logic 	shiftDR,
   output logic tdo
);

   /*
    
    The JTAG spec mandates behavior, not implementation:

    When the TAP controller is in Test-Logic-Reset, the IR must hold
    the IDCODE instruction (or BYPASS if there's no IDCODE
    register). If TRST* is implemented, asserting it must force the
    TAP into Test-Logic-Reset asynchronously. Holding TMS high for ≥5
    TCK cycles must also reach Test-Logic-Reset.    
    
    The spec describes ClockDR as a conceptual gated clock for the DR
    shift path, but it's a behavioral description — "the DR is clocked
    during Capture-DR and Shift-DR." It doesn't mandate that ClockDR
    be a physical net feeding a clock pin. As long as the bypass flop
    captures tdi & shiftDR on the appropriate TCK edges (i.e., when
    the TAP is in Capture-DR or Shift-DR), it doesn't matter whether
    you implement that by gating the clock or by enabling the data
    path. The new form passes the same TCK edges through and uses
    clockDR to decide whether to update — observably identical from
    outside the module.        
    
    The tdi & shiftDR trick handles both required behaviors with one
    flop and an AND gate: In Capture-DR, shiftDR is 0, so tdi &
    shiftDR = 0 — the bypass register loads a logic 0, which is
    exactly what §10.1.1(b) requires.  In Shift-DR, shiftDR is 1, so
    tdi & shiftDR = tdi — TDI shifts straight through to TDO.    
        
    */
   
   always_ff @(posedge tck) begin
      if (clockDR)  
        tdo <= tdi & shiftDR;  // 10.1.1 (b)
   end

endmodule // bypass_register
