`timescale 1ns / 1ps
module onepulse (
    input wire pb_in,
    input wire clk,
    output reg pb_out
    );
    reg pb_in_delay;
    always @(posedge clk) begin
        if (pb_in == 1'b1 && pb_in_delay == 1'b0)
            pb_out <= 1'b1;
        else
            pb_out <= 1'b0;
        pb_in_delay <= pb_in;
    end
endmodule