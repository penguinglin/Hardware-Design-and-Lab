module lab3_basic (
    input wire clk,
    input wire rst,
    input wire mode,
    input wire play, 
    input wire right,
    input wire left,
    input wire forward,
    output reg [15:0] LED,
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY
);
    // ======================================//
    // Control switches
    // ======================================//
    reg [4:0] value;
    reg [4:0] BCD4, BCD3, BCD2, BCD1; // 4 BCD digits
    wire clk_scan, clk_slow;

    // Clock dividers
    clock_divider #(.n(16)) scan_div (.clk(clk), .clk_div(clk_scan));
    clock_divider #(.n(25)) slow_div (.clk(clk), .clk_div(clk_slow));

    // ======================================//
    // 顯示內容切換邏輯
    // ======================================//
    always @(posedge clk_slow or posedge rst) begin
        if (rst) begin
            // --- Reset 時顯示 "0 x - -" ---
            BCD4 <= 5'd0;   // 0
            BCD3 <= 5'd14;  // o (代表 x)
            BCD2 <= 5'd17;  // -
            BCD1 <= 5'd17;  // -
        end 
        else begin
            // --- 不論 mode = 0 或 1，皆顯示 "PrAc" ---
            BCD4 <= 5'd10; // P
            BCD3 <= 5'd11; // r
            BCD2 <= 5'd12; // A
            BCD1 <= 5'd13; // c
        end
    end

    // ======================================//
    // 七段顯示掃描控制
    // ======================================//
    always @(posedge clk_scan or posedge rst) begin
        if (rst) begin
            DIGIT <= 4'b1110;
            value <= BCD1;
        end else begin
            case (DIGIT)
                4'b1110: begin value <= BCD3; DIGIT <= 4'b1101; end
                4'b1101: begin value <= BCD2; DIGIT <= 4'b1011; end
                4'b1011: begin value <= BCD1; DIGIT <= 4'b0111; end
                4'b0111: begin value <= BCD4; DIGIT <= 4'b1110; end
                default: begin value <= BCD1; DIGIT <= 4'b1110; end
            endcase
        end
    end

    // ======================================//
    // 七段顯示編碼表
    // ======================================//
    always @(*) begin
        case (value)
            5'd0:  DISPLAY = 7'b000_0001;
            5'd1:  DISPLAY = 7'b100_1111;
            5'd2:  DISPLAY = 7'b001_0010;
            5'd3:  DISPLAY = 7'b000_0110;
            5'd4:  DISPLAY = 7'b100_1100;
            5'd5:  DISPLAY = 7'b010_0100;
            5'd6:  DISPLAY = 7'b010_0000;
            5'd7:  DISPLAY = 7'b000_1111;
            5'd8:  DISPLAY = 7'b000_0000;
            5'd9:  DISPLAY = 7'b000_0100;
            5'd10: DISPLAY = 7'b001_1000; // P
            5'd11: DISPLAY = 7'b111_1010; // r
            5'd12: DISPLAY = 7'b000_1000; // A
            5'd13: DISPLAY = 7'b111_0010; // c
            5'd14: DISPLAY = 7'b000_1100; // x
            5'd15: DISPLAY = 7'b001_1100; // o
            5'd16: DISPLAY = 7'b000_0011; // 0-1
            5'd17: DISPLAY = 7'b111_1110; // -
            5'd18: DISPLAY = 7'b111_1111; // nothing
            default: DISPLAY = 7'b111_1111; 
        endcase
    end

    // ======================================//
    // LED control
    // ======================================//
    always @(*) begin
        if (rst)
            LED = 16'hFFFF;  // reset亮
        else
            LED = 16'h0000;
    end

endmodule
