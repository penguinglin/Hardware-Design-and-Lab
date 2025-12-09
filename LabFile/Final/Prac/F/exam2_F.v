// 111062118 江佩???	
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
	// reg / wire
	reg [2:0]Input_amount;
	reg [6:0]Money;
		wire [6:0]Price = Input_amount * 15;
		wire [3:0]Money_ten,Money_one,Price_ten,Price_one;
		assign Money_one = Money % 10;
		assign Money_ten = (Money / 10) % 10;
		assign Price_one = Price % 10;
		assign Price_ten = (Price / 10) % 10;
	reg [6:0]Return_Money,Reture_Money_plusone;
		wire [3:0]Return_Money_one, Return_Money_ten;
		assign Return_Money_one = Return_Money % 10;
		assign Return_Money_ten = (Return_Money / 10) % 10;
		// assign Return_Money = Money - Price;
		// assign Reture_Money_plusone = Money - Price +1;		
	// one pulse, debounce
	 	wire rst_d, rst_op, en_d, en_op;
		debounce d1(.pb(rst), .clk(clk), .pb_debounced(rst_d));
		debounce d2(.pb(en), .clk(clk), .pb_debounced(en_d));
		one_pulse o1(.pb_debounced(rst_d), .clk(clk), .pb_one_pulse(rst_op));
		one_pulse o2(.pb_debounced(en_d), .clk(clk), .pb_one_pulse(en_op));
	// fsm
		parameter [1:0]AMOUNT = 2'd0;
		parameter [1:0]DEPOSIT = 2'd1;
		parameter [1:0]CHANGE = 2'd2;
		reg [1:0]state, next_state;
		always @(posedge clk or posedge rst_op)begin
			if(rst_op) state <= AMOUNT;
			else state <= next_state;
		end
		always @(*)begin
			next_state = state;
			case(state)
				AMOUNT: next_state = (en_op) ? DEPOSIT : AMOUNT;
				DEPOSIT : next_state = (Money >= Price) ? CHANGE : DEPOSIT;
				CHANGE : next_state = (Reture_Money_plusone == 0) ? AMOUNT : CHANGE;
			endcase  
		end
	// kb 
		wire [511:0] key_down;
    wire [8:0] last_change;
    wire key_valid;
		KeyboardDecoder kb(.clk(clk), .rst(rst_op), .PS2_CLK(PS2_CLK), .PS2_DATA(PS2_DATA), .key_down(key_down), .last_change(last_change), .key_valid(key_valid));
		reg [2:0] key_value;
		parameter [8:0]left_zero = 9'b0_0100_0101;
		parameter [8:0]left_one = 9'b0_0001_0110;
		parameter [8:0]left_two = 9'b0_0001_1110;
		parameter [8:0]left_three = 9'b0_0010_0110;
		parameter [8:0]left_five = 9'b0_0010_1110;
		parameter [8:0]space = 9'b0_0010_1001;
		always @(*)begin
			if(key_valid)begin
				case(last_change)
					left_zero : key_value = 3'd0;
					left_one : key_value = 3'd1;
					left_two : key_value = 3'd2;
					left_three : key_value = 3'd3;
					left_five : key_value = 3'd4;
					space : key_value = 3'd5;
				endcase
			end else key_value = 3'd6;
		end		
		reg control;
	// !IMPOETANT
	always @(posedge clk)begin
		if(rst_op) control <= 0;
		else begin
			control <= (key_down) ? 1 : 0;
		end
	end
		reg over;
		always @(posedge clk or posedge rst_op)begin
			if(rst_op)begin
				Input_amount <= 2'd1;
				Money <= 7'd0;
				over <= 0;
			end else begin
				case (state)
					AMOUNT : begin
						// input num 1 or 2 or 3
						if(key_valid) begin
							case(key_value)
								3'd1 : Input_amount <= 2'd1;
								3'd2 : Input_amount <= 2'd2;
								3'd3 : Input_amount <= 2'd3;
								// default : Input_amount <= 2'd1;
							endcase
						end 
						Money <= 7'd0;
						over <=0;
					end
					DEPOSIT : begin
						// input num 0(add 10) or 5(add 5)
						if(key_valid && ~control) begin
							case(key_value)
								3'd0 : Money <= Money + 10;
								3'd4 : Money <= Money + 5;
							endcase
						end
						over <= (Money > Price)  ? 1 : 0;
					end
				endcase
			end
		end
	// Seven Segment 
		reg [15:0]nums;
		SevenSegment s(.rst(rst_op), .clk(clk), .display(DISPLAY), .digit(DIGIT), .nums(nums));
		wire space_press = ((state == DEPOSIT) && key_down[space]) ? 1 : 0;
		always @(*)begin
			if(rst_op) nums = 16'd0;
			else begin
				case(state)
					AMOUNT : nums = {12'd0, Input_amount};
					DEPOSIT : nums = (space_press) ? {Price_ten, Price_one , Money_ten, Money_one} : {8'd0, Money_ten , Money_one};
					CHANGE : nums = (over) ? {8'd0, Return_Money_ten, Return_Money_one} : {16'd0};
				endcase
			end
		end
	// led display
		always @(*)begin
			if(rst_op) led = 16'd0;
			else begin
				case (state)
					AMOUNT: led = {4'hF, 12'd0};
					DEPOSIT: led = {4'd0, 4'hF, 8'd0};
					CHANGE : led = {8'd0, 4'hF, 4'd0};
				endcase
			end
		end
	// clk_25
		wire clk_div_25;
		clock_divider #(.n(25))(.clk(clk), .clk_div(clk_div_25));
		always @(posedge clk_div_25 or posedge rst_op)begin
			if(rst_op)begin
				Return_Money <= 7'd0;
				Reture_Money_plusone <= 7'd0;
			end else if (state == CHANGE) begin
				Return_Money <= (Reture_Money_plusone == 1) ? 7'd0 : Return_Money - 1;
				Reture_Money_plusone <= Reture_Money_plusone - 1 ;
			end else begin
				Return_Money <= 7'd5; 
				Reture_Money_plusone <= (over) ? 7'd1 : 7'd6;
			end
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

module couont_half(
	input wire rst,
	input wire clk,
	input wire [1:0]state,

	// output wire count,
	output reg flash
);
	reg [31:0]num;
	always @(posedge clk or posedge rst)begin
		if(rst) begin
			num <= 0;
			flash <= 0;
		end else if(state == 2'd1) begin
			if(num > 50000000-1) begin
				num <= 0;
				flash <= ~flash;
			end else num <= num +1;
		end
	end
endmodule