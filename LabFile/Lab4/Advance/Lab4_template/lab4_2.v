module lab4_2 (
  input wire clk,
  input wire rst,
  input wire set, 
  inout wire PS2_DATA,
  inout wire PS2_CLK,
  output wire [15:0] LED,
  output wire [3:0] digit,
  output wire [6:0] display
);

  // -----------------------------
  // Clock divider
  // -----------------------------
  wire clk_1s;
  wire done_3s, done_5s;
  reg [2:0] state, next_state;
  
  GameTimer timer(
      .clk(clk),
      .rst(rst),
      .clk_1s(clk_1s),
      .state(state),
      .done_3s(done_3s),
      .done_5s(done_5s)
  );
  // display override buffer
  reg [15:0] display_mux_num;
  reg display_override; // 1 -> show display_mux_num, 0 -> show num_wire  
  // LED override buffer
  reg [15:0] led_mux_num;
  reg led_override; // 1 -> show led_mux_num, 0 -> show led_wire
  


  // -----------------------------
  // FSM State Definition
  // -----------------------------
  localparam S_INIT        = 3'b000;
  localparam S_SET         = 3'b001;
  localparam S_GUESS       = 3'b010;
  localparam S_RESULT      = 3'b011;
  localparam S_FINAL       = 3'b100;
  reg set_flag, guest_flag;
  wire kb_init_request;
  assign kb_init_request = (state == S_SET && set_flag) || (state == S_GUESS && guest_flag);


  // -----------------------------
  // Game data registers
  // -----------------------------
  reg [15:0] secret_num;  
  reg [15:0] guess_num; 
  reg [1:0] sel_pos;   
  wire [3:0] A_wire, B_wire;     
  reg [3:0] A, B;

  // -----------------------------
  // Keyboard Control wires
  // -----------------------------
  wire [15:0] num_wire;
  wire submit;
  wire [15:0] led_wire;

  // -----------------------------
  // Instantiate KeyboardControl
  // -----------------------------
  KeyboardControl kb(
      .clk(clk),
      .rst(rst),
      .PS2_DATA(PS2_DATA),
      .PS2_CLK(PS2_CLK),
      .state_init_request(kb_init_request), 
      .num(num_wire),
      .LED(led_wire),
      .submit(submit),
      .led_en((state==S_SET)||(state==S_GUESS)),
      .segment_en((state==S_SET)||(state==S_GUESS))
  );
  reg submit_d; // Submit signal delayed by one clock cycle
  wire submit_pulse; // Single-cycle pulse on submit rising edge
  assign submit_pulse = submit & ~submit_d;

  // Capture the previous state of submit (Sequential)
  always @(posedge clk or posedge rst) begin
      if (rst)
          submit_d <= 1'b0;
      else
          submit_d <= submit;
  end
  

  // -----------------------------
  // Instantiate SevenSegment
  // -----------------------------
  // decide which num goes to display
  wire [15:0] display_source_num;
  assign display_source_num = display_override ? display_mux_num : num_wire;
  assign LED = led_override ? led_mux_num : led_wire;

  // SevenSegment instance: feed display_source_num
  SevenSegment seven_seg(
      .clk(clk),
      .rst(rst),
      .nums(display_source_num), 
      .digit(digit),
      .display(display)
  );


  // -----------------------------
  // FSM Sequential
  // -----------------------------
  always @(posedge clk or posedge rst) begin
      if (rst)
          state <= S_INIT;
      else
          state <= next_state;
  end

  // -----------------------------
  // Compare Unit
  // -----------------------------
  wire is_correct;
  CompareUnit cmp(
      .secret(secret_num),
      .guess(guess_num),
      .A(A_wire),
      .B(B_wire),
      .is_correct(is_correct)
  );

  // -----------------------------
  // FSM Combinational: Transition
  // -----------------------------
  always @(*) begin
    next_state = state;
    case(state)
        S_INIT:   if(set) next_state = S_SET;
        S_SET:    if(submit_pulse) next_state = S_GUESS;
        S_GUESS:  if(submit_pulse) next_state = is_correct ? S_FINAL : S_RESULT;
        S_RESULT: if (done_3s) next_state = S_GUESS;
        S_FINAL:  if (done_5s) next_state = S_INIT;
    endcase
  end

  always @(posedge clk or posedge rst) begin
    if(rst) begin
        A <= 0;
        B <= 0;
    end else begin
        A <= A_wire;
        B <= B_wire;
    end
  end

  // -----------------------------
  // FSM Sequential: Output & Behavior
  // -----------------------------
  always @(posedge clk or posedge rst) begin
      if(rst) begin
          sel_pos <= 0;
          display_override <= 0;
          display_mux_num <= 16'hCCCC;
          set_flag <= 1;
          guest_flag <= 1;
          secret_num <= 16'b0;
          guess_num <= 16'b0;
          led_mux_num <= 16'b0;
          led_override <= 0;
      end else begin
          case(state)
              S_INIT: begin
                  display_mux_num <= 16'hCCCC;
                  display_override <= 1'b1;
                  set_flag <= 1;
                  guest_flag <= 1;
                  secret_num <= 16'b0;
                  guess_num <= 16'b0;
                  led_mux_num <= 16'b0;
                  led_override <= 1;
              end
              S_SET, S_GUESS: begin
                  display_override <= 1'b0;
                  led_override <= 1'b0;
                  if(set_flag && (state==S_SET)) begin
                      set_flag <= 0;
                      secret_num <= 16'b0;
                  end else if(set_flag == 0 && (state==S_SET)) begin
                    secret_num <= num_wire;
                  end

                  if(guest_flag && (state==S_GUESS)) begin
                      guest_flag <= 0;
                      guess_num <= 16'b0;
                  end else if(guest_flag ==0 && (state==S_GUESS)) begin
                    guess_num <= num_wire;
                  end
              end
              S_RESULT: begin
                  display_mux_num <= { A_wire, 4'd10, B_wire, 4'd11 };
                  display_override <= 1'b1;
                  guest_flag <= 1;
                  led_mux_num <= 16'b0; 
                  led_override <= 1'b1;
              end
              S_FINAL: begin
                  display_mux_num <= { 4'd4, 4'd10, 4'd0, 4'd11 };
                  led_mux_num <= clk_1s ? 16'h0000 : 16'hFFFF;
                  display_override <= 1'b1;
                  led_override <= 1'b1;
                  guest_flag <= 1;
                  set_flag <= 1;
              end
          endcase
      end
  end

