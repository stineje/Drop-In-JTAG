///////////////////////////////////////////
// clk_gen.sv
//
// Written: james.stine@okstate.edu, jacob.pease@okstate.edu 28 July 2025
// Modified:
//
// Purpose: Parameterized MMCM-based clock generator for Xilinx Artix-7 FPGAs (Arty A7-100T).
//          Takes a raw board input clock and uses the on-chip Mixed-Mode Clock Manager
//          (MMCM) primitive to multiply and divide it to a target output frequency.
//          The MMCM internally runs a VCO at a higher frequency (must stay within
//          600-1200MHz for Artix-7) and divides back down to the desired output.
//          Output is routed through a BUFG global clock buffer for low-skew distribution
//          across the device.  A locked output signal indicates when the MMCM has
//          stabilized and the output clock is valid -- the parent module should hold
//          the design in reset until locked is asserted.
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
//
// Copyright (C) 2021-25 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may not use this file
// except in compliance with the License, or, at your option, the Apache License version 2.0. You
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the
// License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
// either express or implied. See the License for the specific language governing permissions
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////
//
// Artix-7 MMCM VCO must stay within 600-1200MHz.
// Choose MULT_F and DIVIDE_F so that:
//   VCO  = (1/CLKIN_PERIOD) * MULT_F        must be 600-1200MHz
//   Fout = VCO / DIVIDE_F                   is your target frequency
//
// Common configurations from 100MHz input (CLKIN_PERIOD=10.0, MULT_F=8.0, VCO=800MHz):
//   25MHz  -> DIVIDE_F = 32.0
//   50MHz  -> DIVIDE_F = 16.0
//   100MHz -> DIVIDE_F =  8.0
//   200MHz -> DIVIDE_F =  4.0
////////////////////////////////////////////////////////////////////////////////////////////////

module clk_gen #(
   parameter real CLKIN_PERIOD  = 10.0,  // Input clock period in ns (default: 100MHz)
   parameter real MULT_F        = 8.0,   // VCO multiplier     (default: VCO = 800MHz)
   parameter real DIVIDE_F      = 32.0,  // Output divider     (default: Fout = 25MHz)
   parameter int  DIVCLK_DIVIDE = 1      // Input pre-divider  (usually 1)
)(
   input  logic clk_in,    // raw board clock input
   input  logic reset,     // synchronous reset (active high)
   output logic clk_out,   // divided output clock (through BUFG)
   output logic locked     // high when MMCM has locked onto input clock
);

   logic clk_fb;     // MMCM internal feedback — must loop CLKFBOUT back to CLKFBIN
   logic clk_unbuf;  // raw MMCM output before global clock buffer

   MMCME2_BASE #(
      .CLKIN1_PERIOD     (CLKIN_PERIOD),
      .CLKFBOUT_MULT_F   (MULT_F),
      .CLKOUT0_DIVIDE_F  (DIVIDE_F),
      .CLKOUT0_DUTY_CYCLE(0.5),
      .CLKOUT0_PHASE     (0.0),
      .DIVCLK_DIVIDE     (DIVCLK_DIVIDE),
      .REF_JITTER1       (0.01),
      .STARTUP_WAIT      ("FALSE")
   ) mmcm_inst (
      .CLKIN1    (clk_in),
      .CLKFBIN   (clk_fb),
      .CLKFBOUT  (clk_fb),
      .CLKOUT0   (clk_unbuf),
      .LOCKED    (locked),
      // unused outputs - tie off
      .CLKOUT0B  (), .CLKOUT1   (), .CLKOUT1B  (),
      .CLKOUT2   (), .CLKOUT2B  (), .CLKOUT3   (),
      .CLKOUT3B  (), .CLKOUT4   (), .CLKOUT5   (),
      .CLKOUT6   (), .CLKFBOUTB (),
      .PWRDWN    (1'b0),
      .RST       (reset)
   );

   // Buffer output onto global clock network
   BUFG bufg_inst (
      .I (clk_unbuf),
      .O (clk_out)
   );

endmodule // clk_gen
