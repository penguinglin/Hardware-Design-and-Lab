module lab2_2_practice (
    input clk,
    input rst,
    input signed [7:0] A,
    input signed [7:0] B,
    output reg signed [11:0] out
);
    reg signed [11:0]out_delay;
// Write your code here
    always @(posedge clk) begin
        if (rst) begin
            out_delay <= 12'b0;
            out <= out_delay;
        end else begin
            out_delay <= A - B;
            out <= out_delay;
        end
    end
endmodule

