//==================================================
//  Module: lab5_2
//  Description: VGA Puzzle Game with Keyboard Input
//==================================================
module lab5_2 (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire [2:0] sw,
    inout  wire PS2_CLK,
    inout  wire PS2_DATA,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output hsync,
    output vsync,
    output reg [15:0] led
);

//==================================================
// Keyboard Signals
//==================================================
reg have_key_down;
wire shift_down;
wire [511:0] key_down;
wire [8:0] last_change;
wire been_ready;

//==================================================
// Button & Debounce Signals
//==================================================
wire rst_;
wire rst_processed;
wire start_;
wire start_processed;

//==================================================
// VGA Display Control
//==================================================
wire clk_25MHz;
wire clk_22;
wire valid;
wire [9:0] h_cnt;  // 640 pixels
wire [9:0] v_cnt;  // 480 pixels
reg [9:0] h_cnt_;
reg [9:0] v_cnt_;
wire [11:0] data0, data1, data2, data3;
wire [14:0] pixel_addr;
reg  [11:0] pixel;
wire [11:0] pixel_0, pixel_1, pixel_2, pixel_3;

// VGA color output
assign {vgaRed, vgaGreen, vgaBlue} = (valid) ? pixel : 12'h0;

//==================================================
// Internal Registers
//==================================================
reg [16:0] init_pixel;
reg [16:0] show_pixel, show_pixel_s;
reg RGB_reversed;
reg [31:0] chosen_puzzle;
integer i;

// Puzzle answers and clue masks
reg [31:0] puzzle1_ans, puzzle2_ans, puzzle3_ans;
reg [15:0] puzzle_placed, puzzle_is_clue;
reg [15:0] puzzle1_is_clue, puzzle2_is_clue, puzzle3_is_clue;
reg [31:0] player_ans;

// Cursor and input states
reg [4:0] cur_num, cur_num_s;
reg [4:0] cur_place, cur_place_s;
reg [2:0] enter_step;

// Display data during game
reg [16:0] game_pixel, game_pixel_s;

//==================================================
// State Machine
//==================================================
localparam INIT   = 2'b00;
localparam SHOW   = 2'b01;
localparam GAME   = 2'b10;
localparam FINISH = 2'b11;
reg [1:0] state, nxt_state;

