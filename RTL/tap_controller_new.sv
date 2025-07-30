module tap_controller_new 
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

   enum 	logic [3:0] {Exit2DR     = 4'h0,
			     Exit1DR     = 4'h1,
			     ShiftDR     = 4'h2,
			     PauseDR     = 4'h3,
			     SelectIR    = 4'h4,
			     UpdateDR    = 4'h5,
			     CaptureDR   = 4'h6,
			     SelectDR    = 4'h7,
			     Exit2IR     = 4'h8,
			     Exit1IR     = 4'h9,
			     ShiftIR     = 4'hA,
			     PauseIR     = 4'hB,
			     RunTestIdle = 4'hC,
			     UpdateIR    = 4'hD,
			     CaptureIR   = 4'hE,
			     TLReset     = 4'hF
			     } State;
   
   always @(posedge tck) begin
      if (~trst) State <= TLReset; 
      else case (State)
	     TLReset     : State <= tms ? TLReset : RunTestIdle;
	     RunTestIdle : State <= tms ? SelectDR : RunTestIdle;
	     SelectDR    : State <= tms ? SelectIR : CaptureDR;
	     CaptureDR   : State <= tms ? Exit1DR : ShiftDR;
	     ShiftDR     : State <= tms ? Exit1DR : ShiftDR;
	     Exit1DR     : State <= tms ? UpdateDR : PauseDR;
	     PauseDR     : State <= tms ? Exit2DR : PauseDR;
	     Exit2DR     : State <= tms ? UpdateDR : ShiftDR;
	     UpdateDR    : State <= tms ? SelectDR : RunTestIdle;
	     SelectIR    : State <= tms ? TLReset : CaptureIR;
	     CaptureIR   : State <= tms ? Exit1IR : ShiftIR;
	     ShiftIR     : State <= tms ? Exit1IR : ShiftIR;
	     Exit1IR     : State <= tms ? UpdateIR : PauseIR;
	     PauseIR     : State <= tms ? Exit2IR : PauseIR;
	     Exit2IR     : State <= tms ? UpdateIR : ShiftIR;
	     UpdateIR    : State <= tms ? SelectDR : RunTestIdle;
	   endcase // case (State)
   end
   

   // 6.1.1 Section c 
   // actions occurring on the rising/falling edge of TCK in the state
   always @(negedge tck) begin
      shiftIR <= State == ShiftIR;
      shiftDR <= State == ShiftDR;            
      reset <= ~(State == TLReset);      
      tdo_en <= State == ShiftIR || State == ShiftDR;
      captureIR <= State == CaptureIR;
      updateIR <= State == UpdateIR;
      captureDR <= State == CaptureDR;
      updateDR <= State == UpdateDR;      
   end

   // Clocking registers on rising edge of tck
   // See spreadsheet: clockIR: 0xA|0xE; clockDR: 0x2|0x6
   assign clockIR = tck | State[0] | ~State[1] | ~State[3];
   assign clockDR = tck | State[0] | ~State[1] | State[3];
   
   //assign select = State[3];
   assign select = (Exit2IR | Exit1IR | ShiftIR | PauseIR | 
		    RunTestIdle | UpdateIR | CaptureIR | TLReset);
   
   //assign updateDRstate = State[0] & ~State[1] & State[2] & ~State[3];   
   
endmodule

