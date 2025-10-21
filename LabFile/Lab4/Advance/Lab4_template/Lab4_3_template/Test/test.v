`define silence   32'd50000000
`define c4  32'd262   // C4


module lab4_3(
    input wire clk,
    input wire rst,
    inout wire PS2_DATA,   // Keyboard I/O
    inout wire PS2_CLK,    // Keyboard I/O
    output reg [2:0] volume,       // LED: [15:13] volume
    output reg [8:0] LED,         //LED: [8:0] for LFSR state
    output wire audio_mclk, // master clock
    output wire audio_lrck, // left-right clock
    output wire audio_sck,  // serial clock
    output wire audio_sdin, // serial audio data input
    output wire [6:0] DISPLAY,
    output wire [3:0] DIGIT
    );      
    
    // Internal Signal
    wire [15:0] audio_in_left, audio_in_right; // Left and Right channel audio data input
    reg [31:0] freqL, freqR;           // Raw frequency
    wire [31:0] freq_inL, freq_inR;    // Processed frequency, adapted to the clock rate of Basys3

    //keyboard
    reg [3:0] key_num;
	reg [9:0] last_key;
    reg have_key_down;
    wire shift_down;
	wire [511:0] key_down;
	wire [8:0] last_change;
	wire been_ready;

    parameter [8:0] KEY_CODES [0:19] = {
		9'b0_0100_0101,	// 0 => 45
		9'b0_0001_0110,	// 1 => 16
		9'b0_0001_1110,	// 2 => 1E
		9'b0_0010_0110,	// 3 => 26
		9'b0_0010_0101,	// 4 => 25
		9'b0_0010_1110,	// 5 => 2E
		9'b0_0011_0110,	// 6 => 36
		9'b0_0011_1101,	// 7 => 3D
		9'b0_0011_1110,	// 8 => 3E
		9'b0_0100_0110,	// 9 => 46
		
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
    //state
    localparam INITIAL = 2'b00;
    localparam GUESS = 2'b01;
    localparam FINAL = 2'b10;
    reg[2:0] state;
    reg [2:0] nxt_state;
    reg [2:0] last_state;
    //volume
    reg [2:0] sound_lev;
    //rst button
    wire rst_;
    wire rst_processed;
    //sound
    wire [4:0] note_number;
    //display
    reg [6:0] display0;
    reg [6:0] display1;
    reg [6:0] display2;
    reg [6:0] display3;
    //guess sate
    reg [2:0] input_state;
    reg [4:0] input_alpha;
    reg [4:0] input_number;
    wire [5:0] answer = (input_number == 5) ? input_alpha + 7 : input_alpha;
    //final state
    reg result;
    //--volume control---------------------------------------------------------------------------------------------
    always@(*)begin
        case(sound_lev)
        1:begin
            volume = 3'b100;
        end
        2:begin
            volume = 3'b110;
        end
        3:begin
            volume = 3'b111;
        end
        endcase
    end
    always@(posedge clk)begin
        if(state == INITIAL)begin
            sound_lev <= 2;
        end
        else begin
            if(been_ready && key_down[last_change] == 1'b1 && key_down[8'h1D] == 1 && have_key_down == 0)begin//��w
                case(sound_lev)
                    1:sound_lev <= 2;
                    2:sound_lev <= 3;
                    3:sound_lev <= 3;
                endcase
            end
            else if(been_ready && key_down[last_change] == 1'b1 && key_down[8'h1B] == 1 && have_key_down == 0)begin//��s
                case(sound_lev)
                    1:sound_lev <= 1;
                    2:sound_lev <= 1;
                    3:sound_lev <= 2;
                endcase
            end
        end
    end
