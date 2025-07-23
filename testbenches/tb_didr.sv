// `timescale 1ns/1ps
module testbench();


integer i;

logic tdi, clockDR, captureDR, tdo;

logic [31:0] read_buffer;


device_identification_register dut (
    .tdi(tdi),
    .tdo(tdo),
    .captureDR(captureDR),
    .clockDR(clockDR)
);
    
// clock
initial begin
    clockDR = 1'b1;
    forever #5 clockDR = ~clockDR;
end


initial begin
    tdi = 0;
    captureDR = 0;

    @(posedge clockDR)
        captureDR = 1;

    @(posedge clockDR)
        captureDR = 0;

    for (i=0; i < 32; i=i+1) begin
        
        @(posedge clockDR) begin

            read_buffer[31-i] = tdo;
            
        end
    end

    #10

    $finish;
end

endmodule // testbench
