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