//----LFSR->Hz------------------------------------------------------------------------------------------------------
    assign note_number = LED % 14;
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
//----state control---------------------------------------------------------------------------------------------------------
    always@(posedge clk,posedge rst_processed)begin
        if(rst_processed)begin
            state <= INITIAL;
            last_state <= INITIAL;
        end
        else begin
            state <= nxt_state;
            last_state <= state;
        end
    end

    always@(*)begin
        nxt_state = state;
        case(state)
        INITIAL:begin
            nxt_state <= GUESS;
        end
        GUESS:begin
            if(been_ready && key_down[last_change] == 1'b1 && key_down[8'h5A] == 1 && have_key_down == 0)begin
                nxt_state <= FINAL;
            end 
            else if(been_ready && key_down[last_change] == 1'b1 && key_down[8'h2D] == 1 && have_key_down == 0)begin//��R
                nxt_state <= INITIAL;
            end
            else nxt_state <= GUESS;
        end
        FINAL:begin
            if(been_ready && key_down[last_change] == 1'b1 && key_down[8'h5A] == 1 && have_key_down == 0)begin//��enter
                nxt_state <= GUESS;
            end
            else if(been_ready && key_down[last_change] == 1'b1 && key_down[8'h2D] == 1 && have_key_down == 0)begin//��R
                nxt_state <= INITIAL;
            end
            else nxt_state <= FINAL;
        end
        endcase
    end
//----result control------------------------------------------------------------------------------------------------------------
    always@(posedge clk)begin
        if(state == GUESS && been_ready && key_down[last_change] == 1'b1 && key_down[8'h5A] == 1 && have_key_down == 0)begin
            result <= (answer == note_number && input_number != 11 && input_alpha != 11);
        end
        else if(state != FINAL) result <= 0;
    end

