module lab5_2 (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [2:0] sw,
    inout wire PS2_CLK,
    inout wire PS2_DATA,
    output  [3:0] vgaRed,
    output  [3:0] vgaGreen,
    output  [3:0] vgaBlue,
    output  hsync,
    output  vsync,
    output reg [15:0] led
);
// add your design here
    //keyboard
    reg have_key_down;
    wire shift_down;
	wire [511:0] key_down;
	wire [8:0] last_change;
	wire been_ready;
    //button
    wire rst_;
    wire rst_processed;
    wire start_;
    wire start_processed;
    //displayer
     wire clk_25MHz;
    wire clk_22;
    wire valid;
    wire [9:0] h_cnt; //640
    wire [9:0] v_cnt;  //480
    reg [9:0] h_cnt_;
    reg [9:0] v_cnt_;
    wire [11:0] data0;
    wire [11:0] data1;
    wire [11:0] data2;
    wire [11:0] data3;
    wire [14:0] pixel_addr;
    reg [11:0] pixel;
    wire [11:0] pixel_0;
    wire [11:0] pixel_1;
    wire [11:0] pixel_2;
    wire [11:0] pixel_3;
    assign{vgaRed,vgaGreen,vgaBlue} = (valid == 1'b1)? pixel:12'h0;
    //INIT state
    reg [16:0]init_pixel;
    //SHOW state
    reg[16:0] show_pixel;
    reg[16:0] show_pixel_s;
    reg RGB_reversed;
    reg[31:0] chosen_puzzle;
    integer i;
    //GAME state
    reg [31:0] puzzle1_ans;
    reg [31:0] puzzle2_ans;
    reg [31:0] puzzle3_ans;
    reg [15:0] puzzle_placed;
    reg [15:0] puzzle_is_clue;

    reg [15:0] puzzle1_is_clue;
    reg [15:0] puzzle2_is_clue;
    reg [15:0] puzzle3_is_clue;

    reg [31:0] player_ans;

    reg[4:0] cur_num;//選取哪個數字
    reg[4:0] cur_num_s;
    reg[4:0] cur_place;//選取哪個地方
    reg[4:0] cur_place_s;
    reg[2:0] enter_step;//輸入階段
    
    reg[16:0] game_pixel;
    reg[16:0] game_pixel_s;
    //state
    localparam INIT = 2'b00;
    localparam SHOW = 2'b01;
    localparam GAME = 2'b10;
    localparam FINISH = 2'b11;
    reg [1:0] state;
    reg [1:0] nxt_state;

    always@(posedge clk, posedge rst)begin
        if(rst)state <= INIT;
        else state <= nxt_state;
    end

    always@(*)begin
        nxt_state = state;
        case(state)
        INIT:begin
            if(start_processed)nxt_state = SHOW;
            else nxt_state = INIT;
        end
        SHOW:begin
            if(start_processed)nxt_state = GAME;
            else nxt_state = SHOW;
        end
        GAME:begin
            if(puzzle_placed == 16'b1111_1111_1111_1111)nxt_state <= FINISH;
            else nxt_state <= GAME;
        end
        FINISH:begin
            if(start_processed)nxt_state = INIT;
            else nxt_state = FINISH;
        end
        endcase
    end
//sequential logic----------------------------------------------------------------------------------------------------------
always@(posedge clk, posedge rst)begin
    if(rst)begin
        cur_place <= 0;
    end
    else if(state == INIT)begin
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
    else if(state == SHOW)begin
        case(sw)
        3'b001:begin
            chosen_puzzle <= puzzle1_ans;
            puzzle_placed <= puzzle1_is_clue;
            puzzle_is_clue <= puzzle1_is_clue;
            player_ans <= puzzle1_ans;
        end
        3'b010:begin
            chosen_puzzle <= puzzle2_ans;
            puzzle_placed <= puzzle2_is_clue;
            puzzle_is_clue <= puzzle2_is_clue;
            player_ans <= puzzle2_ans;
        end
        3'b100:begin
            chosen_puzzle <= puzzle3_ans;
            puzzle_placed <= puzzle3_is_clue;
            puzzle_is_clue <= puzzle3_is_clue;
            player_ans <= puzzle3_ans;
        end
        default:begin
            chosen_puzzle <= puzzle1_ans;
            puzzle_placed <= puzzle1_is_clue;
            puzzle_is_clue <= puzzle1_is_clue;
            player_ans <= puzzle1_ans;
        end
        endcase

        
    end
    else if(state == GAME)begin
        if(enter_step == 0 && cur_place_s != 16)begin
            if(been_ready && key_down[last_change] == 1'b1&& have_key_down == 0 && key_down[16'h5A] == 1)begin
                cur_place <= cur_place_s;
                if(puzzle_placed[cur_place_s] == 0)begin
                    enter_step <= 1;
                end
            end
        end
        else if(enter_step == 1)begin
            case(cur_place)
                15:player_ans[31:30] <= cur_num;
                14:player_ans[29:28] <= cur_num;
                13:player_ans[27:26] <= cur_num;
                12:player_ans[25:24] <= cur_num;
                11:player_ans[23:22] <= cur_num;
                10:player_ans[21:20] <= cur_num;
                9:player_ans[19:18] <= cur_num;
                8:player_ans[17:16] <= cur_num;
                7:player_ans[15:14] <= cur_num;
                6:player_ans[13:12] <= cur_num;
                5:player_ans[11:10] <= cur_num;
                4:player_ans[9:8] <= cur_num;
                3:player_ans[7:6] <= cur_num;
                2:player_ans[5:4] <= cur_num;
                1:player_ans[3:2] <= cur_num;
                0:player_ans[1:0] <= cur_num;
                default:;
            endcase
            if(cur_num != 16)puzzle_placed[cur_place] <= 1;
            if(been_ready && key_down[last_change] == 1'b1&& have_key_down == 0 && key_down[16'h5A] == 1 && cur_num != 16) enter_step <= 2;
        end
        else if(enter_step == 2)begin
            enter_step <= 0;
        end
    end
