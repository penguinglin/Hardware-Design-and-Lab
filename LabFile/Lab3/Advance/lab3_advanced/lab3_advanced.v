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

// ==================================================== //
//  FSM State definitions                               //
// ==================================================== //
reg [1:0] cs,ns; // Current state (cs) and next state (ns)
parameter INITIAL = 2'd0, PRACTICE = 2'd1, TIMING = 2'd2, FINAL = 2'd3; 

// ==================================================== //
//  Game Logic                                          //
// ==================================================== //
reg [1:0] puzzle_cnt; // Current puzzle index (0, 1, or 2)
reg [6:0] BCD1,BCD2,BCD3,BCD4; // 7-segment display values for 4 digits
reg [6:0] score1,score2,score3; // Best scores for each puzzle
reg [1:0] sec_f; // Counter for seconds in FINAL state
reg [3:0] sol_count;//count how many lines in the puzzles have been solved
reg [6:0] cur_time,display_cur_time_h,display_cur_time_l,display_score_h,display_score_l; // Current time and display values
reg sec_count; // Toggle signal used for display refreshing in PRACTIVE/TIMING state
reg p1_solved,p2_solved,p3_solved,LED_ON,solved,entered; // Flags for puzzle solved status and LED control
reg finish;//puzzle has been solved, go to FINAL

// ==================================================== //
//  Score and Time Splitting                            //
// ==================================================== //
wire [7:0] score1_h,score1_l;
wire [7:0] score2_h,score2_l;
wire [7:0] score3_h,score3_l;
wire [6:0] cur_time_h,cur_time_l;
assign cur_time_h = cur_time / 7'd10;
assign cur_time_l = cur_time % 7'd10;
assign score1_h = score1 / 7'd10;
assign score1_l = score1 % 7'd10;
assign score2_h = score2 / 7'd10;
assign score2_l = score2 % 7'd10;
assign score3_h = score3 / 7'd10;
assign score3_l = score3 % 7'd10;

// ==================================================== //
//  Puzzle Definitions                                  //
// ==================================================== //
parameter puzzle1_1 = 7'b0000001,puzzle1_2 = 7'b1111111;
parameter puzzle2_1 = 7'b0011100,puzzle2_2 = 7'b0011110;
parameter puzzle3_1 = 7'b0011100,puzzle3_2 = 7'b0000011;

// ==================================================== //
//  Clock Generation                                    //
// ==================================================== //
// 0.5sec clock
wire clk_slow,clk_scan;
reg[28:0]counter;
reg [27:0] counter_1sec;
reg flash;
assign clk_slow = flash;
// 0.5 sec counter and clk signal
always @(posedge clk or posedge rst)begin
    if(rst)begin
        counter <= 28'd0;
        flash <= 1'd0;
    end
    else begin
        if(counter < 50000000 - 1)begin
            counter <= counter + 1;
        end
        else begin
            counter <= 0;
            flash <= !flash;
        end
    end
end
// 1 sec counter
reg clock_1sec;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_1sec <= 28'd0;
            clock_1sec <= 1'd0;
        end
        else begin
            if (counter_1sec < 100_000_000 - 1) begin
                counter_1sec <= counter_1sec + 1;
            end
            else begin
                counter_1sec <= 28'd0;
                clock_1sec <= 1'd1;
            end
        end
    end
// Original clock_divider for 7-segment scanning
clock_divider #(.n(16)) scan_div (
    .clk(clk),
    .clk_div(clk_scan)
);
// count 3 second
always @(posedge clk_slow or posedge rst) begin
    if(rst)begin
        sec_f <= 2'd0;
    end
    else begin
        if(cs == FINAL)begin
            if (clock_1sec) begin
                sec_f <= sec_f + 2'd1;
            end
        end
        else begin
            sec_f <= 2'd0;
        end
    end
end

