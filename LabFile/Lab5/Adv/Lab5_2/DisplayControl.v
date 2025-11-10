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
