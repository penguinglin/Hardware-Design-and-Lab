module exam2_B(
    input clk, 
    input rst, 
    input en, 
    inout PS2_DATA, 
		inout PS2_CLK, 
    output [3:0] DIGIT, 
    output [6:0] DISPLAY,
    output wire [15:0] led
);
	// debounce, one pulse
		wire rst_d, rst_op, en_d, en_op;
		debounce d1(.pb(rst), .clk(clk), .pb_debounced(rst_d));
		one_pulse o1(.pb_debounced(rst_d), .clk(clk), .pb_one_pulse(rst_op));
		debounce d2(.pb(en), .clk(clk), .pb_debounced(en_d));
		one_pulse o2(.pb_debounced(en_d), .clk(clk), .pb_one_pulse(en_op));
	// kb parameter : A1010 B1011 C1100 D1101 E1110 F1111
		parameter [8:0] left_1 = 9'b0_0001_0110; //16
		parameter [8:0] left_2 = 9'b0_0001_1110; //1E
    parameter [8:0] left_3 = 9'b0_0010_0110; //26
		parameter [8:0]	left_4 = 9'b0_0010_0101; //25
		parameter [8:0] left_5 = 9'b0_0010_1110; //2E
		parameter [8:0] left_6 = 9'b0_0011_0110; //36
		parameter [8:0] left_7 = 9'b0_0011_1101; //3D
		parameter [8:0] left_8 = 9'b0_0011_1110; //3E 
		parameter [8:0] left_9 = 9'b0_0100_0110; //46
		parameter [8:0] left_0 = 9'b0_0100_0101; //45
		wire [511:0] key_down;
    wire [8:0] last_change;
    wire key_valid;
		KeyboardDecoder kb(
			.rst(rst_op),
    	.clk(clk),
    	.PS2_DATA(PS2_DATA),
    	.PS2_CLK(PS2_CLK),
    	.key_down(key_down),
    	.last_change(last_change),
    	.key_valid(key_valid)
		);
		// lock key!
		reg [8:0]locked_key;
		reg locked;
	// FSM state
		parameter [1:0]INIT = 2'd0;
		parameter [1:0]SET = 2'd1;
		parameter [1:0]GUESS = 2'd2;
		parameter [1:0]CHECK = 2'd3;
		reg [1:0]state, next_state;
		always@(posedge clk or posedge rst_op)begin
			if(rst_op) state <= INIT;
			else state <= next_state;
		end
	// seven segment && led
		wire [15:0] nums;
		reg [15:0] temp_num_p;
		reg [15:0] temp_num_g;
		reg [15:0] temp_num;
		reg [15:0] temp_led; 
		assign led = temp_led;
		assign nums = (state == INIT) ? {4'd10, 4'd10, 4'd10, 4'd10} : (state == SET) ? temp_num_p : (state == GUESS) ? temp_num_g : temp_num;		
		SevenSegment S(.display(DISPLAY), .digit(DIGIT), .nums(nums), .rst(rst_op), .clk(clk));
		reg special_enter;
		wire en_set   = en_op & (state == SET);
		wire en_guess = en_op & (state == GUESS);
		reg [15:0]password,guess_password;
	// led & nums & transition state
		reg [1:0]now_input;
		wire flash;
		wire done;
		reg count_en;
		clock_divider_25 c(.clk(clk), .rst(rst_op), .state(state), .en_count(count_en), .done(done), .flash(flash));
		wire correct = (password == guess_password)? 1:0;
		integer  i;

		reg [3:0] key_value;
		always @(*) begin
				case (last_change)
						left_0: key_value = 4'd0;
						left_1: key_value = 4'd1;
						left_2: key_value = 4'd2;
						left_3: key_value = 4'd3;
						left_4: key_value = 4'd4;
						left_5: key_value = 4'd5;
						left_6: key_value = 4'd6;
						left_7: key_value = 4'd7;
						left_8: key_value = 4'd8;
						left_9: key_value = 4'd9;
						default: key_value = 4'd15;  
				endcase
		end
		
	// state reg
		always @(posedge clk or posedge rst_op) begin //remember
			if(rst_op) begin
				password <= 0;
				guess_password <= 0;
				temp_num_p <= 0;
				temp_num_g <= 0;
				temp_led <= {4'hF, 12'd0};
				special_enter <= 0;
			end else begin
				case (state)
					INIT:begin
						password <= 0;
						guess_password <= 0;
						temp_num_p <= 0;
						temp_num_g <= 0;
						temp_led <=  {4'hF, 12'd0};
						special_enter <= 0;
						count_en <= 0;
					end
					SET:begin
						temp_led <= {4'd0, 4'hF, 8'd0};
						// key input shift
						if (key_valid) begin
								if(!locked && key_down[last_change] && key_value != 4'd15) begin
									temp_num_p <= {temp_num_p[11:0], key_value};
									locked <= 1;
									locked_key <= last_change;	
								end else if (locked && key_down[locked_key] == 0) locked <= 0;
						end
						if (en_set) begin
								password <= temp_num_p;
						end
						special_enter <= 0;
						count_en <= 0;
					end
					GUESS:begin
						count_en <= 0;
						temp_led <= {8'd0, 4'hF, 4'd0};
						// press key
						if (key_valid)begin
							// check if there is another key still not release
							if(!locked && key_down[last_change] && key_value != 4'd15)begin
								// if no : update input
              	temp_num_g <= {temp_num_g[11:0], key_value};
								// and lock the key
								locked <= 1;
								locked_key <= last_change;
							end else if (locked && key_down[locked_key]== 0) locked <= 0;
							end 
						if (en_guess)
              guess_password <= temp_num_g;
					end
					CHECK:begin
						count_en <= 1;
						temp_led <= {12'd0, 4'hF};
						if(correct) begin
							special_enter <= 0;
							temp_num_g <= 0;
						end else  special_enter <= 1;
					end
				endcase
			end
		end

		always @(*) begin
			next_state = state;
    	case (state)
					INIT:  next_state = en_op ? SET : INIT;
					SET:   next_state = en_set ? GUESS : SET;
					GUESS: next_state = en_guess ? CHECK : GUESS;
					CHECK: begin
						next_state = done ? (correct ? INIT : GUESS) : CHECK;
						// if correct : flash 1111, else flash 0000
						temp_num = (flash) ?  (correct ? 16'h1111 : 16'h0000) : 16'hFFFF;
					end
			endcase
		end
endmodule


// provided modules
module clock_divider #(parameter n=25) (clk, clk_div);
    input clk;
    output clk_div;

    reg [n-1:0] num = 0;
    wire [n-1:0] next_num;

    always @(posedge clk) begin
        num <= next_num;
    end

    assign next_num = num + 1;
    assign clk_div = num[n-1];
endmodule

module debounce (pb, clk, pb_debounced);
    input pb;
    input clk;
    output pb_debounced;

    reg [3:0] shift_reg;

    always @(posedge clk) begin
        shift_reg[3:1] <= shift_reg[2:0];
        shift_reg[0] <= pb;
    end

    assign pb_debounced = ((shift_reg == 4'b1111) ? 1'b1 : 1'b0);
endmodule

module one_pulse (pb_debounced, clk, pb_one_pulse);
    input pb_debounced;
    input clk;
    output pb_one_pulse;
    
    reg pb_one_pulse;
    reg pb_debounced_delay;

    always @(posedge clk) begin
        if(pb_debounced == 1'b1 && pb_debounced_delay == 1'b0) begin
            pb_one_pulse <= 1'b1;
        end else begin
            pb_one_pulse <= 1'b0;
        end            
        pb_debounced_delay <= pb_debounced;
    end
endmodule

module SevenSegment(
	output reg [6:0] display,
	output reg [3:0] digit, 
	input wire [15:0] nums, // four 4-bits BCD number
	input wire rst,
	input wire clk  // Input 100Mhz clock
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
    
    always @ (posedge clk_divider[15], posedge rst) begin
    	if (rst) begin
    		display_num <= 4'b0000;
    		digit <= 4'b1111;
    	end else begin
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
				9 : display = 7'b0010000;	//1001
				10 : display = 7'b0111111; //-
			default : display = 7'b1111111;
    	endcase
    end
endmodule

module KeyboardDecoder(
    input wire rst,
    input wire clk,
    inout wire PS2_DATA,
    inout wire PS2_CLK,
    output reg [511:0] key_down,
    output wire [8:0] last_change,
    output reg key_valid
	);
    
    parameter [1:0] INIT			= 2'b00;
    parameter [1:0] WAIT_FOR_SIGNAL = 2'b01;
    parameter [1:0] GET_SIGNAL_DOWN = 2'b10;
    parameter [1:0] WAIT_RELEASE    = 2'b11;
    
    parameter [7:0] IS_INIT			= 8'hAA;
    parameter [7:0] IS_EXTEND		= 8'hE0;
    parameter [7:0] IS_BREAK		= 8'hF0;
    
    reg [9:0] key;		// key = {been_extend, been_break, key_in}
    reg [1:0] state;
    reg been_ready, been_extend, been_break;
    
    wire [7:0] key_in;
    wire is_extend;
    wire is_break;
    wire valid;
    wire err;
    
    wire [511:0] key_decode = 1 << last_change;
    assign last_change = {key[9], key[7:0]};
    
    KeyboardCtrl inst (
		.key_in(key_in),
		.is_extend(is_extend),
		.is_break(is_break),
		.valid(valid),
		.err(err),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
	);
	
	one_pulse op (
		.pb_one_pulse(pulse_been_ready),
		.pb_debounced(been_ready),
		.clk(clk)
	);

    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		state <= INIT;
    		been_ready  <= 1'b0;
    		been_extend <= 1'b0;
    		been_break  <= 1'b0;
    		key <= 10'b0_0_0000_0000;
    	end else begin
    		state <= state;
			been_ready  <= been_ready;
			been_extend <= (is_extend) ? 1'b1 : been_extend;
			been_break  <= (is_break ) ? 1'b1 : been_break;
			key <= key;
    		case (state)
    			INIT : begin
    					if (key_in == IS_INIT) begin
    						state <= WAIT_FOR_SIGNAL;
    						been_ready  <= 1'b0;
							been_extend <= 1'b0;
							been_break  <= 1'b0;
							key <= 10'b0_0_0000_0000;
    					end else begin
    						state <= INIT;
    					end
    				end
    			WAIT_FOR_SIGNAL : begin
    					if (valid == 0) begin
    						state <= WAIT_FOR_SIGNAL;
    						been_ready <= 1'b0;
    					end else begin
    						state <= GET_SIGNAL_DOWN;
    					end
    				end
    			GET_SIGNAL_DOWN : begin
						state <= WAIT_RELEASE;
						key <= {been_extend, been_break, key_in};
						been_ready  <= 1'b1;
    				end
    			WAIT_RELEASE : begin
    					if (valid == 1) begin
    						state <= WAIT_RELEASE;
    					end else begin
    						state <= WAIT_FOR_SIGNAL;
    						been_extend <= 1'b0;
    						been_break  <= 1'b0;
    					end
    				end
    			default : begin
    					state <= INIT;
						been_ready  <= 1'b0;
						been_extend <= 1'b0;
						been_break  <= 1'b0;
						key <= 10'b0_0_0000_0000;
    				end
    		endcase
    	end
    end
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		key_valid <= 1'b0;
    		key_down <= 511'b0;
    	end else if (key_decode[last_change] && pulse_been_ready) begin
    		key_valid <= 1'b1;
    		if (key[8] == 0) begin
    			key_down <= key_down | key_decode;
    		end else begin
    			key_down <= key_down & (~key_decode);
    		end
    	end else begin
    		key_valid <= 1'b0;
			key_down <= key_down;
    	end
    end
endmodule

module count_half( 
	input wire clk, 
	input wire rst,
	input wire [1:0]state,
	input wire en_count,
	output reg [2:0]count,
	output reg flash 
	);

	reg [30:0]temp_count;
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			temp_count <= 31'd0;
			count <= 4'd0;
			flash <= 0;
		end else if(state == 2'b11 && en_count) begin
			if(temp_count < 50000000-1) begin
				temp_count <= temp_count +1;
			end else begin
				temp_count <= 31'd0;
				count <= count +1;
				flash <= ~flash;
			end
		end else begin
			temp_count <= 31'd0;
			count <= 4'd0;
			flash <= 0;
		end 
	end
endmodule

module clock_divider_25 (
    input wire clk, 
		input wire rst,
		input wire [1:0]state,
		input wire en_count,
		output reg done,
		output reg flash  // 0: nothing, 1: flash(light)
		);

    reg [24:0] num;
		reg [2:0]count;

    always @(posedge clk or posedge rst) begin
				if(rst) begin
					num <= 25'd0;
					count <= 3'd0;
					flash <= 0;
					done <= 0;
				end else if(state==2'd3 && en_count) begin
					if(num[24]) begin
						num <= 25'd0;
						count <= count +1;
						flash <= ~flash;
						if(count == 5) done <= 1;
					end else num <= num+1;
				end else begin
					num <= 25'd0;
					count <= 3'd0;
					flash <= 0;
					done <= 0;
				end
    end
endmodule