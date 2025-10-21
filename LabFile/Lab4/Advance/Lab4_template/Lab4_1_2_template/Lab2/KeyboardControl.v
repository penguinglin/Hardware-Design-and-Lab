module KeyboardControl(
    input wire clk,
    input wire rst,
    inout wire PS2_DATA,
    inout wire PS2_CLK,
    input wire state_init_request,
    input wire led_en,
    input wire segment_en,
    output wire [15:0] num,
    output reg [15:0] LED,
    output reg submit  // S鍵觸發
);
    // -----------------------------
    // Keyboard control signals
    // -----------------------------
    wire [511:0] key_down;
    wire [8:0] last_change;
    wire key_valid;
    reg [3:0] key_num;
    reg [1:0] sel_pos;
    reg [8:0] locked_key;
    reg locked;
    reg [3:0] BCD1, BCD2, BCD3, BCD4;
    
    // Key codes
    parameter [8:0] KEY_CODES [0:21] = {
			9'b0_0100_0101,	// 0 => 45
			9'b0_0001_0110,	// 1 => 16
			9'b0_0001_1110,	// 2 => 1E
			9'b0_0010_0110,	// 3 => 26
			9'b0_0010_0101,	// 4 => 25
			9'b0_0010_1110,	// 5 => 2E
			9'b0_0011_0110,	// 6 => 36
			9'b0_0011_1101,	// 7 => 3D
			9'b0_0011_1110,	// 8 => 3E
			9'b0_0100_0110,	// 9 => 46

			9'b0_0111_0000, // right_0 => 70
			9'b0_0110_1001, // right_1 => 69
			9'b0_0111_0010, // right_2 => 72
			9'b0_0111_1010, // right_3 => 7A
			9'b0_0110_1011, // right_4 => 6B
			9'b0_0111_0011, // right_5 => 73
			9'b0_0111_0100, // right_6 => 74
			9'b0_0110_1100, // right_7 => 6C
			9'b0_0111_0101, // right_8 => 75
			9'b0_0111_1101,  // right_9 => 7D

			9'b0_0010_1001, // space => 29
			9'b0_0001_1011   // S => 1B
    };
        // -----------------------------
        // Keyboard decoder
        // -----------------------------
    KeyboardDecoder key_de(
        .key_down(key_down),
        .last_change(last_change),
        .key_valid(key_valid),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(rst),
        .clk(clk)
    );

    // -----------------------------
    // Key code 轉 BCD
    // -----------------------------
    always @(*) begin
        case (last_change)
            KEY_CODES[0] : key_num = 4'b0000;
            KEY_CODES[1] : key_num = 4'b0001;
            KEY_CODES[2] : key_num = 4'b0010;
            KEY_CODES[3] : key_num = 4'b0011;
            KEY_CODES[4] : key_num = 4'b0100;
            KEY_CODES[5] : key_num = 4'b0101;
            KEY_CODES[6] : key_num = 4'b0110;
            KEY_CODES[7] : key_num = 4'b0111;
            KEY_CODES[8] : key_num = 4'b1000;
            KEY_CODES[9] : key_num = 4'b1001;
            KEY_CODES[10] : key_num = 4'b0000;
            KEY_CODES[11] : key_num = 4'b0001;
            KEY_CODES[12] : key_num = 4'b0010;
            KEY_CODES[13] : key_num = 4'b0011;
            KEY_CODES[14] : key_num = 4'b0100;
            KEY_CODES[15] : key_num = 4'b0101;
            KEY_CODES[16] : key_num = 4'b0110;
            KEY_CODES[17] : key_num = 4'b0111;
            KEY_CODES[18] : key_num = 4'b1000;
            KEY_CODES[19] : key_num = 4'b1001;
            KEY_CODES[20] : key_num = 4'b1110; // space
            KEY_CODES[21] : key_num = 4'b1111; // S
            default: key_num = 4'b1010;
        endcase
    end

    // -----------------------------
    // BCD update
    // -----------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            BCD1 <= 4'b0;
            BCD2 <= 4'b0;
            BCD3 <= 4'b0;
            BCD4 <= 4'b0;
            sel_pos <= 2'b00;
            submit <= 0;
            locked <= 0;
            locked_key <= 0;
        end else if (state_init_request) begin
            BCD1 <= 4'b0;
            BCD2 <= 4'b0;
            BCD3 <= 4'b0;
            BCD4 <= 4'b0;
            sel_pos <= 2'b00;
            submit <= 0; 
            locked <= 0;
            locked_key <= 0;
        end else if (key_valid && segment_en) begin
            submit <= 0;
            if (!locked) begin
                if (key_down[last_change]) begin
                    locked <= 1;
                    locked_key <= last_change;

                    if (key_num <= 4'd9) begin
                        case(sel_pos)
                            2'b00: BCD4 <= key_num;
                            2'b01: BCD3 <= key_num;
                            2'b10: BCD2 <= key_num;
                            2'b11: BCD1 <= key_num;
                        endcase
                    end else if (key_num == 4'b1110) begin
                        sel_pos <= sel_pos + 1;
                        case(sel_pos)
                            2'b00: BCD3 <= 4'd0;
                            2'b01: BCD2 <= 4'd0;
                            2'b10: BCD1 <= 4'd0;
                            2'b11: BCD4 <= 4'd0;
                        endcase
                    end else if (key_num == 4'b1111) begin
                        submit <= 1;
                    end
                end
            end else begin
                if (!key_down[locked_key]) begin
                    locked <= 0;
                end
            end
        end
    end

    // -----------------------------
    // LED 
    // -----------------------------
    always @(*) begin
        if (led_en) begin
            case(sel_pos)
                2'b00: LED = 16'b1111_0000_0000_0000;
                2'b01: LED = 16'b0000_1111_0000_0000;
                2'b10: LED = 16'b0000_0000_1111_0000;
                2'b11: LED = 16'b0000_0000_0000_1111;
                default: LED = 16'b0;
            endcase
        end else begin
            LED = 16'b0;
        end
    end

    assign num = {BCD4, BCD3, BCD2, BCD1};

endmodule
