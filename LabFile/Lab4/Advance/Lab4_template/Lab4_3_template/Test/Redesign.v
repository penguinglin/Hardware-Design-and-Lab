`define silence 32'd50000000
`define c4 32'd262 

module lab4_3(
    input wire clk,
    input wire rst,
    inout wire PS2_DATA,   
    inout wire PS2_CLK,    
    output reg [2:0] volume,    
    output reg [8:0] LED,         
    output wire audio_mclk,       // Master clock for audio codec
    output wire audio_lrck,       // Left-right clock
    output wire audio_sck,        // Serial clock
    output wire audio_sdin,       // Serial audio data
    output wire [6:0] DISPLAY,   
    output wire [3:0] DIGIT      
);

//=============================================================
//  Signal Declaration
//=============================================================

//----------------------------
// Audio Generation
//----------------------------
wire [15:0] audio_in_left, audio_in_right; 
reg  [31:0] freqL, freqR;                  
wire [31:0] freq_inL, freq_inR;            
wire [4:0]  note_number;                   

//----------------------------
// Keyboard Input
//----------------------------
reg  [3:0]  key_num;
reg  [9:0]  last_key;
reg         have_key_down;
wire        shift_down;
wire [511:0] key_down;
wire [8:0]  last_change;
wire        been_ready;

// Key code mapping
parameter [8:0] KEY_CODES [0:19] = {
    9'b0_0100_0101, // 0 => 45
    9'b0_0001_0110, // 1 => 16
    9'b0_0001_1110, // 2 => 1E
    9'b0_0010_0110, // 3 => 26
    9'b0_0010_0101, // 4 => 25
    9'b0_0010_1110, // 5 => 2E
    9'b0_0011_0110, // 6 => 36
    9'b0_0011_1101, // 7 => 3D
    9'b0_0011_1110, // 8 => 3E
    9'b0_0100_0110, // 9 => 46
    9'b0_0111_0000, // right_0 => 70
    9'b0_0110_1001, // right_1 => 69
    9'b0_0111_0010, // right_2 => 72
    9'b0_0111_1010, // right_3 => 7A
    9'b0_0110_1011, // right_4 => 6B
    9'b0_0111_0011, // right_5 => 73
    9'b0_0111_0100, // right_6 => 74
    9'b0_0110_1100, // right_7 => 6C
    9'b0_0111_0101, // right_8 => 75
    9'b0_0111_1101  // right_9 => 7D
};

//----------------------------
// FSM State Definition
//----------------------------
localparam INITIAL = 2'b00;
localparam GUESS   = 2'b01;
localparam FINAL   = 2'b10; 
reg [2:0] state, nxt_state, last_state;

//----------------------------
// Volume Control
//----------------------------
reg [2:0] sound_lev; 

//----------------------------
// Rst BTNC
//----------------------------
wire rst_;     
wire rst_processed;

//----------------------------
// User Input
//–----------------------------
reg [2:0] input_state;   
reg [4:0] input_alpha;   
reg [4:0] input_number;
wire [5:0] answer = (input_number == 5) ? input_alpha + 7 : input_alpha; 

//----------------------------
// Result Display
//----------------------------
reg result;               
reg [6:0] display0, display1, display2, display3; 

//=============================================================
//  Volume Control
//=============================================================
always @(*) begin
    case (sound_lev)
        1: volume = 3'b100;
        2: volume = 3'b110;
        3: volume = 3'b111;
        default: volume = 3'b100;
    endcase
end

