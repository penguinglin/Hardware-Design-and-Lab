module lab2_1 (
    input clk,
    input rst,
    input signed [7:0] A,
    input signed [7:0] B,
    output reg [1:0] out
);

    wire sA, sB;
    assign sA = A[7];
    assign sB = B[7];
// Write your code here
    always @(posedge clk) begin
        if (rst) begin 
            out <= 2'b00;
        end else if (A == 8'b0 || B == 8'b0) begin
            out <= 2'b00;
        end else if (sA == 1'b0 && sB == 1'b0) begin
            out <= 2'b01;
        end else if (sA == 1'b1 && sB == 1'b1) begin
            out <= 2'b10;
        end else begin
            out <= 2'b11;
        end
    end
endmodule