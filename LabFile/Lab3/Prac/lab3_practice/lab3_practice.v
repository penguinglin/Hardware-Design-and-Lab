module lab3_practice (
    input wire clk,
    input wire rst,
    input wire slow,
    input wire fast,
    input wire end_light,
    output reg [15:0] led
);
    /* Note that output port can be either reg or wire.
    * It depends on how you design your module. */
    
    // add your design here
endmodule

module clock_divider #(
    parameter n = 10 // 100MHz / (2^10)
)(
    input wire  clk,
    output wire clk_div  
);

    reg [n-1:0] num;
    wire [n-1:0] next_num;

    always @(posedge clk) begin
        num <= next_num;
    end

    assign next_num = num + 1;
    assign clk_div = num[n-1];
endmodule