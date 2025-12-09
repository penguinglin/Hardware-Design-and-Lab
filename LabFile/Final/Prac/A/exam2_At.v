// ========================
// exam2_A_tb.v
// ========================
`timescale 1ns/1ps

module exam2_A_tb;

    reg clk;
    reg rst;
    wire [3:0] DIGIT;
    wire [6:0] DISPLAY;

    // Instantiate DUT
    exam2_A uut (
        .clk(clk),
        .rst(rst),
        .DIGIT(DIGIT),
        .DISPLAY(DISPLAY)
    );

    // Clock generation: 10ns period -> 100MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset
    initial begin
        rst = 1;
        #20;
        rst = 0;
    end

    // Monitor signals
    initial begin
        $dumpfile("exam2_A_tb.vcd");
        $dumpvars(0, exam2_A_tb);
        $display("Time | xi | answer | DIGIT | DISPLAY");
        $monitor("%0t | %d | %d | %b | %b", $time, uut.xi, uut.answer, DIGIT, DISPLAY);
    end

    // Simulation runtime
    initial begin
        #200000; // run long enough to see xi increment
        $finish;
    end

endmodule

// ========================
// SevenSegment 修改版本
// ========================
module SevenSegment(
    output reg [6:0] display,
    output reg [3:0] digit, 
    input wire [15:0] nums,
    input wire rst,
    input wire clk
);

    reg [15:0] clk_divider = 0;
    reg [3:0] display_num;

    // Slow clock divider
    always @(posedge clk or posedge rst) begin
        if (rst) clk_divider <= 0;
        else clk_divider <= clk_divider + 1;
    end

    // Multiplexing 7-seg digits
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            digit <= 4'b1110;
            display_num <= nums[3:0];
        end else begin
            case(digit)
                4'b1110: begin
                    digit <= 4'b1101;
                    display_num <= nums[7:4];
                end
                4'b1101: begin
                    digit <= 4'b1011;
                    display_num <= nums[11:8];
                end
                4'b1011: begin
                    digit <= 4'b0111;
                    display_num <= nums[15:12];
                end
                4'b0111: begin
                    digit <= 4'b1110;
                    display_num <= nums[3:0];
                end
                default: begin
                    digit <= 4'b1110;
                    display_num <= nums[3:0];
                end
            endcase
        end
    end

    // 7-segment decoder
    always @(*) begin
        case(display_num)
            0: display = 7'b1000000;
            1: display = 7'b1111001;
            2: display = 7'b0100100;
            3: display = 7'b0110000;
            4: display = 7'b0011001;
            5: display = 7'b0010010;
            6: display = 7'b0000010;
            7: display = 7'b1111000;
            8: display = 7'b0000000;
            9: display = 7'b0010000;
            default: display = 7'b1111111;
        endcase
    end

endmodule