//---------------------------
// State Transition
//---------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= INIT;
        else
            state <= nxt_state;
    end

    always @(*) begin
        nxt_state = state;
        case (state)
            INIT:   if (start_processed) nxt_state = SHOW;
            SHOW:   if (start_processed) nxt_state = GAME;
            GAME:   if (puzzle_placed == 16'hFFFF) nxt_state = FINISH;
            FINISH: if (start_processed) nxt_state = INIT;
        endcase
    end

//==================================================
// Sequential Logic
//==================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cur_place <= 0;
        end
        else if (state == INIT) begin
            // Initialize puzzles and clues
            puzzle1_ans <= 32'b10_00_11_01_11_01_10_00_00_10_01_11_01_11_00_10;
            puzzle2_ans <= 32'b01_00_11_10_10_11_01_00_00_01_10_11_11_10_00_01;
            puzzle3_ans <= 32'b00_10_01_11_11_01_10_00_01_11_00_10_10_00_11_01;

            puzzle1_is_clue <= 16'b0000_0111_0111_1001;
            puzzle2_is_clue <= 16'b1001_1011_0110_0001;
            puzzle3_is_clue <= 16'b1000_1110_0010_1101;

            enter_step <= 0;
            chosen_puzzle <= puzzle1_ans;
            puzzle_placed <= puzzle1_is_clue;
            puzzle_is_clue <= puzzle1_is_clue;
            player_ans <= 0;
        end
        else if (state == SHOW) begin
            // Select puzzle based on switch input
            case (sw)
                3'b001: begin
                    chosen_puzzle <= puzzle1_ans;
                    puzzle_placed <= puzzle1_is_clue;
                    puzzle_is_clue <= puzzle1_is_clue;
                    player_ans <= puzzle1_ans;
                end
                3'b010: begin
                    chosen_puzzle <= puzzle2_ans;
                    puzzle_placed <= puzzle2_is_clue;
                    puzzle_is_clue <= puzzle2_is_clue;
                    player_ans <= puzzle2_ans;
                end
                3'b100: begin
                    chosen_puzzle <= puzzle3_ans;
                    puzzle_placed <= puzzle3_is_clue;
                    puzzle_is_clue <= puzzle3_is_clue;
                    player_ans <= puzzle3_ans;
                end
                default: begin
                    chosen_puzzle <= puzzle1_ans;
                    puzzle_placed <= puzzle1_is_clue;
                    puzzle_is_clue <= puzzle1_is_clue;
                    player_ans <= puzzle1_ans;
                end
            endcase
        end
        else if (state == GAME) begin
            // Player input sequence: select position → choose number → confirm
            if (enter_step == 0 && cur_place_s != 16) begin
                if (been_ready && key_down[last_change] && !have_key_down && key_down[16'h5A]) begin
                    cur_place <= cur_place_s;
                    if (!puzzle_placed[cur_place_s]) enter_step <= 1;
                end
            end
            else if (enter_step == 1) begin
                case (cur_place)
                    15: player_ans[31:30] <= cur_num;
                    14: player_ans[29:28] <= cur_num;
                    13: player_ans[27:26] <= cur_num;
                    12: player_ans[25:24] <= cur_num;
                    11: player_ans[23:22] <= cur_num;
                    10: player_ans[21:20] <= cur_num;
                    9:  player_ans[19:18] <= cur_num;
                    8:  player_ans[17:16] <= cur_num;
                    7:  player_ans[15:14] <= cur_num;
                    6:  player_ans[13:12] <= cur_num;
                    5:  player_ans[11:10] <= cur_num;
                    4:  player_ans[9:8]   <= cur_num;
                    3:  player_ans[7:6]   <= cur_num;
                    2:  player_ans[5:4]   <= cur_num;
                    1:  player_ans[3:2]   <= cur_num;
                    0:  player_ans[1:0]   <= cur_num;
                endcase

                if (cur_num != 16) puzzle_placed[cur_place] <= 1;
                if (been_ready && key_down[last_change] && !have_key_down && key_down[16'h5A] && cur_num != 16)
                    enter_step <= 2;
            end
            else if (enter_step == 2) begin
                enter_step <= 0;
            end
        end
    end

//--------------------------------------------------
// Keyboard Input Handling (update cursor & number)
//--------------------------------------------------
    always @(posedge clk) begin
        if (enter_step == 2 || state != GAME) begin
            cur_num <= 16;
            cur_place_s <= 16;
        end
        else if (state == GAME) begin
            if (enter_step == 0) begin
                // Select puzzle cell
                if (been_ready && key_down[last_change] && !have_key_down) begin
                    if (key_down[16'h2E]) cur_place_s <= 15;
                    else if (key_down[16'h36]) cur_place_s <= 14;
                    else if (key_down[16'h3D]) cur_place_s <= 13;
                    else if (key_down[16'h3E]) cur_place_s <= 12;
                    else if (key_down[16'h2C]) cur_place_s <= 11;
                    else if (key_down[16'h35]) cur_place_s <= 10;
                    else if (key_down[16'h3C]) cur_place_s <= 9;
                    else if (key_down[16'h43]) cur_place_s <= 8;
                    else if (key_down[16'h34]) cur_place_s <= 7;
                    else if (key_down[16'h33]) cur_place_s <= 6;
                    else if (key_down[16'h3B]) cur_place_s <= 5;
                    else if (key_down[16'h42]) cur_place_s <= 4;
                    else if (key_down[16'h32]) cur_place_s <= 3;
                    else if (key_down[16'h31]) cur_place_s <= 2;
                    else if (key_down[16'h3A]) cur_place_s <= 1;
                    else if (key_down[16'h41]) cur_place_s <= 0;
                end
            end
            else if (enter_step == 1) begin
                // Select number to place
                if (been_ready && key_down[last_change] && !have_key_down) begin
                    if (key_down[16'h16]) cur_num <= 0;
                    else if (key_down[16'h1E]) cur_num <= 1;
                    else if (key_down[16'h26]) cur_num <= 2;
                    else if (key_down[16'h25]) cur_num <= 3;
                end
            end
        end
    end

//--------------------------------------------------
// Keyboard Press Detection
//--------------------------------------------------
    always @(posedge clk or posedge rst_processed) begin
        if (rst_processed)
            have_key_down <= 0;
        else
            have_key_down <= (key_down == 0) ? 0 : 1;
    end

//==================================================
// Display Logic (pixel generation & LED result)
//==================================================
    always @(*) begin
        led = 0;
        RGB_reversed = 0;
        show_pixel = 0;
        show_pixel_s = 0;
        game_pixel_s = 0;
        init_pixel = 0;

        case (state)
            //----------------------------------------
            // INIT 
            //----------------------------------------
            INIT: begin
                init_pixel = 0;
            end

            //----------------------------------------
            // SHOW 
            //----------------------------------------
            SHOW: begin
                show_pixel = pixel_0;
                RGB_reversed = 0;

                if (v_cnt < 120) begin
                    RGB_reversed = 0;
                    if      (h_cnt < 160) show_pixel_s = pixel_0;
                    else if (h_cnt < 320) show_pixel_s = pixel_1;
                    else if (h_cnt < 480) show_pixel_s = pixel_2;
                    else if (h_cnt <= 640) show_pixel_s = pixel_3;
                end

                else if (v_cnt < 240) begin
                    RGB_reversed = 1;
                    if      (h_cnt < 160) show_pixel_s = pixel_0;
                    else if (h_cnt < 320) show_pixel_s = pixel_1;
                    else if (h_cnt < 480) show_pixel_s = pixel_2;
                    else if (h_cnt <= 640) show_pixel_s = pixel_3;
                end

                else begin
                    show_pixel_s = 0;
                end

                if (RGB_reversed) begin
                    show_pixel[11:8] = 15 - show_pixel_s[11:8];
                    show_pixel[7:4]  = 15 - show_pixel_s[7:4];
                    show_pixel[3:0]  = 15 - show_pixel_s[3:0];
                end else begin
                    show_pixel = show_pixel_s;
                end
            end

            //----------------------------------------
            // GAME / FINISH 
            //----------------------------------------
            GAME, FINISH: begin
                RGB_reversed = 0;
                if      (v_cnt < 120)     begin : LAYER_1  // puzzle[15:12]
                    process_row(15, 12, player_ans[31:24]);
                end else if (v_cnt < 240) begin : LAYER_2  // puzzle[11:8]
                    process_row(11, 8, player_ans[23:16]);
                end else if (v_cnt < 360) begin : LAYER_3  // puzzle[7:4]
                    process_row(7, 4, player_ans[15:8]);
                end else begin                      // puzzle[3:0]
                    process_row(3, 0, player_ans[7:0]);
                end
            end
        endcase
    end


//==================================================
// Component Instantiations
//==================================================
// VGA memory blocks
    blk_mem_gen_0 blk_mem_gen_0_inst (.clka(clk_25MHz), .wea(0), .addra(pixel_addr), .dina(data0), .douta(pixel_0));
    blk_mem_gen_1 blk_mem_gen_1_inst (.clka(clk_25MHz), .wea(0), .addra(pixel_addr), .dina(data1), .douta(pixel_1));
    blk_mem_gen_2 blk_mem_gen_2_inst (.clka(clk_25MHz), .wea(0), .addra(pixel_addr), .dina(data2), .douta(pixel_2));
    blk_mem_gen_3 blk_mem_gen_3_inst (.clka(clk_25MHz), .wea(0), .addra(pixel_addr), .dina(data3), .douta(pixel_3));

    // VGA controller
    vga_controller vga_inst (
        .pclk(clk_25MHz),
        .reset(rst_processed),
        .hsync(hsync),
        .vsync(vsync),
        .valid(valid),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt)
    );

    // Memory address generator
    mem_addr_gen mem_addr_gen_inst (
        .clk(clk_22),
        .rst(rst),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr(pixel_addr)
    );

    // Clock divider for VGA pixel clock
    cclock_divider clk_wiz_0_inst (
        .clk(clk),
        .clk1(clk_25MHz),
        .clk_22(clk_22)
    );

    // Keyboard decoder
    KeyboardDecoder key_de (
        .key_down(key_down),
        .last_change(last_change),
        .key_valid(been_ready),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(rst_processed),
        .clk(clk)
    );

    // Button debounce and one-pulse
    debounce db_rst   (.clk(clk), .pb(rst),   .pb_debounced(rst_));
    debounce db_start (.clk(clk), .pb(start), .pb_debounced(start_));
    one_pulse op_rst  (.clk(clk), .pb_in(rst_),   .pb_out(rst_processed));
    one_pulse op_start(.clk(clk), .pb_in(start_), .pb_out(start_processed));

endmodule