always @(posedge clk) begin
    if (state == INITIAL)
        sound_lev <= 2;
    else begin
        if (been_ready && key_down[last_change] && key_down[8'h1D] && !have_key_down)
            case (sound_lev)
                1: sound_lev <= 2;
                2: sound_lev <= 3;
                3: sound_lev <= 3;
            endcase
        else if (been_ready && key_down[last_change] && key_down[8'h1B] && !have_key_down)
            case (sound_lev)
                1: sound_lev <= 1;
                2: sound_lev <= 1;
                3: sound_lev <= 2;
            endcase
    end
end

//=============================================================
//  LFSR with Note Mapping
//=============================================================
assign note_number = LED % 14;
always @(*) begin
    case (note_number)
        0: freqL = 262;  // C4
        1: freqL = 294;  // D4
        2: freqL = 330;  // E4
        3: freqL = 350;  // F4
        4: freqL = 392;  // G4
        5: freqL = 440;  // A4
        6: freqL = 494;  // B4
        7: freqL = 523;  // C5
        8: freqL = 587;  // D5
        9: freqL = 659;  // E5
        10: freqL = 699; // F5
        11: freqL = 784; // G5
        12: freqL = 880; // A5
        13: freqL = 988; // B5
        default: freqL = 1;
    endcase
end
always @(*) freqR = freqL;

//=============================================================
//  FSM (INITIAL → GUESS → FINAL)
//=============================================================
always @(posedge clk, posedge rst_processed) begin
    if (rst_processed) begin
        state <= INITIAL;
        last_state <= INITIAL;
    end else begin
        state <= nxt_state;
        last_state <= state;
    end
end

always @(*) begin
    nxt_state = state;
    case (state)
        INITIAL: nxt_state = GUESS;
        GUESS: begin
            if (been_ready && key_down[last_change] && key_down[8'h5A] && !have_key_down)
                nxt_state = FINAL; 
            else if (been_ready && key_down[last_change] && key_down[8'h2D] && !have_key_down)
                nxt_state = INITIAL; 
        end
        FINAL: begin
            if (been_ready && key_down[last_change] && key_down[8'h5A] && !have_key_down)
                nxt_state = GUESS;
            else if (been_ready && key_down[last_change] && key_down[8'h2D] && !have_key_down)
                nxt_state = INITIAL;
        end
    endcase
end

//=============================================================
//  Result
//=============================================================
always @(posedge clk) begin
    if (state == GUESS && been_ready && key_down[last_change] && key_down[8'h5A] && !have_key_down)
        result <= (answer == note_number && input_number != 11 && input_alpha != 11);
    else if (state != FINAL)
        result <= 0;
end

//-------------------------------------------------------------
// Seven Segment Display
//-------------------------------------------------------------
always @(*) begin
    if (state == INITIAL) begin
        display0 = num_trans(11);
        display1 = num_trans(11);
        display2 = num_trans(11);
        display3 = num_trans(11);
    end else if (state == GUESS) begin
        display0 = num_trans(11);
        display1 = num_trans(11);
        display2 = alpha_trans(input_alpha);
        display3 = num_trans(input_number);
    end else if (state == FINAL) begin
        if (result) begin
            display0 = 7'b1000010; // g
            display1 = 7'b1000000; // o
            display2 = 7'b1000000; // o
            display3 = 7'b0100001; // d
        end else begin
            display0 = 7'b1000111; // l
            display1 = 7'b1000000; // o
            display2 = 7'b0010010; // s
            display3 = 7'b0000110; // e
        end
    end
end

//-------------------------------------------------------------
// LFSR 
//-------------------------------------------------------------
always @(posedge clk) begin
    if (state == INITIAL)
        LED <= 9'b101011001;
    else if (been_ready && key_down[last_change] && key_down[8'h31] && !have_key_down)
        {LED[8:0]} <= {LED[0], LED[8], (LED[0]^LED[7]), (LED[0]^LED[6]),
                        LED[5], (LED[0]^LED[4]), LED[3], LED[2], LED[1]};
end

//-------------------------------------------------------------
// Output of Audio 
//-------------------------------------------------------------
assign freq_inL = (state == GUESS) ? 50000000 / freqL : 50000000 / `silence;
assign freq_inR = (state == GUESS) ? 50000000 / freqR : 50000000 / `silence;

note_gen noteGen_00(
    .clk(clk),
    .rst(rst),
    .volume(sound_lev),
    .note_div_left(freq_inL),
    .note_div_right(freq_inR),
    .audio_left(audio_in_left),
    .audio_right(audio_in_right)
);

speaker_control sc(
    .clk(clk),
    .rst(rst),
    .audio_in_left(audio_in_left),
    .audio_in_right(audio_in_right),
    .audio_mclk(audio_mclk),
    .audio_lrck(audio_lrck),
    .audio_sck(audio_sck),
    .audio_sdin(audio_sdin)
);

KeyboardDecoder key_de(
    .key_down(key_down),
    .last_change(last_change),
    .key_valid(been_ready),
    .PS2_DATA(PS2_DATA),
    .PS2_CLK(PS2_CLK),
    .rst(rst_processed),
    .clk(clk)
);

debounce m1(.clk(clk), .pb(rst), .pb_debounced(rst_));
onepulse m2(.clk(clk), .signal(rst_), .op(rst_processed));

display disp(
    .clk(clk),
    .display0(display0),
    .display1(display1),
    .display2(display2),
    .display3(display3),
    .display(DISPLAY),
    .digit(DIGIT)
);

//=============================================================
//  Function 區
//=============================================================
function [6:0] num_trans(input [4:0] number);
    case(number)
        0: num_trans = 7'b1000000;
        1: num_trans = 7'b1111001;
        2: num_trans = 7'b0100100;
        3: num_trans = 7'b0110000;
        4: num_trans = 7'b0011001;
        5: num_trans = 7'b0010010;
        6: num_trans = 7'b0000010;
        7: num_trans = 7'b1111000;
        8: num_trans = 7'b0000000;
        9: num_trans = 7'b0010000;
        10: num_trans = 7'b1111111;
        11: num_trans = 7'b0111111;
        default: num_trans = 7'b1111110;
    endcase
endfunction

function [6:0] alpha_trans(input [4:0] number);
    case(number)
        0: alpha_trans = 7'b1000110; // C
        1: alpha_trans = 7'b0100001; // D
        2: alpha_trans = 7'b0000110; // E
        3: alpha_trans = 7'b0001110; // F
        4: alpha_trans = 7'b1000010; // G
        5: alpha_trans = 7'b0001000; // A
        6: alpha_trans = 7'b0000011; // B
        default: alpha_trans = 7'b0111111;
    endcase
endfunction

endmodule