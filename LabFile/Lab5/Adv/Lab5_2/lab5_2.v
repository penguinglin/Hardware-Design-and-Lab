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