endmodule

module CompareUnit(
    input wire [15:0] secret,
    input wire [15:0] guess,
    output reg [3:0] A,
    output reg [3:0] B,
    output wire is_correct
);

    wire [3:0] s0 = secret[3:0], s1 = secret[7:4], s2 = secret[11:8], s3 = secret[15:12];
    wire [3:0] g0 = guess[3:0], g1 = guess[7:4], g2 = guess[11:8], g3 = guess[15:12];

    reg [3:0] secret_used, guess_used;

    always @(*) begin
        A = 0;
        B = 0;
        secret_used = 4'b0;
        guess_used = 4'b0;

        if (s0==g0) begin A=A+1; secret_used[0]=1; guess_used[0]=1; end
        if (s1==g1) begin A=A+1; secret_used[1]=1; guess_used[1]=1; end
        if (s2==g2) begin A=A+1; secret_used[2]=1; guess_used[2]=1; end
        if (s3==g3) begin A=A+1; secret_used[3]=1; guess_used[3]=1; end

        if (!guess_used[0]) begin
            if ((g0==s1 && !secret_used[1]) || (g0==s2 && !secret_used[2]) || (g0==s3 && !secret_used[3])) B = B+1;
        end
        if (!guess_used[1]) begin
            if ((g1==s0 && !secret_used[0]) || (g1==s2 && !secret_used[2]) || (g1==s3 && !secret_used[3])) B = B+1;
        end
        if (!guess_used[2]) begin
            if ((g2==s0 && !secret_used[0]) || (g2==s1 && !secret_used[1]) || (g2==s3 && !secret_used[3])) B = B+1;
        end
        if (!guess_used[3]) begin
            if ((g3==s0 && !secret_used[0]) || (g3==s1 && !secret_used[1]) || (g3==s2 && !secret_used[2])) B = B+1;
        end
    end

    assign is_correct = (A==4);
endmodule

module GameTimer #(
    parameter CLK_FREQ = 100000000,    
    parameter S_RESULT = 3'b011,       
    parameter S_FINAL  = 3'b100
)(
    input  wire clk,
    input  wire rst,
    input  wire [2:0] state,             
    output wire clk_1s,
    output wire done_3s, 
    output wire done_5s               // for S_FINAL
);

    // === Counter for 1 second ===
    reg[28:0] counter_1s;
    reg [3:0]  sec_counter;   
    reg clk_1s_reg; 
    assign clk_1s = clk_1s_reg; 
    assign done_3s =  (sec_counter >= 3);
    assign done_5s =  (sec_counter >= 5);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_1s   <= 0;
            sec_counter  <= 0;
            clk_1s_reg   <= 0; 
        end else begin
            if (state == S_RESULT || state == S_FINAL) begin

                if (counter_1s < CLK_FREQ - 1) begin
                    counter_1s <= counter_1s + 1;
                end else begin
                    counter_1s <= 0;
                    clk_1s_reg <= ~clk_1s_reg; 
                    sec_counter <= sec_counter + 1;
                end

            end else begin
                counter_1s  <= 0;
                clk_1s_reg  <= 0;
                sec_counter <= 0;
            end
        end
    end
endmodule