end


always@(posedge clk)begin//按鍵更新
    if(enter_step == 2 || state != GAME)begin
        cur_num <= 16;
        cur_place_s <= 16;
    end
    else begin
        if(state == GAME)begin
            if(enter_step == 0)begin
                if(been_ready && key_down[last_change] == 1'b1&& have_key_down == 0)begin//有按按鍵
                    if(key_down[16'h2E]) cur_place_s <= 15;
                    else if(key_down[16'h36]) cur_place_s <= 14;
                    else if(key_down[16'h3D]) cur_place_s <= 13;
                    else if(key_down[16'h3E]) cur_place_s <= 12;
                    else if(key_down[16'h2C]) cur_place_s <= 11;
                    else if(key_down[16'h35]) cur_place_s <= 10;
                    else if(key_down[16'h3C]) cur_place_s <= 9;
                    else if(key_down[16'h43]) cur_place_s <= 8;
                    else if(key_down[16'h34]) cur_place_s <= 7;
                    else if(key_down[16'h33]) cur_place_s <= 6;
                    else if(key_down[16'h3B]) cur_place_s <= 5;
                    else if(key_down[16'h42]) cur_place_s <= 4;
                    else if(key_down[16'h32]) cur_place_s <= 3;
                    else if(key_down[16'h31]) cur_place_s <= 2;
                    else if(key_down[16'h3A]) cur_place_s <= 1;
                    else if(key_down[16'h41]) cur_place_s <= 0;
                end
            end
            else if(enter_step == 1) begin
                if(been_ready && key_down[last_change] == 1'b1&& have_key_down == 0)begin//有按按鍵
                    if(key_down[16'h16])cur_num <= 0;
                    else if(key_down[16'h1E]) cur_num <= 1;
                    else if(key_down[16'h26]) cur_num <= 2;
                    else if(key_down[16'h25]) cur_num <= 3;
                end
            end
        end
    end
end
//combinational logic------------------------------------------------------------------------------------------------------


//display
always@(*)begin
    led = 0;
    if(state == INIT)begin
        init_pixel = 0;
    end
    else if(state == SHOW)begin
        show_pixel = pixel_0;
        RGB_reversed = 0;
        if(0 <= v_cnt && v_cnt < 120)begin//第一層
            RGB_reversed = 0;
            if(0 <= h_cnt && h_cnt < 160) show_pixel_s = pixel_0;
            else if(160 <= h_cnt && h_cnt < 320) show_pixel_s = pixel_1;
            else if(320 <= h_cnt && h_cnt < 480) show_pixel_s = pixel_2;
            else if(480 <= h_cnt && h_cnt <= 640) show_pixel_s = pixel_3;
        end
        else if(120 <= v_cnt && v_cnt < 240)begin
            RGB_reversed = 1;
            if(0 <= h_cnt && h_cnt < 160) show_pixel_s = pixel_0;
            else if(160 <= h_cnt && h_cnt < 320) show_pixel_s = pixel_1;
            else if(320 <= h_cnt && h_cnt < 480) show_pixel_s = pixel_2;
            else if(480 <= h_cnt && h_cnt <= 640) show_pixel_s = pixel_3;
        end
        else show_pixel_s = 0;



        if(RGB_reversed)begin
        show_pixel[11:8] = 15 - show_pixel_s[11:8];
        show_pixel[7:4] = 15 - show_pixel_s[7:4];
        show_pixel[3:0] = 15 - show_pixel_s[3:0];
        end
        else begin
            show_pixel = show_pixel_s;
        end
    end
    else if(state == GAME || state == FINISH)begin
        RGB_reversed = 0;
        if(0 <= v_cnt && v_cnt < 120)begin//第一層
            if(0 <= h_cnt && h_cnt < 160)begin
                if(puzzle_is_clue[15])RGB_reversed = 1;
                if(puzzle_placed[15])begin
                    case(player_ans[31:30])
                    0:game_pixel_s = pixel_0;
                    1:game_pixel_s = pixel_1;
                    2:game_pixel_s = pixel_2;
                    3:game_pixel_s = pixel_3;
                    endcase
                end
                else game_pixel_s = 0;
            end
            else if(160 <= h_cnt && h_cnt < 320)begin
                if(puzzle_is_clue[14])RGB_reversed = 1;
                if(puzzle_placed[14])begin
                    case(player_ans[29:28])
                    0:game_pixel_s = pixel_0;
                    1:game_pixel_s = pixel_1;
                    2:game_pixel_s = pixel_2;
                    3:game_pixel_s = pixel_3;
                    endcase
                end
                else game_pixel_s = 0;
            end
            else if(320 <= h_cnt && h_cnt < 480)begin
                if(puzzle_is_clue[13])RGB_reversed = 1;
                if(puzzle_placed[13])begin
                    case(player_ans[27:26])
                    0:game_pixel_s = pixel_0;
                    1:game_pixel_s = pixel_1;
                    2:game_pixel_s = pixel_2;
                    3:game_pixel_s = pixel_3;
                    endcase
                end
                else game_pixel_s = 0;
            end
            else if(480 <= h_cnt && h_cnt <= 640)begin
                if(puzzle_is_clue[12])RGB_reversed = 1;
                if(puzzle_placed[12])begin
                    case(player_ans[25:24])
                    0:game_pixel_s = pixel_0;
                    1:game_pixel_s = pixel_1;
                    2:game_pixel_s = pixel_2;
                    3:game_pixel_s = pixel_3;
                    endcase
                end
                else game_pixel_s = 0;
            end
        end
        else if(120 <= v_cnt && v_cnt < 240)begin//第二層
            if(0 <= h_cnt && h_cnt < 160)begin
                if(puzzle_is_clue[11])RGB_reversed = 1;
                if(puzzle_placed[11])begin
                    case(player_ans[23:22])
                    0:game_pixel_s = pixel_0;
                    1:game_pixel_s = pixel_1;
                    2:game_pixel_s = pixel_2;
                    3:game_pixel_s = pixel_3;
                    endcase
                end
                else game_pixel_s = 0;
            end
            else if(160 <= h_cnt && h_cnt < 320)begin
                if(puzzle_is_clue[10])RGB_reversed = 1;
                if(puzzle_placed[10])begin
                    case(player_ans[21:20])
                    0:game_pixel_s = pixel_0;
                    1:game_pixel_s = pixel_1;
                    2:game_pixel_s = pixel_2;
                    3:game_pixel_s = pixel_3;
                    endcase
                end
                else game_pixel_s = 0;
            end
            else if(320 <= h_cnt && h_cnt < 480)begin
                if(puzzle_is_clue[9])RGB_reversed = 1;
                if(puzzle_placed[9])begin
                    case(player_ans[19:18])
                    0:game_pixel_s = pixel_0;
                    1:game_pixel_s = pixel_1;
                    2:game_pixel_s = pixel_2;
                    3:game_pixel_s = pixel_3;
                    endcase
                end
                else game_pixel_s = 0;
            end
            else if(480 <= h_cnt && h_cnt <= 640)begin
                if(puzzle_is_clue[8])RGB_reversed = 1;
                if(puzzle_placed[8])begin
                    case(player_ans[17:16])
                    0:game_pixel_s = pixel_0;
                    1:game_pixel_s = pixel_1;
                    2:game_pixel_s = pixel_2;
                    3:game_pixel_s = pixel_3;
                    endcase
                end
                else game_pixel_s = 0;
            end
        end
        else if(240 <= v_cnt && v_cnt < 360)begin//第三層
            if(0 <= h_cnt && h_cnt < 160)begin
                if(puzzle_is_clue[7])RGB_reversed = 1;
                if(puzzle_placed[7])begin
                    case(player_ans[15:14])
                    0:game_pixel_s = pixel_0;
                    1:game_pixel_s = pixel_1;
                    2:game_pixel_s = pixel_2;
                    3:game_pixel_s = pixel_3;
                    endcase
                end
                else game_pixel_s = 0;
            end
            else if(160 <= h_cnt && h_cnt < 320)begin
                if(puzzle_is_clue[6])RGB_reversed = 1;
                if(puzzle_placed[6])begin
                    case(player_ans[13:12])
                    0:game_pixel_s = pixel_0;
                    1:game_pixel_s = pixel_1;
                    2:game_pixel_s = pixel_2;
                    3:game_pixel_s = pixel_3;
                    endcase
                end
                else game_pixel_s = 0;
            end
            else if(320 <= h_cnt && h_cnt < 480)begin
                if(puzzle_is_clue[5])RGB_reversed = 1;
                if(puzzle_placed[5])begin
                    case(player_ans[11:10])
                    0:game_pixel_s = pixel_0;
                    1:game_pixel_s = pixel_1;
                    2:game_pixel_s = pixel_2;
                    3:game_pixel_s = pixel_3;
                    endcase
                end
                else game_pixel_s = 0;
            end
            else if(480 <= h_cnt && h_cnt <= 640)begin
                if(puzzle_is_clue[4])RGB_reversed = 1;
                if(puzzle_placed[4])begin
                    case(player_ans[9:8])
                    0:game_pixel_s = pixel_0;
                    1:game_pixel_s = pixel_1;
                    2:game_pixel_s = pixel_2;
                    3:game_pixel_s = pixel_3;
                    endcase
                end
                else game_pixel_s = 0;
            end
        end
        else begin//第四層
            if(0 <= h_cnt && h_cnt < 160)begin
                if(puzzle_is_clue[3])RGB_reversed = 1;
                if(puzzle_placed[3])begin
                    case(player_ans[7:6])
                    0:game_pixel_s = pixel_0;
                    1:game_pixel_s = pixel_1;
                    2:game_pixel_s = pixel_2;
                    3:game_pixel_s = pixel_3;
                    endcase
                end
                else game_pixel_s = 0;
            end
            else if(160 <= h_cnt && h_cnt < 320)begin
                if(puzzle_is_clue[2])RGB_reversed = 1;
                if(puzzle_placed[2])begin
                    case(player_ans[5:4])
                    0:game_pixel_s = pixel_0;
                    1:game_pixel_s = pixel_1;
                    2:game_pixel_s = pixel_2;
                    3:game_pixel_s = pixel_3;
                    endcase
                end
                else game_pixel_s = 0;
            end
            else if(320 <= h_cnt && h_cnt < 480)begin
                if(puzzle_is_clue[1])RGB_reversed = 1;
                if(puzzle_placed[1])begin
                    case(player_ans[3:2])
                    0:game_pixel_s = pixel_0;
                    1:game_pixel_s = pixel_1;
                    2:game_pixel_s = pixel_2;
                    3:game_pixel_s = pixel_3;
                    endcase
                end
                else game_pixel_s = 0;
            end
            else if(480 <= h_cnt && h_cnt <= 640)begin
                if(puzzle_is_clue[0])RGB_reversed = 1;
                if(puzzle_placed[0])begin
                    case(player_ans[1:0])
                    0:game_pixel_s = pixel_0;
                    1:game_pixel_s = pixel_1;
                    2:game_pixel_s = pixel_2;
                    3:game_pixel_s = pixel_3;
                    endcase
                end
                else game_pixel_s = 0;
            end
        end


        if(RGB_reversed)begin
        game_pixel[11:8] = 15 - game_pixel_s[11:8];
        game_pixel[7:4] = 15 - game_pixel_s[7:4];
        game_pixel[3:0] = 15 - game_pixel_s[3:0];
        end
        else begin
            game_pixel = game_pixel_s;
        end

        if(state == FINISH)begin
            led = 0;
            if(chosen_puzzle[31:30] == player_ans[31:30])led[0] = 1;
            if(chosen_puzzle[29:28] == player_ans[29:28])led[1] = 1;
            if(chosen_puzzle[27:26] == player_ans[27:26])led[2] = 1;
            if(chosen_puzzle[25:24] == player_ans[25:24])led[3] = 1;
            if(chosen_puzzle[23:22] == player_ans[23:22])led[4] = 1;
            if(chosen_puzzle[21:20] == player_ans[21:20])led[5] = 1;
            if(chosen_puzzle[19:18] == player_ans[19:18])led[6] = 1;
            if(chosen_puzzle[17:16] == player_ans[17:16])led[7] = 1;
            if(chosen_puzzle[15:14] == player_ans[15:14])led[8] = 1;
            if(chosen_puzzle[13:12] == player_ans[13:12])led[9] = 1;
            if(chosen_puzzle[11:10] == player_ans[11:10])led[10] = 1;
            if(chosen_puzzle[9:8] == player_ans[9:8])led[11] = 1;
            if(chosen_puzzle[7:6] == player_ans[7:6])led[12] = 1;
            if(chosen_puzzle[5:4] == player_ans[5:4])led[13] = 1;
            if(chosen_puzzle[3:2] == player_ans[3:2])led[14] = 1;
            if(chosen_puzzle[1:0] == player_ans[1:0])led[15] = 1;
        end
    end
    
end

//pixel source selector
always@(*)begin
    pixel = init_pixel;
    case(state)
    INIT:pixel = init_pixel;
    SHOW:pixel = show_pixel;
    GAME:pixel = game_pixel;
    FINISH:pixel = game_pixel;
    endcase
end


//-keyboard control---------------------------------------------------------------------------------------------------------------------
    //一次只能有一個按鍵處理
	always@(posedge clk, posedge rst_processed)begin
		if(rst_processed)have_key_down <= 0;
		else have_key_down <= (key_down == 0) ? 0 : 1 ;
	end

//port connection----------------------------------------------------------------------------------------------------------------------
    blk_mem_gen_0 blk_mem_gen_0_inst(
        .clka(clk_25MHz),
        .wea(0),
        .addra(pixel_addr),
        .dina(data0[11:0]),
        .douta(pixel_0)
    );
    blk_mem_gen_1 blk_mem_gen_1_inst(
        .clka(clk_25MHz),
        .wea(0),
        .addra(pixel_addr),
        .dina(data1[11:0]),
        .douta(pixel_1)
    );
    blk_mem_gen_2 blk_mem_gen_2_inst(
        .clka(clk_25MHz),
        .wea(0),
        .addra(pixel_addr),
        .dina(data2[11:0]),
        .douta(pixel_2)
    );
    blk_mem_gen_3 blk_mem_gen_3_inst(
        .clka(clk_25MHz),
        .wea(0),
        .addra(pixel_addr),
        .dina(data3[11:0]),
        .douta(pixel_3)
    );
    vga_controller   vga_inst(
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

    cclock_divider clk_wiz_0_inst(
        .clk(clk),
        .clk1(clk_25MHz),
        .clk_22(clk_22)
        );

    KeyboardDecoder key_de (
		.key_down(key_down),
		.last_change(last_change),
		.key_valid(been_ready),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst_processed),
		.clk(clk)
	);
    debounce v1(
        .clk(clk),
        .pb(rst),
        .pb_debounced(rst_)
    );
    debounce v2(
        .clk(clk),
        .pb(start),
        .pb_debounced(start_)
    );
    one_pulse v3(
        .clk(clk),
        .pb_in(rst_),
        .pb_out(rst_processed)
    );
    one_pulse v4(
        .clk(clk),
        .pb_in(start_),
        .pb_out(start_processed)
    );
endmodule

module mem_addr_gen(
    input clk,
    input rst,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    output [14:0] pixel_addr
);
    assign pixel_addr = (  (h_cnt) +  160 * (v_cnt)) % 19200;//圖片壓縮成四分之一
endmodule

module cclock_divider(clk1,clk,clk_22);
    input clk;
    input clk1;
    input clk_22;
    reg [21:0] num;
    wire [21:0] next_num;
    always@(posedge clk)begin
        num <= next_num;
    end
    assign next_num = num + 1'b1;
    assign clk1 = num[1];
    assign clk_22 = num[21];
endmodule

  