// ==================================================== //
//  LED Flashing Logic                                  //
// ==================================================== //
// LED ON to control the light should hold or flash
always @(*) begin
    if(cs == FINAL && solved)begin
        if(mode == 1'd0)begin
            if(flash)LED = 16'hFFFF;
            else LED =16'h0;
        end
        else begin
            if(LED_ON)LED = 16'hFFFF;
            else begin
                if(flash)LED = 16'hFFFF;
                else LED =16'h0;
            end
        end
    end
    else begin
        LED = 16'h0;    
    end
end

// ==================================================== //
//  7-Segment Display                                   //
// ==================================================== //
// Scan 4 digits to display
always@(posedge clk_scan or posedge rst)begin
    if(rst)begin
        DIGIT <= 4'b1110;
        DISPLAY <= 7'b111_1111;
    end
    else begin
        case(DIGIT)
            4'b1110:begin
                DISPLAY <= BCD3;
                DIGIT <= 4'b1101;
            end
            4'b1101:begin
                DISPLAY <= BCD2;
                DIGIT <= 4'b1011;
            end
            4'b1011:begin
                DISPLAY <= BCD1;
                DIGIT <= 4'b0111;
            end
            4'b0111:begin
                DISPLAY <= BCD4;
                DIGIT <= 4'b1110;
            end
            default:begin
                DISPLAY <= BCD4;
                DIGIT <= 4'b1110;
            end
        endcase
    end
end
// Display encoding for current time
always@(*)begin
    case(cur_time_h)
    7'd0:display_cur_time_h = 7'b111_1111;
    7'd1:display_cur_time_h = 7'b100_1111;
    7'd2:display_cur_time_h = 7'b001_0010;
    7'd3:display_cur_time_h = 7'b000_0110;
    7'd4:display_cur_time_h = 7'b100_1100;
    7'd5:display_cur_time_h = 7'b010_0100;
    7'd6:display_cur_time_h = 7'b010_0000;
    7'd7:display_cur_time_h = 7'b000_1111;
    7'd8:display_cur_time_h = 7'b000_0000;
    7'd9:display_cur_time_h = 7'b000_0100;
    default:display_cur_time_h = 7'b111_1111;
    endcase
end
always@(*)begin
    if (cur_time == 7'd0) begin
        display_cur_time_l = 7'b111_1111; // 全暗
    end else begin
        case(cur_time_l)
        7'd0:display_cur_time_l = 7'b000_0001;
        7'd1:display_cur_time_l = 7'b100_1111;
        7'd2:display_cur_time_l = 7'b001_0010;
        7'd3:display_cur_time_l = 7'b000_0110;
        7'd4:display_cur_time_l = 7'b100_1100;
        7'd5:display_cur_time_l = 7'b010_0100;
        7'd6:display_cur_time_l = 7'b010_0000;
        7'd7:display_cur_time_l = 7'b000_1111;
        7'd8:display_cur_time_l = 7'b000_0000;
        7'd9:display_cur_time_l = 7'b000_0100;
        default:display_cur_time_l = 7'b111_1111;
        endcase
    end
end
// 根據 puzzle_cnt 和解題狀態決定顯示分數
always @(*) begin
    case(puzzle_cnt)
    2'd0:begin
        if(p1_solved)begin
        case(score1_h)
            7'd0:display_score_h = 7'b000_0001;
            7'd1:display_score_h = 7'b100_1111;
            7'd2:display_score_h = 7'b001_0010;
            7'd3:display_score_h = 7'b000_0110;
            7'd4:display_score_h = 7'b100_1100;
            7'd5:display_score_h = 7'b010_0100;
            7'd6:display_score_h = 7'b010_0000;
            7'd7:display_score_h = 7'b000_1111;
            7'd8:display_score_h = 7'b000_0000;
            7'd9:display_score_h = 7'b000_0100;
            default:display_score_h = 7'b111_1111;
        endcase
        case(score1_l)
            7'd0:display_score_l = 7'b000_0001;
            7'd1:display_score_l = 7'b100_1111;
            7'd2:display_score_l = 7'b001_0010;
            7'd3:display_score_l = 7'b000_0110;
            7'd4:display_score_l = 7'b100_1100;
            7'd5:display_score_l = 7'b010_0100;
            7'd6:display_score_l = 7'b010_0000;
            7'd7:display_score_l = 7'b000_1111;
            7'd8:display_score_l = 7'b000_0000;
            7'd9:display_score_l = 7'b000_0100;
            default:display_score_l = 7'b111_1111;
        endcase
        end
        else begin
            display_score_h = 7'b111_1110;
            display_score_l = 7'b111_1110;
        end
    end
    2'd1:begin
        if(p2_solved)begin
        case(score2_h)
            7'd0:display_score_h = 7'b000_0001;
            7'd1:display_score_h = 7'b100_1111;
            7'd2:display_score_h = 7'b001_0010;
            7'd3:display_score_h = 7'b000_0110;
            7'd4:display_score_h = 7'b100_1100;
            7'd5:display_score_h = 7'b010_0100;
            7'd6:display_score_h = 7'b010_0000;
            7'd7:display_score_h = 7'b000_1111;
            7'd8:display_score_h = 7'b000_0000;
            7'd9:display_score_h = 7'b000_0100;
            default:display_score_h = 7'b111_1111;
        endcase
        case(score2_l)
            7'd0:display_score_l = 7'b000_0001;
            7'd1:display_score_l = 7'b100_1111;
            7'd2:display_score_l = 7'b001_0010;
            7'd3:display_score_l = 7'b000_0110;
            7'd4:display_score_l = 7'b100_1100;
            7'd5:display_score_l = 7'b010_0100;
            7'd6:display_score_l = 7'b010_0000;
            7'd7:display_score_l = 7'b000_1111;
            7'd8:display_score_l = 7'b000_0000;
            7'd9:display_score_l = 7'b000_0100;
            default:display_score_l = 7'b111_1111;
        endcase
        end
        else begin
            display_score_h = 7'b111_1110;
            display_score_l = 7'b111_1110;
        end
    end
    2'd2:begin
        if(p3_solved)begin
        case(score3_h)
            7'd0:display_score_h = 7'b000_0001;
            7'd1:display_score_h = 7'b100_1111;
            7'd2:display_score_h = 7'b001_0010;
            7'd3:display_score_h = 7'b000_0110;
            7'd4:display_score_h = 7'b100_1100;
            7'd5:display_score_h = 7'b010_0100;
            7'd6:display_score_h = 7'b010_0000;
            7'd7:display_score_h = 7'b000_1111;
            7'd8:display_score_h = 7'b000_0000;
            7'd9:display_score_h = 7'b000_0100;
            default:display_score_l = 7'b111_1111;
        endcase
        case(score3_l)
            7'd0:display_score_l = 7'b000_0001;
            7'd1:display_score_l = 7'b100_1111;
            7'd2:display_score_l = 7'b001_0010;
            7'd3:display_score_l = 7'b000_0110;
            7'd4:display_score_l = 7'b100_1100;
            7'd5:display_score_l = 7'b010_0100;
            7'd6:display_score_l = 7'b010_0000;
            7'd7:display_score_l = 7'b000_1111;
            7'd8:display_score_l = 7'b000_0000;
            7'd9:display_score_l = 7'b000_0100;
            default:display_score_l = 7'b111_1111;
        endcase
        end
        else begin
            display_score_h = 7'b111_1110;
            display_score_l = 7'b111_1110;
        end
    end
    default:begin
        display_score_l = 7'b111_1110;
        display_score_l = 7'b111_1110;
    end
    endcase
end
// Update 7-segment display values based on state and puzzle
always @(posedge clk_slow or posedge rst) begin
    if(rst)begin
        BCD1 <= 7'b1111111;
        BCD2 <= 7'b1111111;
        BCD3 <= 7'b1111111;
        BCD4 <= 7'b1111111;
    end
    else begin
        case(cs)
        INITIAL:begin
            BCD3 <= display_score_h;
            BCD4 <= display_score_l;
            case(puzzle_cnt)
            2'd0:begin
                BCD1 <= puzzle1_1;
                BCD2 <= puzzle1_2;
            end
            2'd1:begin
                BCD1 <= puzzle2_1;
                BCD2 <= puzzle2_2;
            end
            2'd2:begin
                BCD1 <= puzzle3_1;
                BCD2 <= puzzle3_2;
            end
            endcase
        end
        PRACTICE,TIMING:begin
            if(cs == PRACTICE)begin // --
                BCD3 <= 7'b1111111;
                BCD4 <= 7'b1111111;
            end
            else if(cs == TIMING)begin
                if(finish)begin
                    BCD3 <= 7'b1111111;
                    BCD4 <= 7'b1111111;
                end
                else begin
                    BCD3 <= display_cur_time_h;
                    BCD4 <= display_cur_time_l;
                end
            end

            case(puzzle_cnt)
            2'd0:begin
                case(sol_count)
                    4'd0:begin
                        BCD1 <= 7'b0100001;
                        BCD2 <= puzzle1_2;
                    end
                    4'd1:begin
                        if(sec_count == 1'd1)begin
                        BCD1 <= 7'b0110001;
                        BCD2 <= puzzle1_2;
                        end
                    end
                    4'd2:begin
                        if(sec_count == 1'd1)begin
                        BCD1 <= 7'b0111001;
                        BCD2 <= puzzle1_2;
                        end
                    end
                    4'd3:begin
                        if(sec_count == 1'd1)begin
                        BCD1 <= 7'b0111101;
                        BCD2 <= puzzle1_2;
                        end
                    end
                    4'd4:begin
                        if(sec_count == 1'd1)begin
                        BCD1 <= 7'b0111111;
                        BCD2 <= puzzle1_2;
                        end
                    end
                    //sol_count = 5 means solved, should go to final state
                    4'd5:begin
                        if(sec_count == 1'd1)begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= puzzle1_2;
                        end
                    end
                endcase
            end
            2'd1:begin//puzzle 2
                case(sol_count)
                    4'd0:begin
                        BCD1 <= 7'b0111100;
                        BCD2 <= 7'b0011110;
                    end
                    4'd1:begin
                        if(sec_count == 1'd1)begin
                        BCD1 <= 7'b0111101;
                        BCD2 <= 7'b0011110;
                        end
                    end
                    4'd2:begin
                        if(sec_count == 1'd1)begin
                        BCD1 <= 7'b0111111;
                        BCD2 <= 7'b0011110;
                        end
                    end
                    4'd3:begin
                        if(sec_count == 1'd1)begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= 7'b0011110;
                        end
                    end
                    4'd4:begin
                        if(sec_count == 1'd1)begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= 7'b1011110;
                        end
                    end
                    4'd5:begin
                        if(sec_count == 1'd1)begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= 7'b1111110;
                        end
                    end
                    //sol_count = 6 means solved, should go to final state
                    4'd6:begin
                        if(sec_count == 1'd1)begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= 7'b1111111;
                        end
                    end
                endcase
            end
            2'd2:begin//puzzle 3
                case(sol_count)
                    4'd0:begin
                        BCD1 <= 7'b0111100;
                        BCD2 <= 7'b0000011;
                    end
                    4'd1:begin
                        if(sec_count == 1'd1)begin
                        BCD1 <= 7'b0111101;
                        BCD2 <= 7'b0000011;
                        end
                    end
                    4'd2:begin
                        if(sec_count == 1'd1)begin
                        BCD1 <= 7'b0111111;
                        BCD2 <= 7'b0000011;
                        end
                    end
                    4'd3:begin
                        if(sec_count == 1'd1)begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= 7'b0000011;
                        end
                    end
                    4'd4:begin
                        if(sec_count == 1'd1)begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= 7'b1000011;
                        end
                    end
                    4'd5:begin
                        if(sec_count == 1'd1)begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= 7'b1100011;
                        end
                    end
                    4'd6:begin
                        if(sec_count == 1'd1)begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= 7'b1110011;
                        end
                    end
                    4'd7:begin
                        if(sec_count == 1'd1)begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= 7'b1111011;
                        end
                    end
                    //sol_count=8 means solved, should go to final state
                    4'd8:begin
                        if(sec_count == 1'd1)begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= 7'b1111111;
                        end
                    end
                endcase
            end
            endcase
        end
        FINAL:begin
            if(mode == 1'd0)begin//Practice
                BCD1 <= 7'b0011000;//P
                BCD2 <= 7'b1111010;//r
                BCD3 <= 7'b0001000;//A
                BCD4 <= 7'b0110001;//c
            end
            else begin
                BCD2 <= 7'b1111110;
                BCD3 <= display_score_h;
                BCD4 <= display_score_l;
                case(puzzle_cnt)
                2'd0:begin
                    BCD1 <= 7'b1001111;
                end
                2'd1:begin
                    BCD1 <= 7'b0010010;
                end
                2'd2:begin
                    BCD1 <= 7'b0000110;
                end
                endcase
            end
        end
        endcase
    end
end

// ==================================================== //
//  State Machine Control                               //
// ==================================================== //
// clk trigger for state transition
always @(posedge clk_slow or posedge rst)begin
    if(rst)begin
        cs <= INITIAL;
    end
    else begin
        cs <= ns;
    end
end
always@(*)begin
    case(cs)
    INITIAL:begin
        if(play)begin
            if(mode == 1'd0)begin
                ns = PRACTICE;
            end
            else begin
                ns = TIMING;
            end
        end
        else begin
            ns = INITIAL;
        end
    end
    PRACTICE:begin
        if(finish)begin
            ns = FINAL;
        end
        else begin
            ns = PRACTICE;
        end
    end
    TIMING:begin
        if(finish)begin
            ns = FINAL;
        end
        else begin
            ns = TIMING;
        end
    end
    FINAL:begin
        if(sec_f == 2'd3)begin
            ns = INITIAL;
        end
        else begin
            ns = FINAL;
        end
    end
    endcase
end

// ==================================================== //
//  Game Logic and Timing                               //
// ==================================================== //
// Puzzle Selection Logic - INITIAL
// Use puzzle_cnt to track current puzzle (0, 1, or 2), and display
always@(posedge clk_slow or posedge rst)begin
    if(rst)begin
        puzzle_cnt <= 2'd0;
    end
    else begin
        if(cs == INITIAL)begin
            if(right)begin
                if(puzzle_cnt == 2'd2)begin
                    puzzle_cnt <= 2'd0;
                end
                else begin
                    puzzle_cnt <= puzzle_cnt + 2'd1;
                end
            end
            else if(left)begin
                if(puzzle_cnt == 2'd0)begin
                    puzzle_cnt <= 2'd2;
                end
                else begin
                    puzzle_cnt <= puzzle_cnt - 2'd1;
                end
            end
        end
        else begin
            puzzle_cnt <= puzzle_cnt;
        end
    end
end
// control solved signal
always @(posedge clk_slow or posedge rst) begin
    if(rst)begin
        solved <= 1'd0;
    end
    else begin
        if(cs == INITIAL)begin
            solved <= 1'd0;
        end
        else begin
        if(cs == FINAL)begin
            solved <= 1'd1;
        end
        end
    end
end
// Update the record score & LED_ON logic
always @(posedge clk_slow or posedge rst) begin
    if(rst)begin
        score1 <= 7'd100;
        score2 <= 7'd100;
        score3 <= 7'd100;
        LED_ON <= 1'd0; // hold LED
        entered <= 1'd0;
    end
    else begin
        if(cs == INITIAL)begin
            LED_ON <= 1'd0;
            entered <= 1'd0;
        end
        else begin
        if(finish && mode == 1'd1 && entered == 1'd0)begin
            entered <= 1'd1;
            case(puzzle_cnt)
            2'd0:begin
                if(score1 >= cur_time)begin
                    score1 <= cur_time;
                    LED_ON <= 1'd0; // let LED flash
                end
                else begin
                    LED_ON <= 1'd1; // keep LED light
                end
            end
            2'd1:begin
                if(score2 >= cur_time)begin
                    score2 <= cur_time;
                    LED_ON <= 1'd0;
                end
                else begin
                    LED_ON <= 1'd1;
                end
            end
            2'd2:begin
                if(score3 >= cur_time)begin
                    score3 <= cur_time;
                    LED_ON <= 1'd0;
                end
                else begin
                    LED_ON <= 1'd1;
                end
            end
            endcase
        end
        end
    end
end
// Detail Display when the game start & Update p#_solved & clock update
always @(posedge clk_slow or posedge rst) begin
    if(rst)begin
        sol_count <= 4'd0;
        cur_time <= 7'd0;
        sec_count <= 1'd0;
        finish <= 1'd0;
        p1_solved <= 1'd0;
        p2_solved <= 1'd0;
        p3_solved <= 1'd0;
    end
    else begin
        if(cs == INITIAL || cs == FINAL)begin
            sol_count <= 4'd0;
            finish <= 1'd0;
            sec_count <= 1'd0;
            if(cs == INITIAL)begin
                cur_time <= 7'd0;
            end
        end
        else if(cs == PRACTICE || cs == TIMING)begin
            if(mode == 1'd1 && finish)begin // 完成的話發出finish訊號
                case (puzzle_cnt)
                    2'd0: p1_solved <= 1'd1;
                    2'd1: p2_solved <= 1'd1;
                    2'd2: p3_solved <= 1'd1;
                endcase
            end

            // 寫出每一步要display的樣式
            case(puzzle_cnt)
            2'd0:begin
                case(sol_count)
                4'd0:begin
                    if(forward)begin
                        sol_count <= sol_count + 4'd1;
                    end
                    else begin
                        sol_count <= sol_count;
                    end
                end
                4'd1:begin
                    if(right)begin
                        sol_count <= sol_count + 4'd1;
                    end
                    else begin
                        sol_count <= sol_count;
                    end
                end
                4'd2:begin
                    if(right)begin
                        sol_count <= sol_count + 4'd1;
                    end
                    else begin
                        sol_count <= sol_count;
                    end
                end
                4'd3:begin
                    if(forward)begin
                        sol_count <= sol_count + 4'd1;
                    end
                    else begin
                        sol_count <= sol_count;
                    end
                end
                4'd4:begin
                    if(right)begin
                        finish <= 1'd1;
                        sol_count <= sol_count + 4'd1;
                    end
                    else begin
                        finish <= 1'd0;
                    end
                end
                4'd5:begin
                    finish <= 1'd0;
                end
                default:begin
                    sol_count <= sol_count;
                    finish <= 1'd0;
                end
                endcase
            end
            2'd1:begin
                case(sol_count)
                4'd0:begin
                    if(right)begin
                        sol_count <= sol_count + 4'd1;
                    end
                    else begin
                        sol_count <= sol_count;
                    end
                end
                4'd1:begin
                    if(right)begin
                        sol_count <= sol_count + 4'd1;
                    end
                    else begin
                        sol_count <= sol_count;
                    end
                end
                4'd2:begin
                    if(right)begin
                        sol_count <= sol_count + 4'd1;
                    end
                    else begin
                        sol_count <= sol_count;
                    end
                end
                4'd3:begin
                    if(forward)begin
                        sol_count <= sol_count + 4'd1;
                    end
                    else begin
                        sol_count <= sol_count;
                    end
                end
                4'd4:begin
                    if(right)begin
                        sol_count <= sol_count + 4'd1;
                    end
                    else begin
                        sol_count <= sol_count;
                    end
                end
                4'd5:begin
                    if(right)begin
                        finish <= 1'd1;
                        sol_count <= sol_count + 4'd1;
                    end
                    else begin
                        finish <= 1'd0;
                    end
                end
                4'd6:finish <= 1'd0;
                default:begin
                    sol_count <= sol_count;
                    finish <= 1'd0;
                end
                endcase
            end
            2'd2:begin
                case(sol_count)
                4'd0:begin
                    if(right)begin
                        sol_count <= sol_count + 4'd1;
                    end
                    else begin
                        sol_count <= sol_count;
                    end
                end
                4'd1:begin
                    if(right)begin
                        sol_count <= sol_count + 4'd1;
                    end
                    else begin
                        sol_count <= sol_count;
                    end
                end
                4'd2:begin
                    if(right)begin
                        sol_count <= sol_count + 4'd1;
                    end
                    else begin
                        sol_count <= sol_count;
                    end
                end
                4'd3:begin
                    if(forward)begin
                        sol_count <= sol_count + 4'd1;
                    end
                    else begin
                        sol_count <= sol_count;
                    end
                end
                4'd4:begin
                    if(right)begin
                        sol_count <= sol_count + 4'd1;
                    end
                    else begin
                        sol_count <= sol_count;
                    end
                end
                4'd5:begin
                    if(forward)begin
                        sol_count <= sol_count + 4'd1;
                    end
                    else begin
                        sol_count <= sol_count;
                    end
                end
                4'd6:begin
                    if(right)begin
                        sol_count <= sol_count + 4'd1;
                    end
                    else begin
                        sol_count <= sol_count;
                    end
                end
                4'd7:begin
                    if(right)begin
                        finish <= 1'd1;
                        sol_count <= sol_count + 4'd1;
                    end
                    else begin
                        finish <= 1'd0;
                    end
                end
                4'd8:finish <= 1'd0;
                default:begin
                    sol_count <= sol_count;
                    finish <= 1'd0;
                end
                endcase
            end
            endcase
            
            if(sec_count == 1'd1)begin
                sec_count <= 1'd0;
            end
            else begin
                sec_count <= 1'd1;
            end
            // cur_time更新-最多99
            if(cs == TIMING)begin
                if (clock_1sec) begin
                    if (cur_time < 7'd99) begin
                        cur_time <= cur_time + 7'd1;
                    end
                end
            end
            
        end
    end
end

endmodule