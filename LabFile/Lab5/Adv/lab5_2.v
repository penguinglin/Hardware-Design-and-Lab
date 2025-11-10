module lab5_2 (
    input wire clk,
    input wire rst, // bottom
    input wire start, // bottom
    input wire [2:0] sw, // switches
    inout wire PS2_CLK,
    inout wire PS2_DATA,
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,
    output  hsync,
    output  vsync,
    output wire [15:0] led
);
    // add your design here
    wire [11:0] data;
    wire clk_2;
    wire clk_22;
    wire [16:0] pixel_addr;
    wire [11:0] pixel;
    wire [11:0] pixel_0;
    wire [11:0] pixel_1;
    wire [11:0] pixel_2;
    wire [11:0] pixel_3;
    wire valid;
    wire [9:0] h_cnt; //640
    wire [9:0] v_cnt;  //480
    wire [11:0] data0;
    wire [11:0] data1;
    wire [11:0] data2;
    wire [11:0] data3;
    assign{vgaRed,vgaGreen,vgaBlue} = (valid == 1'b1)? pixel:12'h0;
    
    //=====================================//
    // Display Control
    //=====================================//
        clock_divider #(.n(2)) clk_div_2(
            .clk(clk),
            .clk_div(clk_2)
        );
        clock_divider #(.n(22)) clk_div_22(
            .clk(clk),
            .clk_div(clk_22)
        );
        blk_mem_gen_0 blk_0_inst(
            .clka(clk_25MHz),
            .wea(0),
            .addra(pixel_addr),
            .dina(data0[11:0]),
            .douta(pixel_0)
        );
        blk_mem_gen_1 blk_1_inst(
            .clka(clk_25MHz),
            .wea(0),
            .addra(pixel_addr),
            .dina(data1[11:0]),
            .douta(pixel_1)
        );
        blk_mem_gen_2 blk_2_inst(
            .clka(clk_25MHz),
            .wea(0),
            .addra(pixel_addr),
            .dina(data2[11:0]),
            .douta(pixel_2)
        );
        blk_mem_gen_3 blk_3_inst(
            .clka(clk_25MHz),
            .wea(0),
            .addra(pixel_addr),
            .dina(data3[11:0]),
            .douta(pixel_3)
        );
        vga_controller vga_inst(
            .pclk(clk_25MHz),
            .reset(rst_processed),
            .hsync(hsync),
            .vsync(vsync),
            .valid(valid),
            .h_cnt(h_cnt),
            .v_cnt(v_cnt)
        );
        mem_addr_gen mem_addr_gen_inst(
            .clk(clk_22),
            .rst(rst),
            .h_cnt(h_cnt),
            .v_cnt(v_cnt),
            .pixel_addr(pixel_addr)
        );

    //=====================================//
    //    Debounce & One pulse
    //    rst => one_pulse_rst
    //    start => one_pulse_start
    //=====================================//
        wire debounce_rst, one_pulse_rst;
        wire debounce_start, one_pulse_start;
        Debounce DB_rst (
            .pb_debounced(debounce_rst),
            .pb(rst),
            .clk(clk)
        );
        one_pulse OP_rst (
            .pb_out(one_pulse_rst),
            .pb_in(debounce_rst),
            .clk(clk)
        );
        Debounce DB_start (
            .pb_debounced(debounce_start),
            .pb(start),
            .clk(clk)
        );
        one_pulse OP_start (
            .pb_out(one_pulse_start),
            .pb_in(debounce_start),
            .clk(clk)
        );

    //=====================================//
    //    State Machine 
    //=====================================//
        parameter S_INIT = 2'b00;
        parameter S_SHOW = 2'b01;
        parameter S_GAME = 2'b10;
        parameter S_FINISH  = 2'b11;
        reg [1:0] state, next_state;
        wire puzzle_solved;
        

        always @(posedge clk or posedge one_pulse_rst) begin
            if (one_pulse_rst)
                state <= S_INIT;
            else
                state <= next_state;
        end


        
        always @(*) begin
            case(state)
                S_INIT:  next_state = (one_pulse_start) ? S_SHOW : S_INIT;
                S_SHOW:  next_state = (one_pulse_start) ? S_GAME : S_SHOW;
                S_GAME:  next_state = (puzzle_solved) ? S_FINISH : S_GAME;
                S_FINISH: next_state = (one_pulse_start) ? S_INIT : S_FINISH;
                default:  next_state = S_INIT;
            endcase
        end

    //=====================================//
    //    Keyboard Control
    //=====================================//
        wire keyboard_en = (state == S_GAME);
        wire led_en = (state == S_FINISH);
        wire submit_pos;
        wire submit_img;
        wire [3:0] current_pos;
        wire [2:0] current_img;
        
        wire [15:0] valid_pos; // which position can be choose
        reg [15:0]now_valid_pos;
        assign valid_pos = now_valid_pos;
        
        KeyboardControl kb_ctrl (
            .clk(clk),
            .rst(one_pulse_rst),
            .PS2_CLK(PS2_CLK),
            .PS2_DATA(PS2_DATA),
            .keyboard_en(keyboard_en),
            .valid_pos(valid_pos), 
            .submit_pos(submit_pos),
            .submit_img(submit_img),
            .current_pos(current_pos),
            .current_img(current_img)
        );
    
    //=====================================//
    //    Puzzle Control
    //====================================//
        // puzzle answer
        // TODO: player_input
        reg [15:0]player_input;
        wire [31:0] puzzle_one_ans   = 32'b1000_1101_1101_1000_0010_0111_0111_0010;
        wire [31:0] puzzle_two_ans   = 32'b0100_1110_1011_0100_0001_1011_1110_0001;
        wire [31:0] puzzle_three_ans = 32'b0010_0111_1101_1000_0111_0010_1000_1101;
        assign puzzle_solved = (player_input == 16'hFFFF) ? 1'b1 : 1'b0;

        // puzzle enable : sent to kb for input control
        wire [15:0]puzzle_one_en =16'b0110_0001_0001_1111; 
        wire [15:0]puzzle_two_en =16'b0111_1001_0010_0110;
        wire [15:0]puzzle_three_en=16'b0100_1011_1000_1110;
        reg [15:0] choosen_puzzle_en;
        reg [31:0] chosen_puzzle;

        always @(posedge clk or posedge one_pulse_rst) begin
            if (one_pulse_rst) begin
                choosen_puzzle_en <= 16'b0;
                chosen_puzzle <= 32'b0;
            end
            else begin
                case(state)
                    S_INIT:  begin
                        choosen_puzzle_en <= 16'b0;
                        chosen_puzzle <= 32'b0;
                    end
                    S_SHOW:  begin
                        case(sw)
                            3'b001: begin
                                choosen_puzzle_en <= puzzle_one_en;
                                chosen_puzzle <= puzzle_one_ans;
                            end
                            3'b010: begin
                                choosen_puzzle_en <=puzzle_two_en;
                                chosen_puzzle <= puzzle_two_ans;
                            end
                            3'b100: begin
                                choosen_puzzle_en <= puzzle_three_en;
                                chosen_puzzle <= puzzle_three_ans;
                            end
                            default: begin
                                choosen_puzzle_en <= 16'b0;
                                chosen_puzzle <= 32'b0;
                            end
                        endcase
                    end
                endcase
            end
        end

        puzzle_display puzzle_display_inst (
            .clk(clk),
            .rst(one_pulse_rst),
            .state(state),
            .chosen_puzzle(chosen_puzzle),
            .chosen_puzzle_en(choosen_puzzle_en),
            // keyboard inputs
            .submit_pos(submit_pos),
            .current_pos(current_pos),
            .submit_img(submit_img),
            .current_img(current_img),
            // VGA inputs
            .h_cnt(h_cnt),
            .v_cnt(v_cnt),
            .pixel_0(pixel_0),
            .pixel_1(pixel_1),
            .pixel_2(pixel_2),
            .pixel_3(pixel_3),
            // outputs
            .pixel(pixel),
            .now_valid_pos(now_valid_pos),
            .player_ans(player_input)
        );






    // =====================================//
    //   Game Answer Check
    // =====================================//
        wire check_en = (state == S_FINISH);
        wire [15:0] led_display;
        wire [31:0] choosen_puzzle_ans;
        assign choosen_puzzle_ans = (sw == 3'b001) ? puzzle_one_ans :
                                   (sw == 3'b010) ? puzzle_two_ans :
                                   (sw == 3'b100) ? puzzle_three_ans : 32'b0;   
        GameCenter game_center (
            .clk(clk),
            .rst(one_pulse_rst),
            // enable signals
            .check_en(check_en),
            // puzzle answer
            .answer(choosen_puzzle_ans),
            // player input
            .display_puzzle_transform(player_input),
            // outputs - puzzle solved signals
            .puzzle_solved(led_display)
        );

    // -----------------------------
    // LED && Display output
    // -----------------------------
        assign led = (led_en) ? led_display : 16'b0;
        



endmodule
module puzzle_display(
    input  wire        clk,
    input  wire        rst,
    input  wire [1:0]  state,             // INIT=0, SHOW=1, GAME=2, FINISH=3
    input  wire [31:0] chosen_puzzle,    // puzzle init 
    input  wire [15:0] chosen_puzzle_en,  // origin en signal 
    //---------------------------
    // keyboard inputs
    //---------------------------
    input  wire        submit_pos,    
    input  wire [3:0]  current_pos,  
    input  wire        submit_img,        
    input  wire [1:0]  current_img,   

    //---------------------------
    // VGA inputs
    //---------------------------
    input  wire [9:0]  h_cnt,
    input  wire [9:0]  v_cnt,
    input  wire [11:0] pixel_0, pixel_1, pixel_2, pixel_3, 

    output reg  [11:0] pixel,   
    // ---------------------------
    // return to kb
    // ---------------------------        
    output reg  [15:0] now_valid_pos,  


    output reg  [31:0] player_ans        
);

// ---------------------------
// registers
// ---------------------------
reg [15:0] puzzle_is_clue;  // reverse signal
reg [15:0] puzzle_placed;   // valid signal
reg [11:0] init_pixel, show_pixel, show_pixel_s;
reg [11:0] game_pixel, game_pixel_s;
reg        RGB_reversed;
integer idx;

// ---------------------------
// init
// ---------------------------
always @(posedge clk or posedge rst) begin
    if(rst) begin
        player_ans      <= chosen_puzzle; // init player answer
        puzzle_is_clue  <= chosen_puzzle_en;
        puzzle_placed   <= chosen_puzzle_en;  
        now_valid_pos   <= ~chosen_puzzle_en; 
    end
end

// ---------------------------
// update player answer
// ---------------------------
always @(posedge clk) begin
    if(state == 2'd2) begin // GAME
        // submit image: lock the current position
        if(submit_img) begin
            now_valid_pos[current_pos] <= 0;
        end

        // submit position: update answer and mark placed
        if(submit_pos && !puzzle_is_clue[current_pos] && now_valid_pos[current_pos]) begin
            case(current_pos)
                0:  player_ans[1:0]   <= current_img;
                1:  player_ans[3:2]   <= current_img;
                2:  player_ans[5:4]   <= current_img;
                3:  player_ans[7:6]   <= current_img;
                4:  player_ans[9:8]   <= current_img;
                5:  player_ans[11:10] <= current_img;
                6:  player_ans[13:12] <= current_img;
                7:  player_ans[15:14] <= current_img;
                8:  player_ans[17:16] <= current_img;
                9:  player_ans[19:18] <= current_img;
                10: player_ans[21:20] <= current_img;
                11: player_ans[23:22] <= current_img;
                12: player_ans[25:24] <= current_img;
                13: player_ans[27:26] <= current_img;
                14: player_ans[29:28] <= current_img;
                15: player_ans[31:30] <= current_img;
            endcase
            puzzle_placed[current_pos] <= 1;  // mark as placed
        end
    end
end

// ---------------------------
// SHOW / GAME / FINISH show
// ---------------------------
always @(*) begin
    init_pixel = 12'd0;

    case(state)
        2'd0: pixel = init_pixel; // INIT
        2'd1: begin // SHOW
            // first layer normal
            if(v_cnt < 120) begin
                RGB_reversed = 0;
                if(h_cnt < 160) show_pixel_s = pixel_0;
                else if(h_cnt < 320) show_pixel_s = pixel_1;
                else if(h_cnt < 480) show_pixel_s = pixel_2;
                else show_pixel_s = pixel_3;
            end
            // second layer reversed
            else if(v_cnt < 240) begin
                RGB_reversed = 1;
                if(h_cnt < 160) show_pixel_s = pixel_0;
                else if(h_cnt < 320) show_pixel_s = pixel_1;
                else if(h_cnt < 480) show_pixel_s = pixel_2;
                else show_pixel_s = pixel_3;
            end
            else show_pixel_s = 12'd0;

            // RGB reverse
            if(RGB_reversed) begin
                show_pixel[11:8] = 15 - show_pixel_s[11:8];
                show_pixel[7:4]  = 15 - show_pixel_s[7:4];
                show_pixel[3:0]  = 15 - show_pixel_s[3:0];
            end
            else show_pixel = show_pixel_s;

            pixel = show_pixel;
        end
        2'd2, 2'd3: begin // GAME / FINISH
            idx = 15 - ((v_cnt/120)*4 + (h_cnt/160)); 
            if(puzzle_placed[idx]) begin
                RGB_reversed = puzzle_is_clue[idx];
                case(idx)
                    0: game_pixel_s = player_ans[1:0]  == 2'd0 ? pixel_0 : player_ans[1:0]  == 2'd1 ? pixel_1 : player_ans[1:0]  == 2'd2 ? pixel_2 : pixel_3;
                    1: game_pixel_s = player_ans[3:2]  == 2'd0 ? pixel_0 : player_ans[3:2]  == 2'd1 ? pixel_1 : player_ans[3:2]  == 2'd2 ? pixel_2 : pixel_3;
                    2: game_pixel_s = player_ans[5:4]  == 2'd0 ? pixel_0 : player_ans[5:4]  == 2'd1 ? pixel_1 : player_ans[5:4]  == 2'd2 ? pixel_2 : pixel_3;
                    3: game_pixel_s = player_ans[7:6]  == 2'd0 ? pixel_0 : player_ans[7:6]  == 2'd1 ? pixel_1 : player_ans[7:6]  == 2'd2 ? pixel_2 : pixel_3;
                    4: game_pixel_s = player_ans[9:8]  == 2'd0 ? pixel_0 : player_ans[9:8]  == 2'd1 ? pixel_1 : player_ans[9:8]  == 2'd2 ? pixel_2 : pixel_3;
                    5: game_pixel_s = player_ans[11:10]== 2'd0 ? pixel_0 : player_ans[11:10]== 2'd1 ? pixel_1 : player_ans[11:10]== 2'd2 ? pixel_2 : pixel_3;
                    6: game_pixel_s = player_ans[13:12]== 2'd0 ? pixel_0 : player_ans[13:12]== 2'd1 ? pixel_1 : player_ans[13:12]== 2'd2 ? pixel_2 : pixel_3;
                    7: game_pixel_s = player_ans[15:14]== 2'd0 ? pixel_0 : player_ans[15:14]== 2'd1 ? pixel_1 : player_ans[15:14]== 2'd2 ? pixel_2 : pixel_3;
                    8: game_pixel_s = player_ans[17:16]== 2'd0 ? pixel_0 : player_ans[17:16]== 2'd1 ? pixel_1 : player_ans[17:16]== 2'd2 ? pixel_2 : pixel_3;
                    9: game_pixel_s = player_ans[19:18]== 2'd0 ? pixel_0 : player_ans[19:18]== 2'd1 ? pixel_1 : player_ans[19:18]== 2'd2 ? pixel_2 : pixel_3;
                    10:game_pixel_s = player_ans[21:20]== 2'd0 ? pixel_0 : player_ans[21:20]== 2'd1 ? pixel_1 : player_ans[21:20]== 2'd2 ? pixel_2 : pixel_3;
                    11:game_pixel_s = player_ans[23:22]== 2'd0 ? pixel_0 : player_ans[23:22]== 2'd1 ? pixel_1 : player_ans[23:22]== 2'd2 ? pixel_2 : pixel_3;
                    12:game_pixel_s = player_ans[25:24]== 2'd0 ? pixel_0 : player_ans[25:24]== 2'd1 ? pixel_1 : player_ans[25:24]== 2'd2 ? pixel_2 : pixel_3;
                    13:game_pixel_s = player_ans[27:26]== 2'd0 ? pixel_0 : player_ans[27:26]== 2'd1 ? pixel_1 : player_ans[27:26]== 2'd2 ? pixel_2 : pixel_3;
                    14:game_pixel_s = player_ans[29:28]== 2'd0 ? pixel_0 : player_ans[29:28]== 2'd1 ? pixel_1 : player_ans[29:28]== 2'd2 ? pixel_2 : pixel_3;
                    15:game_pixel_s = player_ans[31:30]== 2'd0 ? pixel_0 : player_ans[31:30]== 2'd1 ? pixel_1 : player_ans[31:30]== 2'd2 ? pixel_2 : pixel_3;
                endcase

                if(RGB_reversed) begin
                    game_pixel[11:8] = 15 - game_pixel_s[11:8];
                    game_pixel[7:4]  = 15 - game_pixel_s[7:4];
                    game_pixel[3:0]  = 15 - game_pixel_s[3:0];
                end
                else game_pixel = game_pixel_s;

                pixel = game_pixel;
            end
            else pixel = 12'd0; 
        end
    endcase
end

endmodule
module GameCenter(
    input wire clk,
    input wire rst,
    input wire check_en,                      // Enable signal to start the check
    input wire [31:0] answer,                 // The chosen puzzle answer (e.g., puzzle_one_ans)
    input wire [31:0] display_puzzle_transform, // Player's input to be checked
    output reg [15:0] puzzle_solved           // 16-bit output: a '1' indicates a correct 2-bit segment
);

    integer i;

    always @(*) begin
        puzzle_solved = 16'h0000; 

        if (check_en) begin
            for(i=0; i<16; i=i+1) begin
                
                if (answer[i*2 +:2] == display_puzzle_transform[i*2 +:2]) begin
                    puzzle_solved[i] = 1'b1;
                end
            end
        end
    end

endmodule

module mem_addr_gen(
    input clk,
    input rst,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    output [14:0] pixel_addr
);
    assign pixel_addr = (  (h_cnt) +  160 * (v_cnt)) % 19200;
endmodule

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
