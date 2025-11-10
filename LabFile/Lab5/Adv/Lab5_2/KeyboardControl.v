//========================================================
//  KeyboardControl (for 4x4 Sudoku or puzzle selection)
//  with position validity check
//========================================================
module KeyboardControl(
    input  wire clk,
    input  wire rst,
    inout  wire PS2_DATA,
    inout  wire PS2_CLK,
    input  wire keyboard_en,
    input  wire [15:0] valid_pos, // 位置有效性：1=不可選，0=可選
    output reg  submit_pos,       // one-pulse: confirm position selection
    output reg  submit_img,       // one-pulse: confirm image selection
    output reg [3:0] current_pos, // selected grid position (0~15)
    output reg [2:0] current_img  // selected image ID (1~4)
);

    //--------------------------------------------------------
    // Keyboard decoding signals
    //--------------------------------------------------------
    wire [511:0] key_down;
    wire [8:0]   last_change;
    wire         key_valid;
    reg  [4:0]   key_num;

    reg [3:0] sel_pos;       // internal position buffer
    reg [2:0] sel_img;       // internal image buffer
    reg       pos_locked;    // position locked flag

    //--------------------------------------------------------
    // PS/2 keyboard decoder + one-pulse generator
    //--------------------------------------------------------
    KeyboardDecoder key_de(
        .key_down(key_down),
        .last_change(last_change),
        .key_valid(key_valid),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(rst),
        .clk(clk)
    );

    wire key_valid_op;
    one_pulse key_valid_one_pulse (
        .pb_out(key_valid_op),
        .pb_in(key_valid),
        .clk(clk)
    );

    //--------------------------------------------------------
    // Key code mapping table (PS/2 make codes)
    //--------------------------------------------------------
    parameter [8:0] KEY_CODES [0:21] = {
        9'b0_0001_0110, // 1
        9'b0_0001_1110, // 2
        9'b0_0010_0110, // 3
        9'b0_0010_0101, // 4
        9'b0_0010_1110, // 5
        9'b0_0011_0110, // 6
        9'b0_0011_1101, // 7
        9'b0_0011_1110, // 8
        9'b0_0010_1100, // T
        9'b0_0011_0101, // Y
        9'b0_0011_1100, // U
        9'b0_0100_0011, // I
        9'b0_0011_0100, // G
        9'b0_0011_0011, // H
        9'b0_0011_1011, // J
        9'b0_0100_0010, // K
        9'b0_0011_0010, // B
        9'b0_0011_0001, // N
        9'b0_0011_1010, // M
        9'b0_0100_0001, // ,
        9'b0_0101_1010  // Enter
    };

    //--------------------------------------------------------
    // Convert key scan code to logical key number
    //--------------------------------------------------------
    always @(*) begin
        case (last_change)
            KEY_CODES[0]  : key_num = 5'd1;
            KEY_CODES[1]  : key_num = 5'd2;
            KEY_CODES[2]  : key_num = 5'd3;
            KEY_CODES[3]  : key_num = 5'd4;
            KEY_CODES[4]  : key_num = 5'd5;
            KEY_CODES[5]  : key_num = 5'd6;
            KEY_CODES[6]  : key_num = 5'd7;
            KEY_CODES[7]  : key_num = 5'd8;
            KEY_CODES[8]  : key_num = 5'd9;
            KEY_CODES[9]  : key_num = 5'd10;
            KEY_CODES[10] : key_num = 5'd11;
            KEY_CODES[11] : key_num = 5'd12;
            KEY_CODES[12] : key_num = 5'd13;
            KEY_CODES[13] : key_num = 5'd14;
            KEY_CODES[14] : key_num = 5'd15;
            KEY_CODES[15] : key_num = 5'd16;
            KEY_CODES[16] : key_num = 5'd17;
            KEY_CODES[17] : key_num = 5'd18;
            KEY_CODES[18] : key_num = 5'd19;
            KEY_CODES[19] : key_num = 5'd20;
            KEY_CODES[20] : key_num = 5'd21;
            default       : key_num = 5'd0;
        endcase
    end

    //--------------------------------------------------------
    // Input control logic (two-step selection)
    //--------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sel_pos     <= 0;
            sel_img     <= 0;
            pos_locked  <= 0;
            submit_img  <= 0;
            submit_pos  <= 0;
            current_pos <= 0;
            current_img <= 0;
        end 
        else if (keyboard_en && key_valid_op) begin
            submit_img <= 0;
            submit_pos <= 0;

            // --- Step 1: select position (0~15) ---
            if (!pos_locked) begin
                case (key_num)
                    5'd5:  sel_pos <= 4'd0;
                    5'd6:  sel_pos <= 4'd1;
                    5'd7:  sel_pos <= 4'd2;
                    5'd8:  sel_pos <= 4'd3;
                    5'd9:  sel_pos <= 4'd4;
                    5'd10: sel_pos <= 4'd5;
                    5'd11: sel_pos <= 4'd6;
                    5'd12: sel_pos <= 4'd7;
                    5'd13: sel_pos <= 4'd8;
                    5'd14: sel_pos <= 4'd9;
                    5'd15: sel_pos <= 4'd10;
                    5'd16: sel_pos <= 4'd11;
                    5'd17: sel_pos <= 4'd12;
                    5'd18: sel_pos <= 4'd13;
                    5'd19: sel_pos <= 4'd14;
                    5'd20: sel_pos <= 4'd15;
                endcase

                // Lock position only if valid
                if (key_num == 5'd21 && valid_pos[sel_pos] == 1'b0) begin
                    pos_locked  <= 1;
                    submit_pos  <= 1;
                    current_pos <= sel_pos;
                end
            end
            // --- Step 2: select image (1~4) ---
            else begin
                case (key_num)
                    5'd1: sel_img <= 3'd1;
                    5'd2: sel_img <= 3'd2;
                    5'd3: sel_img <= 3'd3;
                    5'd4: sel_img <= 3'd4;
                endcase
                current_img <= sel_img;

                if (key_num == 5'd21) begin
                    submit_img <= 1;
                    pos_locked <= 0; // unlock for next round
                end
            end
        end
    end

endmodule
