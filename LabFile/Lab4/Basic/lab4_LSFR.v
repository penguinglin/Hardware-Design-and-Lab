module lfsr9_custom (
    input  wire clk,
    input  wire rst,       // asynchronous or synchronous reset pulse
    input  wire shift_en,  // one-pulse trigger from button
    output reg  [3:0] lfsr // LFSR state output
);
    wire feedback;
    wire [3:0] next_lfsr;

    wire new_LED1 = lfsr[2] ^ lfsr[0];
    wire new_LED0 = lfsr[1] ^ lfsr[0];


    assign feedback = lfsr[0];

    // 下一個 LFSR state
    assign next_lfsr = {
        feedback,        // MSB -> LED8
        lfsr[3],         // LED7 右移
        new_LED1,        // LED6
        new_LED0        // LED5
    };

    always @(posedge clk or posedge rst) begin
        if (rst)
            lfsr <= 4'b1001;  // Initial value
        else if (shift_en)
            lfsr <= next_lfsr;
    end
endmodule