module KeyboardControl(
    input wire clk,
    input wire rst,
    inout wire PS2_DATA,
    inout wire PS2_CLK,
    input wire state_init_request,
    input wire led_en,
    input wire segment_en,
    output wire [15:0] num,
    output reg [15:0] LED,
    output reg submit  // S鍵觸發
);
    // -----------------------------
    // Keyboard control signals
    // -----------------------------
    wire [511:0] key_down;
    wire [8:0] last_change;
    wire key_valid;
    reg [3:0] key_num;
    reg [1:0] sel_pos;
    reg [8:0] locked_key;
    reg locked;
    reg [3:0] BCD1, BCD2, BCD3, BCD4;
    
    // Key codes
    parameter [8:0] KEY_CODES [0:21] = {
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
			9'b0_0111_1101,  // right_9 => 7D

			9'b0_0010_1001, // space => 29
			9'b0_0001_1011   // S => 1B
    };
        // -----------------------------
        // Keyboard decoder
        // -----------------------------
    KeyboardDecoder key_de(
        .key_down(key_down),
        .last_change(last_change),
        .key_valid(key_valid),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(rst),
        .clk(clk)
    );

    // -----------------------------
    // Key code 轉 BCD
    // -----------------------------
    always @(*) begin
        case (last_change)
            KEY_CODES[0] : key_num = 4'b0000;
            KEY_CODES[1] : key_num = 4'b0001;
            KEY_CODES[2] : key_num = 4'b0010;
            KEY_CODES[3] : key_num = 4'b0011;
            KEY_CODES[4] : key_num = 4'b0100;
            KEY_CODES[5] : key_num = 4'b0101;
            KEY_CODES[6] : key_num = 4'b0110;
            KEY_CODES[7] : key_num = 4'b0111;
            KEY_CODES[8] : key_num = 4'b1000;
            KEY_CODES[9] : key_num = 4'b1001;
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
            KEY_CODES[20] : key_num = 4'b1110; // space
            KEY_CODES[21] : key_num = 4'b1111; // S
            default: key_num = 4'b1010;
        endcase
    end

    // -----------------------------
    // BCD update
    // -----------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            BCD1 <= 4'b0;
            BCD2 <= 4'b0;
            BCD3 <= 4'b0;
            BCD4 <= 4'b0;
            sel_pos <= 2'b00;
            submit <= 0;
            locked <= 0;
            locked_key <= 0;
        end else if (state_init_request) begin
            BCD1 <= 4'b0;
            BCD2 <= 4'b0;
            BCD3 <= 4'b0;
            BCD4 <= 4'b0;
            sel_pos <= 2'b00;
            submit <= 0; 
            locked <= 0;
            locked_key <= 0;
        end else if (key_valid && segment_en) begin
            submit <= 0;
            if (!locked) begin
                if (key_down[last_change]) begin
                    locked <= 1;
                    locked_key <= last_change;

                    if (key_num <= 4'd9) begin
                        case(sel_pos)
                            2'b00: BCD4 <= key_num;
                            2'b01: BCD3 <= key_num;
                            2'b10: BCD2 <= key_num;
                            2'b11: BCD1 <= key_num;
                        endcase
                    end else if (key_num == 4'b1110) begin
                        sel_pos <= sel_pos + 1;
                        case(sel_pos + 1)
                            2'b00: BCD4 <= 4'd0;
                            2'b01: BCD3 <= 4'd0;
                            2'b10: BCD2 <= 4'd0;
                            2'b11: BCD1 <= 4'd0;
                        endcase
                    end else if (key_num == 4'b1111) begin
                        submit <= 1;
                    end
                end
            end else begin
                if (!key_down[locked_key]) begin
                    locked <= 0;
                end
            end
        end
    end

    // -----------------------------
    // LED 
    // -----------------------------
    always @(*) begin
        if (led_en) begin
            case(sel_pos)
                2'b00: LED = 16'b1111_0000_0000_0000;
                2'b01: LED = 16'b0000_1111_0000_0000;
                2'b10: LED = 16'b0000_0000_1111_0000;
                2'b11: LED = 16'b0000_0000_0000_1111;
                default: LED = 16'b0;
            endcase
        end else begin
            LED = 16'b0;
        end
    end

    assign num = {BCD4, BCD3, BCD2, BCD1};
endmodule

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
    		clk_divider <= 15'b0;
    	end else begin
    		clk_divider <= clk_divider + 15'b1;
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
    		0 : display = 7'b1000000;	//0000
				1 : display = 7'b1111001;   //0001                                                
				2 : display = 7'b0100100;   //0010                                                
				3 : display = 7'b0110000;   //0011                                             
				4 : display = 7'b0011001;   //0100                                               
				5 : display = 7'b0010010;   //0101                                               
				6 : display = 7'b0000010;   //0110
				7 : display = 7'b1111000;   //0111
				8 : display = 7'b0000000;   //1000
				9 : display = 7'b0010000;	 //1001
				10: display = 7'b0001000; // A
				11: display = 7'b0000011; // b
				12: display = 7'b0111111; // -

			default : display = 7'b1111111; //nothing
    	endcase
    end
endmodule
