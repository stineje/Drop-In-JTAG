// `timescale 1ns/1ps
module testbench();

integer i, errors;


logic tck, trst, tms, tdi, tdo;
logic tdo_ref, tdo_sample;
logic clk;
logic reset;


top dut (
    .tck(tck),
    .tdi(tdi),
    .tms(tms),
    .trst(trst),
    .tdo(tdo),
    .sysclk(clk),
    .sys_reset(reset),
    .success(),
    .fail()
);


// clocks
initial begin
    clk = 1'b1;
    forever #1 clk = ~clk;
end

initial begin
    tck = 1'b1;
    forever #10 tck = ~tck;
end

// initialize test
initial begin
    tms = 1'b1;
    tdi = 1'b1;

    reset <= 1; 
    trst <= 0;
    # 22;
    reset <= 0;
    trst <= 1;
end



initial begin
    logic [160:0] tdovector;

    static logic [11:0] halt_tmsvector = 'b101100_0001_10;
    static logic [11:0] halt_tdivector = 'b000000_0110_00; // LSB first

    static logic [11:0] sp_tmsvector = 'b1100_0001_1100;
    static logic [11:0] sp_tdivector = 'b0000_0100_0000; // LSB first


    while (1) begin
        @(negedge clk) begin
            if (dut.MemWriteM) begin
                if(dut.DataAdrM === 100 & dut.WriteDataM === 25) begin
                    $display("Simulation succeeded");
                    break;
                end else if (dut.DataAdrM !== 96) begin
                    $display("Simulation failed");
                    break;
                end
            end
        end
    end

    $display("HALTing system logic");
    for (i=11; i >= 0; i=i-1) begin
        @(negedge tck) begin
            tms <= halt_tmsvector[i];
            tdi <= halt_tdivector[i];
        end
    end

    $display("putting TAP in SAMPLE/PRELOAD");
    for (i=11; i >= 0; i=i-1) begin
        @(negedge tck) begin
            tms <= sp_tmsvector[i];
            tdi <= sp_tdivector[i];
        end
    end

    $display("Scanning DR register");
    for (i=161; i >= 0; i=i-1) begin
        @(negedge tck) begin
            tdovector[i] <= tdo;
        end
    end

    $display("Returning to test-logic reset");
    for (i=0; i<10; i=i+1) begin
        @(negedge tck) begin
            tdi <= 1;
        end
    end

    $display("ReadDataM: %h | WriteDataM %h | DataAdrM: %h | MemWriteM: %b | InstrF: %h | PCF: %h", tdovector[160:129],tdovector[128:97],tdovector[96:64],tdovector[64:64],tdovector[63:32],tdovector[31:0]);
    $stop;
end

endmodule // testbench
