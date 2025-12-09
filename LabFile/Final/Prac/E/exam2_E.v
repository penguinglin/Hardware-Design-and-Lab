module exam2_B(
    input clk, 
    input rst, 
    input en, 
    inout PS2_DATA, 
		inout PS2_CLK, 
    output [3:0] DIGIT, 
    output [6:0] DISPLAY,
    output reg [15:0] led
);
    // add your design here
		// state fsm
			parameter [1:0]IDLE = 2'd0;
			parameter [1:0]NORMAL = 2'd1;
			parameter [1:0]CHANGE = 2'd2;
			reg [1:0]state, next_state;
		// one pulse , debounce
			wire rst_d,rst_op, en_d, en_op;
			debounce d1(.pb(rst), .clk(clk), .pb_debounced(rst_d));
			debounce d2(.pb(en), .clk(clk), .pb_debounced(en_d));
			one_pulse o1(.pb_debounced(rst_d), .clk(clk), .pb_one_pulse(rst_op));
			one_pulse o2(.pb_debounced(en_d), .clk(clk), .pb_one_pulse(en_op));
			wire en_normal = (state == NORMAL && en_op )?1:0;
			wire en_change = (state == CHANGE && en_op )?1:0;
		//kb
			wire [511:0]key_down;
			wire [8:0]last_change;
			wire key_valid;
			KeyboardDecoder kb(
				.rst(rst_op), .clk(clk), .PS2_CLK(PS2_CLK), .PS2_DATA(PS2_DATA), .key_down(key_down), .last_change(last_change), .key_valid(key_valid));
			reg [1:0]key_value; // easy way to detected the input of keyboard
			parameter [8:0]key_1 = 9'b0_0001_0110;
			parameter [8:0]key_2 = 9'b0_0001_1110;
			always@(*)begin
				if(key_valid) begin
					case(last_change)
						key_1: key_value = 2'd0;
						key_2: key_value = 2'd1;
						default : key_value = 2'd3;
					endcase
				end else key_value = 2'd3;
			end
			reg locked;
			reg [8:0]locked_key;
			reg speed_up;
			reg speed_down;
			always @(posedge clk or posedge rst_op)begin
				if(rst_op)begin
					speed_down <= 0;
					speed_up <= 0;
					locked_key <= 0;
					locked <= 0;
				end else begin
					case(state)
						IDLE:begin
							speed_down <= 0;
							speed_up <= 0;
							locked_key <= 0;
							locked <= 0;
						end
						NORMAL: begin
							// before enter another key, speed_up / down hold
							if(key_valid && key_value!= 2'd3)begin
								if(last_change == key_1) begin
									speed_down <= 1;
									speed_up <= 0;
								end else if (last_change ==  key_2) begin
									speed_down <= 0;
									speed_up <= 1;
								end
							end
							if(en_normal)begin
								speed_down <= 0;
								speed_up <= 0;
								locked_key <= 0;
								locked <= 0;
							end
						end
						CHANGE : begin
							if(key_valid && key_value!= 2'd3)begin
								if(!locked && key_down[last_change])begin
									if(last_change == key_1)begin
										speed_down <= 1;
										speed_up <= 0;
									end else if (last_change ==  key_2) begin
										speed_down <=0;
										speed_up <= 1;
									end
									locked <= 1;
									locked_key <= last_change;
								end else if(locked && key_down[locked_key]== 0)begin
										locked<=0;
										speed_up<=0;
										speed_down<=0;
								end
							end
						end
					endcase
				end
			end
		// seven segment
			wire [15:0]nums;
			SevenSegment s(.clk(clk), .rst(rst_op), .digit(DIGIT), .display(DISPLAY), .nums(nums));
		// FSM
			always@(posedge clk or posedge rst_op)begin
				if(rst_op) state <= IDLE; 
				else state <= next_state;
			end
			always@(*)begin
				next_state = state;
				case (state)
					IDLE: next_state = (en_op) ? NORMAL : IDLE;
					NORMAL: next_state = (en_normal) ? CHANGE : NORMAL;
					CHANGE: next_state = (en_change) ? IDLE : CHANGE;
				endcase
			end
		// led display // DONE
			always @(*) begin
				case (state)
					IDLE: led = {4'hF, 12'd0};
					NORMAL: led = {4'd0,4'hF,8'd0};
					CHANGE: led = {8'd0,4'hF,4'd0};
					default : led = {16'd0};
				endcase
			end
		// count display
			wire [3:0]msec;
			wire [3:0]one;
			wire [3:0]ten;
			wire second;
			count_half cf(.clk(clk), .rst(rst_op),.state(state), .speed_up(speed_up), .speed_down(speed_down), .change(en_normal),.count_msec(msec), .count_sec_one(one), .count_sec_ten(ten), .done(second));
			assign nums =  {3'd0,second, ten, one, msec};
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
		input wire speed_up,
		input wire speed_down,
		input wire change,

		// output
		output reg [3:0]count_msec, 
		output reg [3:0]count_sec_one,
		output reg [3:0]count_sec_ten,
		output reg done
	);
		wire clk_div_fast;
		clock_divider #(.n(21)) ck(.clk(clk), .clk_div(clk_div_fast));

		// count update 
		reg [6:0]count_update; // 64 update: slow, 4 update: normal
		reg end_count;

		reg change_ctrl, speed_down_ctrl, speed_up_ctrl;
		always @(posedge clk or posedge rst)begin
			if(rst) begin
				change_ctrl <= 0;
				speed_down_ctrl<= 0;
				speed_up_ctrl <= 0;
			end else if (state != 2'd0)begin
				if(clk_div_fast) begin
					change_ctrl <= 0;
					speed_down_ctrl <= 0;
					speed_up_ctrl <= 0;
				end else begin
					if(speed_down) begin
						speed_down_ctrl <= 1;
						speed_up_ctrl <= 0;
					end
					if(speed_up) begin 
						speed_up_ctrl <= 1;
						speed_down_ctrl <= 0;
					end
					if(change) change_ctrl <= 1;
				end
			end
		end


    

		always@(posedge clk_div_fast or posedge rst) begin
			if(rst) begin
				count_msec <= 0;
				count_sec_one <= 0;
				count_sec_ten <= 0;
				done <= 0;
				count_update <= 0;
				end_count <= 0;

			end else begin
				case (state)
					2'd0: begin
						count_msec <= 0;
						count_sec_one <= 0;
						count_sec_ten <= 0;
						done <= 0;
						count_update <= 0;
						end_count <= 0;
					end
					2'd1, 2'd2: begin // press to change and do not change back
						if(!end_count) begin
							if(!speed_down_ctrl && !speed_up_ctrl)begin
								// count in normal: update 4 a time
								if(count_update >= 7'd16) begin
									count_update <= 0;
									if(count_msec == 4'd9)begin
										count_msec <= 4'd0;
										if(count_sec_one == 4'd9)begin
											count_sec_one <= 4'd0;
											if(count_sec_ten == 4'd5) begin
												count_sec_ten <= 4'd0;
												done <= 1;
												end_count <= 1;
											end else count_sec_ten <= count_sec_ten +1 ;
										end else count_sec_one <= count_sec_one +1 ;
									end else count_msec <= count_msec +1;
								end else begin
									count_update <= count_update +1 ;
								end


							end else if (speed_up_ctrl) begin
								// done need to count update
									if(count_msec == 4'd9)begin
										count_msec <= 4'd0;
										if(count_sec_one == 4'd9)begin
											count_sec_one <= 4'd0;
											
											if(count_sec_ten == 4'd5) begin
												count_sec_ten <= 4'd0;
												done <= 1;
												end_count <= 1;
											end else count_sec_ten <= count_sec_ten +1 ;
										end else count_sec_one <= count_sec_one +1 ;
									end else count_msec <= count_msec +1;	


							end else if (speed_down_ctrl) begin
								if(count_update >= 7'd64) begin
									count_update <= 0;
									if(count_msec == 4'd9)begin
										count_msec <= 4'd0;
										if(count_sec_one == 4'd9)begin
											count_sec_one <= 4'd0;
											if(count_sec_ten == 4'd5) begin
												count_sec_ten <= 4'd0;
												done <= 1;
												end_count <= 1;
											end else count_sec_ten <= count_sec_ten +1 ;
										end else count_sec_one <= count_sec_one +1 ;
									end else count_msec <= count_msec +1;
								end else begin
									count_update <= count_update +1 ;
								end
							end
						end


						if(change_ctrl)begin
							count_msec <= 0;
							count_sec_one <= 0;
							count_sec_ten <= 0;
							done <= 0;
							count_update <= 0;
							end_count <= 0;
						end
					end
				endcase
			end
		end
endmodule