module lab2_1_practice(
    input clk,
    input rst,
    input signed [7:0] A,
    input signed [7:0] B,
    output reg signed [11:0] out
);

// Write your code here
    always @(posedge clk) begin
        if (rst) begin
            out <= 12'b0;
        end else begin
            out <= A + B; 
        end
    end

endmodule