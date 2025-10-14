module lfsr9_custom (
    input  wire clk,
    input  wire rst,       // asynchronous or synchronous reset pulse
    input  wire shift_en,  // one-pulse trigger from button
    output reg  [8:0] lfsr // LFSR state output
);
    wire feedback;
    wire [8:0] next_lfsr;

    wire new_LED6 = lfsr[7] ^ lfsr[0];
    wire new_LED5 = lfsr[6] ^ lfsr[0];
    wire new_LED3 = lfsr[4] ^ lfsr[0];


    assign feedback = lfsr[0];

    // 下一個 LFSR state
    assign next_lfsr = {
        feedback,        // MSB -> LED8
        lfsr[8],         // LED7 右移
        new_LED6,        // LED6
        new_LED5,        // LED5
        lfsr[5],         // LED4 右移
        new_LED3,        // LED3
        lfsr[3],         // LED2 右移
        lfsr[2],         // LED1 右移
        lfsr[1]          // LED0 右移
    };

    always @(posedge clk or posedge rst) begin
        if (rst)
            lfsr <= 9'b101011001;  // Initial value
        else if (shift_en)
            lfsr <= next_lfsr;
    end
endmodule
