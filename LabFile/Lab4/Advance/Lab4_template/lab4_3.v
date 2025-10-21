`define silence   32'd50000000
`define c4  32'd262   // C4
module lab4_3(
    input wire clk,
    input wire rst,
    inout wire PS2_DATA,   // Keyboard I/O
    inout wire PS2_CLK,    // Keyboard I/O
    output wire [2:0] volume,       // LED: [15:13] volume
    output wire [8:0] LED,         //LED: [8:0] for LFSR state
    output wire audio_mclk, // master clock
    output wire audio_lrck, // left-right clock
    output wire audio_sck,  // serial clock
    output wire audio_sdin, // serial audio data input
    output wire [6:0] DISPLAY,
    output wire [3:0] DIGIT
    );   

    // -----------------------------
    // override buffer
    // -----------------------------
        // display override buffer
        wire [15:0] num_wire;
        wire [3:0] digit_wire;
        wire [6:0] display_wire;
        reg [15:0] display_mux_num;
        reg display_override; // 1 -> show display_mux_num, 0 -> show num_wire  
        // LED override buffer
        wire [8:0] led_wire;

    // -----------------------------
    // FSM State Definition
    // -----------------------------
        localparam S_INITIAL = 2'b00;
        localparam S_GUESS = 2'b01;
        localparam S_FINAL = 2'b10;
        reg[2:0] state, next_state, last_state; // Add last state to record previous state
        reg guess_flag;
        wire kb_init_request;
        assign kb_init_request = (state == S_GUESS && guess_flag);
        wire stateIsGuess = (state == S_GUESS);
        reg [1:0] record; // remember

    // -----------------------------
    // KeyboardControl: Output
    // -----------------------------
        wire [2:0] volume_kb_out;
        wire [8:0] led_kb_out;
        assign volume = volume_kb_out;
        assign LED = led_kb_out;

    // -----------------------------
    // Instantiate KeyboardControl
    // -----------------------------
        wire rst_enter;
        wire submit_enter;
        wire [8:0] lfsr;
        KeyboardControl kb(
            .clk(clk),
            .rst(rst),
            .PS2_DATA(PS2_DATA),
            .PS2_CLK(PS2_CLK),
            .state_init_request(kb_init_request), 
            .stateIsGuess(stateIsGuess),
            .num(num_wire),
            .LED(led_kb_out),
            .volume(volume_kb_out),
            .submit(submit_enter),
            .RST(rst_enter),
            .lfsr_transfer_ready(lfsr) 
        );
        assign led_wire = lfsr;
    // Do one plause detection for submit and return and rst
        reg submit_d; 
        wire submit_pulse;
        assign submit_pulse = submit_enter & ~submit_d;
        always @(posedge clk or posedge rst) begin
            if (rst)
                submit_d <= 1'b0;
            else
                submit_d <= submit_enter;
        end
        reg rst_d;
        wire rst_pulse;
        assign rst_pulse = rst_enter & ~rst_d;
        always @(posedge clk or posedge rst) begin
            if (rst)
                rst_d <= 1'b0;
            else
                rst_d <= rst_enter;
        end

    // -----------------------------
    // FSM Sequential
    // ----------------------------
        always@(posedge clk,posedge rst)begin
            if(rst)begin
                state <= S_INITIAL;
                last_state <= S_INITIAL;
            end else if (rst_pulse) begin
                state <= S_INITIAL;
                last_state <= S_INITIAL;
            end
            else begin
                state <= next_state;
                last_state <= state;
            end
        end

    // -----------------------------
    // FSM Combinational: Transition
    // -----------------------------
        always @(*) begin
            next_state = state;
            case(state)
                S_INITIAL: next_state <= S_GUESS;
                S_GUESS: begin
                    if(submit_pulse) next_state <= S_FINAL;
                    else if(record == 0) next_state <= S_INITIAL;
                    else next_state <= S_GUESS;
                end
                S_FINAL: begin
                    if (submit_pulse) begin 
                        next_state = S_GUESS;
                        // reset guess_flag and record
                        guess_flag = 1;
                        record = 0;
                    end
                    else if (rst_pulse) next_state = S_INITIAL;
                    else next_state = S_FINAL;
                end 
            endcase
        end

    // -----------------------------
    // FSM Sequential: Output & Behavior
    // -----------------------------
        wire right;
        always @(posedge clk or posedge rst) begin
            if(rst) begin
                display_override <= 0;
                display_mux_num <= 16'hCCCC;
                guess_flag <= 1;
            end else if (rst_pulse) begin
                display_override <= 0;
                display_mux_num <= 16'hCCCC;
                guess_flag <= 1;
                record <= 0;
            end else begin  
                case(state)
                    S_INITIAL: begin
                        display_mux_num <= 16'hCCCC;
                        display_override <= 1'b1;
                        guess_flag <= 1;
                        record <= 0;
                    end
                    S_GUESS: begin
                        display_override <= 1'b0;
                        if(guess_flag) begin
                            guess_flag <= 0;
                            display_mux_num <= 16'hCCCC;
                            display_override <= 1'b1;
                        end 
                    end
                    S_FINAL: begin
                        // if right => display GOOD, else display LOSE
                        display_mux_num <= (right)? { 4'd8, 4'd12, 4'd12, 4'd5}:{ 4'd9, 4'd12, 4'd10, 4'd11 };
                        display_override <= 1'b1;
                        guess_flag <= 1;
                        if (submit_pulse) begin
                            record <= 0;
                        end
                    end
                endcase
            end
        end

    // -----------------------------
    // 7 SevenSegmentDisplay
    // -----------------------------
        SevenSegment seven_seg(
        .clk(clk),
        .rst(rst),
        .nums(display_source_num), 
        .digit(DIGIT),
        .display(DISPLAY)
        );
        assign display_source_num = display_override ? display_mux_num : num_wire;

    // -----------------------------
    // Target & Guess Note Logic
    // -----------------------------
        wire [4:0] target_note_index = led_wire % 14; 
        wire [3:0] guess_note_BCD2 = num_wire[7:4];
        wire [3:0] guess_note_BCD1 = num_wire[3:0];
        wire [3:0] octave_offset = (guess_note_BCD1 == 4'd5) ? 4'd7 : 4'd0; 
        wire [4:0] guess_note_index = 
            (guess_note_BCD2 >= 4'd0 && guess_note_BCD2 <= 4'd6) 
            ? (guess_note_BCD2 + octave_offset) 
            : 5'd31;
        assign right = submit_pulse && (guess_note_index == target_note_index);

    // -----------------------------
    // Voice General
    // -----------------------------
        // Internal Signal
        wire [15:0] audio_in_left, audio_in_right; // Left and Right channel audio data input
        reg [31:0] freqL, freqR;           // Raw frequency
        wire [31:0] freq_inL, freq_inR;    // Processed frequency, adapted to the clock rate of Basys3
        wire [2:0] sound;
        note_gen noteGen_00(
            .clk(clk), 
            .rst(rst), 
            .volume(sound),
            .note_div_left(freq_inL), 
            .note_div_right(freq_inR), 
            .audio_left(audio_in_left),     // left sound audio
            .audio_right(audio_in_right)    // right sound audio
        );
        assign sound = volume_kb_out;
        // Speaker controller
        speaker_control sc(
            .clk(clk), 
            .rst(rst), 
            .audio_in_left(audio_in_left),      // left channel audio data input
            .audio_in_right(audio_in_right),    // right channel audio data input
            .audio_mclk(audio_mclk),            // master clock
            .audio_lrck(audio_lrck),            // left-right clock
            .audio_sck(audio_sck),              // serial clock
            .audio_sdin(audio_sdin)             // serial audio data input
        );

    // -----------------------------
    // Clock divider
    // -----------------------------
    // freq_outL, freq_outR
    // Note gen makes no sound, if freq_out = 50000000 / `silence = 1
        wire [4:0] note_number;
        assign note_number = led_wire % 14;
        always@(*)begin
            case(note_number)
                0: freqL = 262;
                1: freqL = 294;
                2: freqL = 330;
                3: freqL = 350;
                4: freqL = 392;
                5: freqL = 440;
                6: freqL = 494;
                7: freqL = 523;
                8: freqL = 587;
                9: freqL = 659;
                10: freqL = 699;
                11: freqL = 784;
                12: freqL = 880;
                13: freqL = 988;
                default:freqL = 1;
            endcase
        end
        always@(*)begin
            freqR = freqL;
        end
        assign freq_inL = (state == S_GUESS) ? 50000000 / freqL : 50000000 / `silence;
        assign freq_inR = (state == S_GUESS) ? 50000000 / freqR : 50000000 / `silence;

endmodule

module KeyboardControl(
    input wire clk,
    input wire rst,
    inout wire PS2_DATA,
    inout wire PS2_CLK,
    input wire state_init_request, // 來自 main module，表示在guess且需要初始化顯示
    input wire stateIsGuess,       // 來自 main module，表示目前是否在guess狀態
    output wire [15:0] num,
    output reg [8:0] LED,
    output reg [2:0] volume,       // W increase, S decrease
    output reg submit,             // Enter 鍵觸發
    output reg RST,                // R 鍵觸發
    output wire [8:0] lfsr_transfer_ready // LFSR 狀態
);

    // -----------------------------
    // Keyboard Decoder Signals
    // -----------------------------
    wire [511:0] key_down;  
    wire [8:0] last_change; 
    wire been_ready;         
    
    // -----------------------------
    // 內部狀態與輸入緩衝
    // -----------------------------
    reg [3:0] BCD1, BCD2, BCD3, BCD4;
    assign num = {BCD4, BCD3, BCD2, BCD1}; 

    reg [1:0] input_state;     

    // -----------------------------
    // PS/2 Control (RST/Debounce/One-pulse for Decoder)
    // -----------------------------
    wire rst_in_debounced;   // rst_
    wire rst_processed;      // onepulse rst_processed

    KeyboardDecoder key_de (
        .key_down(key_down),
        .last_change(last_change),
        .key_valid(been_ready), 
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(rst_in_debounced), 
        .clk(clk)
    );
    
    debounce rst1(
        .clk(clk),
        .pb(rst),
        .pb_debounced(rst_in_debounced)
    );
    
    onepulse rst2(
        .clk(clk),
        .signal(rst_in_debounced),
        .op(rst_processed)
    );

    // -----------------------------
    // Key Codes
    // -----------------------------
    parameter SCAN_C = 9'h21;
    parameter SCAN_D = 9'h23;
    parameter SCAN_E = 9'h24;
    parameter SCAN_F = 9'h29;
    parameter SCAN_G = 9'h34;
    parameter SCAN_A = 9'h1C;
    parameter SCAN_B = 9'h32;

    parameter SCAN_4 = 9'h25;
    parameter SCAN_5 = 9'h2E;
    parameter SCAN_NUM_4 = 9'h6B;
    parameter SCAN_NUM_5 = 9'h73;
    
    parameter SCAN_R = 9'h2D;
    parameter SCAN_W = 9'h1D;
    parameter SCAN_S = 9'h1B;
    parameter SCAN_N = 9'h31;
    parameter SCAN_ENTER = 9'h5A;
    parameter SCAN_BACKSPACE = 9'h66;

    // -----------------------------
    // Key Press Detection (One-pulse for R, Enter, Backspace, W, S)
    // -----------------------------
    wire key_press_n = been_ready && last_change == SCAN_N && key_down[SCAN_N];
    wire key_press_w = been_ready && last_change == SCAN_W && key_down[SCAN_W];
    wire key_press_s = been_ready && last_change == SCAN_S && key_down[SCAN_S];
    wire key_press_r = been_ready && last_change == SCAN_R && key_down[SCAN_R];
    wire key_press_enter = been_ready && last_change == SCAN_ENTER && key_down[SCAN_ENTER];
    wire key_press_backspace = been_ready && last_change == SCAN_BACKSPACE && key_down[SCAN_BACKSPACE];

    // -----------------------------
    // LFSR
    // -----------------------------
    wire [8:0] led_lfsr_out;
    wire lfsr_shift_en = state_init_request | key_press_n;
    
    lfsr9_custom led_lfsr (
        .clk(clk),
        .rst(rst),
        .shift_en(lfsr_shift_en),
        .lfsr(led_lfsr_out)
    );
    
    always @(*) begin
        LED = led_lfsr_out; 
    end

    

    // -----------------------------
    // Volume Control (Sequential)
    // -----------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            volume <= 3'd2;
        end else if (key_press_w) begin
            if (volume < 3'd3)
                volume <= volume + 1;
        end else if (key_press_s) begin
            if (volume > 3'd1)
                volume <= volume - 1;
        end
    end

    // -----------------------------
    // FSM Control Outputs (RST, Submit)
    // -----------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            RST <= 1'b0;
        else
            RST <= key_press_r;
    end

    always @(posedge clk or posedge rst) begin
        if (rst)
            submit <= 1'b0;
        else
            submit <= key_press_enter && input_state == 2'd2; 
    end

    // -----------------------------
    // Input Logic (Sequential)
    // -----------------------------
    always @(posedge clk or posedge rst) begin
        if (rst || state_init_request) begin
            input_state <= 2'd0;
            BCD1 <= 4'hF;
            BCD2 <= 4'hF;
        end else if (stateIsGuess && been_ready && key_down[last_change]) begin
            if (key_press_backspace) begin
                if (input_state == 2'd2) begin
                    input_state <= 2'd1;
                    BCD1 <= 4'hF;
                end else if (input_state == 2'd1) begin
                    input_state <= 2'd0;
                    BCD2 <= 4'hF;
                end
            end else begin 
                case (input_state)
                    2'd0: begin
                        case (last_change)
                            SCAN_C: {BCD2, input_state} <= {4'd0, 2'd1};
                            SCAN_D: {BCD2, input_state} <= {4'd1, 2'd1};
                            SCAN_E: {BCD2, input_state} <= {4'd2, 2'd1};
                            SCAN_F: {BCD2, input_state} <= {4'd3, 2'd1};
                            SCAN_G: {BCD2, input_state} <= {4'd4, 2'd1};
                            SCAN_A: {BCD2, input_state} <= {4'd5, 2'd1};
                            SCAN_B: {BCD2, input_state} <= {4'd6, 2'd1};
                            default: begin BCD2 <= BCD2; input_state <= input_state; end
                        endcase
                    end
                    2'd1: begin
                        case (last_change)
                            SCAN_4, SCAN_NUM_4: {BCD1, input_state} <= {4'd4, 2'd2};
                            SCAN_5, SCAN_NUM_5: {BCD1, input_state} <= {4'd5, 2'd2};
                            default: begin BCD1 <= BCD1; input_state <= input_state; end
                        endcase
                    end
                    default: ; 
                endcase
            end
        end
    end 

endmodule

module lfsr9_custom (
    input  wire clk,
    input  wire rst,       // asynchronous or synchronous reset pulse
    input  wire shift_en,  // one-pulse trigger from button
    output reg  [8:0] lfsr // LFSR state output
);
    wire feedback;
    wire [8:0] next_lfsr;

    wire new_LED6 = lfsr[7] ^ lfsr[0];
    wire new_LED5 = lfsr[6] ^ lfsr[0];
    wire new_LED3 = lfsr[4] ^ lfsr[0];


    assign feedback = lfsr[0];

    // 下一個 LFSR state
    assign next_lfsr = {
        feedback,        // MSB -> LED8
        lfsr[8],         // LED7 右移
        new_LED6,        // LED6
        new_LED5,        // LED5
        lfsr[5],         // LED4 右移
        new_LED3,        // LED3
        lfsr[3],         // LED2 右移
        lfsr[2],         // LED1 右移
        lfsr[1]          // LED0 右移
    };

    always @(posedge clk or posedge rst) begin
        if (rst)
            lfsr <= 9'b101011001;  // Initial value
        else if (shift_en)
            lfsr <= next_lfsr;
    end
endmodule
module note_gen(
    input clk, // clock from crystal
    input rst, // active high reset
    input [2:0] volume, 
    input [21:0] note_div_left, // div for note generation
    input [21:0] note_div_right,
    output [15:0] audio_left,
    output [15:0] audio_right
    );

    // Declare internal signals
    reg [21:0] clk_cnt_next, clk_cnt;
    reg [21:0] clk_cnt_next_2, clk_cnt_2;
    reg b_clk, b_clk_next;
    reg c_clk, c_clk_next;

    // Note frequency generation
    // clk_cnt, clk_cnt_2, b_clk, c_clk
    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            begin
                clk_cnt <= 22'd0;
                clk_cnt_2 <= 22'd0;
                b_clk <= 1'b0;
                c_clk <= 1'b0;
            end
        else
            begin
                clk_cnt <= clk_cnt_next;
                clk_cnt_2 <= clk_cnt_next_2;
                b_clk <= b_clk_next;
                c_clk <= c_clk_next;
            end
    
    // clk_cnt_next, b_clk_next
    always @*
        if (clk_cnt == note_div_left)
            begin
                clk_cnt_next = 22'd0;
                b_clk_next = ~b_clk;
            end
        else
            begin
                clk_cnt_next = clk_cnt + 1'b1;
                b_clk_next = b_clk;
            end

    // clk_cnt_next_2, c_clk_next
    always @*
        if (clk_cnt_2 == note_div_right)
            begin
                clk_cnt_next_2 = 22'd0;
                c_clk_next = ~c_clk;
            end
        else
            begin
                clk_cnt_next_2 = clk_cnt_2 + 1'b1;
                c_clk_next = c_clk;
            end

    // Assign the amplitude of the note
    // Volume is controlled here
    wire signed [15:0] base_l = (b_clk == 1'b0) ? 16'hE000 : 16'h2000;
    wire signed [15:0] base_r = (c_clk == 1'b0) ? 16'hE000 : 16'h2000;
    reg signed [15:0] real_l,real_r;
    always@(*)begin

        case(volume)
            1:begin
                real_l = base_l / 8;
                real_r = base_r / 8;
            end
            2:begin
                real_l = base_l / 2;
                real_r = base_r / 2;
            end
            3:begin
                real_l = base_l;
                real_r = base_r;
            end
            default:begin
                real_l = 0;
                real_r = 0;
            end
        endcase
    end

    assign audio_left = (note_div_left == 22'd1) ? 16'h0000 : real_l;
    assign audio_right = (note_div_right == 22'd1) ? 16'h0000 :real_r;
endmodule

// SevenSegment.v                                         //
// Use nums[15:0] control the 4-digit 7-segment display   //
// nums: {BCD4, BCD3, BCD2, BCD1}                         //
//       0-9:present num 0-9; 10:A; 11:b; 12:-;           //
//       others(1111):nothing                             //

// Modify: here you can add more display type if you want, then outside the module you can pass the "nums" wire to make here display what you want.
// Notice: here can just display at most 16 types, since each BCD is 4 bits.(You must modify nums bit size to make it bigger if you want more types)
module SevenSegment(
	output reg [6:0] display,
	output reg [3:0] digit,
	input wire [15:0] nums,
	input wire rst,
	input wire clk
  );
    
    reg [15:0] clk_divider;
    reg [3:0] display_num;
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		clk_divider <= 16'b0;
    	end else begin
    		clk_divider <= clk_divider + 16'b1;
    	end
    end
    
    always @ (posedge clk_divider[15]) begin
    		case (digit)
    			4'b1110 : begin
						display_num <= nums[7:4];
						digit <= 4'b1101;
					end
    			4'b1101 : begin
						display_num <= nums[11:8];
						digit <= 4'b1011;
					end
    			4'b1011 : begin
						display_num <= nums[15:12];
						digit <= 4'b0111;
					end
    			4'b0111 : begin
						display_num <= nums[3:0];
						digit <= 4'b1110;
					end
    			default : begin
						display_num <= nums[3:0];
						digit <= 4'b1110;
					end				
    		endcase
    end
    
    always @ (*) begin
    	case (display_num)                                  
				0 : display = 7'b0011001;   //4
				1 : display = 7'b0010010;   //5

				// Alpha
				2 : display = 7'b0001000; // A
				3 : display = 7'b0000011; // b
				4 : display = 7'b1000110; // C
				5 : display = 7'b0100001; // d
				6 : display = 7'b0000110; // E
				7 : display = 7'b0001110; // F
				8 : display = 7'b1000010; // G

				// Game State 
				9 : display = 7'b1000111; // L
				10 : display = 7'b0010010; // S
				11 : display = 7'b0000110; // E
				12 : display = 7'b1000000; // 0
				13 : display = 7'b0111111; // -

			default : display = 7'b1111111; //nothing
    	endcase
    end
endmodule