//----main----------------------------------------------------------------------------------------------------------------------
    always@(posedge clk,posedge rst_processed)begin
        if(rst_processed)begin
            input_alpha <= 11;
            input_number <= 11;
            input_state <= 0;
        end
        else if(state == INITIAL)begin
            input_alpha <= 11;
            input_number <= 11;
            input_state <= 0;
        end
        else if(state == GUESS)begin
            if(last_state == FINAL && state == GUESS)begin//�M�ŤW��guess
                input_number <= 11;
                input_alpha <= 11;
                input_state <= 0;
            end
            else if(been_ready && key_down[last_change] == 1'b1 && have_key_down == 0 && key_down[8'h66])begin//��Jbackspace
                if(input_state == 2)begin
                    input_state <= 1;
                    input_number <= 11;
                end
                else if(input_state == 1)begin
                    input_state <= 0;
                    input_alpha <= 11;
                end  
            end
            else if(input_state == 0 && been_ready && key_down[last_change] == 1'b1 && have_key_down == 0)begin//��J�^��r
                input_state <= (key_down[8'h21] || key_down[8'h23] || key_down[8'h24] || key_down[8'h2B] || key_down[8'h34] || key_down[8'h1C] || key_down[8'h32]) ? !input_state : input_state;
                if(key_down[8'h21]) input_alpha <= 0;
                else if(key_down[8'h23]) input_alpha <= 1;
                else if(key_down[8'h24]) input_alpha <= 2;
                else if(key_down[8'h2B]) input_alpha <= 3;
                else if(key_down[8'h34]) input_alpha <= 4;
                else if(key_down[8'h1C]) input_alpha <= 5;
                else if(key_down[8'h32]) input_alpha <= 6;
            end
            else if(input_state == 1 && been_ready && key_down[last_change] == 1'b1 && have_key_down == 0)begin//��J�Ʀr
                input_state <= (key_down[8'h25] || key_down[8'h6B] || key_down[8'h2E] || key_down[8'h73]) ? 2 : 1;
                if(key_down[8'h25] || key_down[8'h6B]) input_number <= 4;
                else if(key_down[8'h2E] || key_down[8'h73]) input_number <= 5;
            end
        end
    end

    always@(*)begin
        if(state == INITIAL)begin
            display0 = num_trans(11);
            display1 = num_trans(11);
            display2 = num_trans(11);
            display3 = num_trans(11);
        end
        else if(state == GUESS)begin
            display0 = num_trans(11);
            display1 = num_trans(11);
            display2 = alpha_trans(input_alpha);
            display3 = num_trans(input_number);
        end
        else if(state == FINAL)begin
            if(result)begin
                display0 = 7'b1000010;//g
                display1 = 7'b1000000;//o
                display2 = 7'b1000000;//o
                display3 = 7'b0100001;//d
            end
            else begin
                display0 = 7'b1000111;//l
                display1 = 7'b1000000;//o
                display2 = 7'b0010010;//s
                display3 = 7'b0000110;//e
            end
        end
    end
//-keyboard control---------------------------------------------------------------------------------------------------------------------
    //�@���u�঳�@�ӫ���B�z
	always@(posedge clk, posedge rst_processed)begin
		if(rst_processed)have_key_down <= 0;
		else have_key_down <= (key_down == 0) ? 0 : 1 ;
	end

//otherfunction----------------------------------------------------------------------------------------------------------------------
    //LFSR update
    always@(posedge clk)begin
        if(state == INITIAL)begin
            LED <= 9'b101011001;
        end
        else begin
            if(been_ready && key_down[last_change] == 1'b1 && key_down[8'h31] == 1 && have_key_down == 0)begin//��N
                LED[8] <= LED[0];
                LED[7] <= LED[8];
                LED[6] <= (LED[0] && !LED[7]) || (!LED[0] && LED[7]);
                LED[5] <= (LED[0] && !LED[6]) || (!LED[0] && LED[6]);
                LED[4] <= LED[5];
                LED[3] <= (LED[0] && !LED[4]) || (!LED[0] && LED[4]);
                LED[2] <= LED[3];
                LED[1] <= LED[2];
                LED[0] <= LED[1];
            end
        end
    end


    always @ (*) begin
		case (last_change)
			KEY_CODES[00] : key_num = 4'b0000;
			KEY_CODES[01] : key_num = 4'b0001;
			KEY_CODES[02] : key_num = 4'b0010;
			KEY_CODES[03] : key_num = 4'b0011;
			KEY_CODES[04] : key_num = 4'b0100;
			KEY_CODES[05] : key_num = 4'b0101;
			KEY_CODES[06] : key_num = 4'b0110;
			KEY_CODES[07] : key_num = 4'b0111;
			KEY_CODES[08] : key_num = 4'b1000;
			KEY_CODES[09] : key_num = 4'b1001;
			KEY_CODES[10] : key_num = 4'b0000;
			KEY_CODES[11] : key_num = 4'b0001;
			KEY_CODES[12] : key_num = 4'b0010;
			KEY_CODES[13] : key_num = 4'b0011;
			KEY_CODES[14] : key_num = 4'b0100;
			KEY_CODES[15] : key_num = 4'b0101;
			KEY_CODES[16] : key_num = 4'b0110;
			KEY_CODES[17] : key_num = 4'b0111;
			KEY_CODES[18] : key_num = 4'b1000;
			KEY_CODES[19] : key_num = 4'b1001;
			default		  : key_num = 4'b1111;
		endcase
	end


    display m3(
        .clk(clk),
        .display0(display0),
        .display1(display1),
        .display2(display2),
        .display3(display3),
        .display(DISPLAY),
        .digit(DIGIT)
    );

    // freq_outL, freq_outR
    // Note gen makes no sound, if freq_out = 50000000 / `silence = 1
    assign freq_inL = (state == GUESS) ? 50000000 / freqL : 50000000 / `silence;
    assign freq_inR = (state == GUESS) ? 50000000 / freqR : 50000000 / `silence;

    // Note generation
    // [in]  processed frequency
    // [out] audio wave signal (using square wave here)
    note_gen noteGen_00(
        .clk(clk), 
        .rst(rst), 
        .volume(sound_lev),
        .note_div_left(freq_inL), 
        .note_div_right(freq_inR), 
        .audio_left(audio_in_left),     // left sound audio
        .audio_right(audio_in_right)    // right sound audio
    );

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

    KeyboardDecoder key_de (
		.key_down(key_down),
		.last_change(last_change),
		.key_valid(been_ready),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst_processed),
		.clk(clk)
	);

    debounce m1(
        .clk(clk),
        .pb(rst),
        .pb_debounced(rst_)
    );
    onepulse m2(
        .clk(clk),
        .signal(rst_),
        .op(rst_processed)
    );

    function [6:0] num_trans;
        input [4:0] number;
        begin
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
            10: num_trans = 7'b1111111;//�L���
            11: num_trans = 7'b0111111;//���--
            default: num_trans = 7'b1111110;
            endcase
        end
    endfunction
    function [6:0] alpha_trans;
        input [4:0] number;
        begin
            case(number)
            0: alpha_trans = 7'b1000110;//C
            1: alpha_trans = 7'b0100001;//D
            2: alpha_trans = 7'b0000110;//E
            3: alpha_trans = 7'b0001110;//F
            4: alpha_trans = 7'b1000010;//G
            5: alpha_trans = 7'b0001000;//A
            6: alpha_trans = 7'b0000011;//B
            default: alpha_trans = 7'b0111111;
            endcase
        end
    endfunction
endmodule