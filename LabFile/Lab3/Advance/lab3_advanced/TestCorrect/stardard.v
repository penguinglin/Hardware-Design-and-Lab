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

reg [1:0] cs,ns;
reg [1:0] puzzle_cnt;
reg [6:0] BCD1,BCD2,BCD3,BCD4;
reg [6:0] score1,score2,score3;
reg sec_count_f;
reg [1:0] sec_f;
reg [3:0] sol_count;//count how many lines in the puzzles have been solved
reg [6:0] cur_time,display_cur_time_h,display_cur_time_l,display_score_h,display_score_l;
reg sec_count;
reg p1_solved,p2_solved,p3_solved,LED_ON;
reg finish;//puzzle has been solved, go to FINAL
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

parameter puzzle1_1 = 7'b0000001,puzzle1_2 = 7'b1111111;
parameter puzzle2_1 = 7'b0011100,puzzle2_2 = 7'b0011110;
parameter puzzle3_1 = 7'b0011100,puzzle3_2 = 7'b0000011;

parameter INITIAL = 2'd0,PRACTICE = 2'd1,TIMING = 2'd2,FINAL = 2'd3;
wire clk_slow;
reg[28:0]counter;
reg clock_05sec;

assign clk_slow = clock_05sec;
    // one sec counter
    always @(posedge clk or posedge rst)begin
        if(rst)begin
            counter <= 28'd0;
            clock_05sec <= 1'd0;
        end
        else begin
            if(counter < 50000000 - 1)begin
                counter <= counter + 1;
            end
            else begin
                counter <= 0;
                clock_05sec <= !clock_05sec;
            end
        end
    end
    // Original clock_divider for 7-segment scanning
    wire clk_scan;
    clock_divider #(.n(16)) scan_div (
        .clk(clk),
        .clk_div(clk_scan)
    );
always @(posedge clk_slow or posedge rst)begin
    if(rst)begin
        cs <= INITIAL;
    end
    else begin
        cs <= ns;
    end
end

always @(posedge clk_slow or posedge rst) begin
    if(rst)begin
        score1 <= 7'd100;
        score2 <= 7'd100;
        score3 <= 7'd100;
        LED_ON <= 1'd0;
    end
    else begin
        if(cs == INITIAL)begin
            LED_ON <= 1'd0;
        end
        else begin
        if(finish)begin
        if(mode == 1'd0)begin
            LED_ON <= 1'd1;
        end
        else begin
        case(puzzle_cnt)
        2'd0:begin
            if(score1 > cur_time)begin
                score1 <= cur_time;
                LED_ON <= 1'd1;
            end
        end
        2'd1:begin
            if(score2 > cur_time)begin
                score2 <= cur_time;
                LED_ON <= 1'd1;
            end
        end
        2'd2:begin
            if(score3 > cur_time)begin
                score3 <= cur_time;
                LED_ON <= 1'd1;
            end
        end
        endcase
        end
        end
        else begin//finish = 0
            if(sec_count_f == 1'd1 && sec_f == 2'd2)LED_ON <= 1'd0;
        end
        end
    end
end

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
            if(cs == PRACTICE)begin
                BCD3 <= 7'b1111111;
                BCD4 <= 7'b1111111;
            end
            else if(cs == TIMING)begin
                BCD3 <= display_cur_time_h;
                BCD4 <= display_cur_time_l;
            end
            if(sec_count == 1'd1)begin
            case(puzzle_cnt)
            2'd0:begin
                case(sol_count)
                    4'd0:begin
                        BCD1 <= 7'b0100001;
                        BCD2 <= puzzle1_2;
                    end
                    4'd1:begin
                        BCD1 <= 7'b0110001;
                        BCD2 <= puzzle1_2;
                    end
                    4'd2:begin
                        BCD1 <= 7'b0111001;
                        BCD2 <= puzzle1_2;
                    end
                    4'd3:begin
                        BCD1 <= 7'b0111101;
                        BCD2 <= puzzle1_2;
                    end
                    4'd4:begin
                        BCD1 <= 7'b0111111;
                        BCD2 <= puzzle1_2;
                    end
                    //sol_count = 5 means solved, should go to final state
                    4'd5:begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= puzzle1_2;
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
                        BCD1 <= 7'b0111101;
                        BCD2 <= 7'b0011110;
                    end
                    4'd2:begin
                        BCD1 <= 7'b0111111;
                        BCD2 <= 7'b0011110;
                    end
                    4'd3:begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= 7'b0011110;
                    end
                    4'd4:begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= 7'b1011110;
                    end
                    4'd5:begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= 7'b1111110;
                    end
                    //sol_count = 6 means solved, should go to final state
                    4'd6:begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= 7'b1111111;
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
                        BCD1 <= 7'b0111101;
                        BCD2 <= 7'b0000011;
                    end
                    4'd2:begin
                        BCD1 <= 7'b0111111;
                        BCD2 <= 7'b0000011;
                    end
                    4'd3:begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= 7'b0000011;
                    end
                    4'd4:begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= 7'b1000011;
                    end
                    4'd5:begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= 7'b1100011;
                    end
                    4'd6:begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= 7'b1110011;
                    end
                    4'd7:begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= 7'b1111011;
                    end
                    //sol_count=8 means solved, should go to final state
                    4'd8:begin
                        BCD1 <= 7'b1111111;
                        BCD2 <= 7'b1111111;
                    end
                endcase
            end
            endcase
            end
            else begin
                BCD1 <= BCD1;
                BCD2 <= BCD2;
            end
        end
        FINAL:begin
            if(mode == 1'd0)begin//Practice
                BCD1 <= 7'b0011000;//P
                BCD2 <= 7'b1111010;//r
                BCD3 <= 7'b0001000;//A
                BCD4 <= 7'b1110010;//c
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


always @(posedge clk_slow or posedge rst) begin
    if(rst)begin
        LED <= 16'd0;
        sec_f <= 2'd0;
        sec_count_f <= 1'd0;
    end
    else begin
        if(cs == FINAL)begin
                if(sec_count_f == 1'd0)LED <= 16'hFFFF;
                else LED <= 16'h0;
            if(sec_count_f == 1'd1)begin
                sec_f <= sec_f + 2'd1;
                sec_count_f <= 1'd0;
            end
            else begin
                sec_count_f <= 1'd1;
            end
        end
        else begin
            LED <= 16'd0;
            sec_f <= 2'd0;
            sec_count_f <= 1'd0;
        end
    end
end

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
            cur_time <= 7'd0;
            if(mode == 1'd1)begin//TIMING
                case (puzzle_cnt)
                    2'd0: p1_solved <= 1'd1;
                    2'd1: p2_solved <= 1'd1;
                    2'd2: p3_solved <= 1'd1;
                    default:begin
                        p1_solved <= p1_solved;
                        p2_solved <= p2_solved;
                        p3_solved <= p3_solved;
                    end
                endcase
            end
        end
        else if(cs == PRACTICE || cs == TIMING)begin
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
                    finish <= finish;
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
                4'd6:finish <= finish;
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
                4'd8:finish <= finish;
                default:begin
                    sol_count <= sol_count;
                    finish <= 1'd0;
                end
                endcase
            end
            endcase
        if(cs == TIMING || cs == PRACTICE)begin
            if(sec_count == 1'd1)begin
                sec_count <= 1'd0;
            end
            else begin
                sec_count <= 1'd1;
            end
            if(cs == TIMING)begin
                if(sec_count == 1'd1)begin
                    cur_time <= cur_time + 7'd1;//max 99
                end
            end
        end
        end
    end
end

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
    case(cur_time_l)
    7'd0:display_cur_time_l = 7'b111_1111;
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

always @(*) begin
    case(puzzle_cnt)
    2'd0:begin
        if(p1_solved)begin
        case(score1_h)
            7'd0:display_score_h = 7'b111_1111;
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
            7'd0:display_score_l = 7'b111_1111;
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
            7'd0:display_score_h = 7'b111_1111;
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
            7'd0:display_score_l = 7'b111_1111;
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
            7'd0:display_score_h = 7'b111_1111;
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
            7'd0:display_score_l = 7'b111_1111;
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
        display_score_l = 7'b111_1111;
        display_score_l = 7'b111_1111;
    end
    endcase
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
        if(sec_count_f == 1'd1 && sec_f == 2'd2)begin
            ns = INITIAL;
        end
        else begin
            ns = FINAL;
        end
    end
    endcase
end

endmodule