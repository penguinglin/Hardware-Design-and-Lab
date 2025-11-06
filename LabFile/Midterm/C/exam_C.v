`timescale 1ns / 1ps
module Number_Generator(
    input wire clk,
    input wire rst,
    input wire [6:0] seed,
	output wire [6:0] out
	);
	reg [6:0] random;
    wire feedback;

	assign feedback = random[6] ^ random[5];
	assign out = (random < 7'd100) ? random : (random - 7'd64);

    always @(posedge clk) begin
        if (rst)
            random <= seed;
        else begin
            random <= {random[5:0], feedback};
        end
    end
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
    		4'd0: display <= 7'b1000000;
            4'd1: display <= 7'b1111001;
            4'd2: display <= 7'b0100100;
            4'd3: display <= 7'b0110000;
            4'd4: display <= 7'b0011001;
            4'd5: display <= 7'b0010010;
            4'd6: display <= 7'b0000010;
            4'd7: display <= 7'b1111000;
            4'd8: display <= 7'b0000000;
            4'd9: display <= 7'b0010000;
			4'd10: display <= 7'b0111111; // -
			4'd11: display <= 7'b1000001; // U
			4'd12: display <= 7'b1001000; // n
			4'd13: display <= 7'b1000111; //L
			4'd14: display <= 7'b0100011; // little o
			4'd15: display <= 7'b0000110; //E
            /*TODO:*/
			default : display = 7'b1111111;
    	endcase
    end
    
endmodule

module exam_C(
	output wire [6:0] display,
	output wire [3:0] digit,
	output reg [15:0] LED,	
	inout wire PS2_DATA,
	inout wire PS2_CLK,
	input wire rst,
	input wire clk,
    input wire restart,
	input wire en,
	input wire [15:0] SW
	);

	// state 
	parameter IDLE = 3'd0;
    parameter GAME = 3'd1;
    parameter CHECK = 3'd2;
    parameter FINAL = 3'd3;
	reg [1:0] state;
    reg [1:0] next_state;
	// Keyboard 
		reg [511:0]skey_down;
		wire [8:0]slast_change;
		reg skey_valid;
		KeyboardDecoder kb( 
			.rst(rst), 
			.clk(clk), 
			.PS2_CLK(PS2_CLK), 
			.PS2_DATA(PS2_DATA), 
			.key_down(skey_down), 
			.key_valid(skey_valid), 
			.last_change(slast_change) 
		);

	// Debounce and onepulse
	/*
		rst => rst_op
		restart => restart_op
		en => en_op
	*/
		wire rst_db, rst_op;
		wire restart_db, restart_op;
		wire en_db, en_op;
		debounce rstdb( .pb_debounce(rst_db), .pb(rst), .clk(clk) );
		onepulse rstop( .pb_in(rst_db), .pb_out(rst_op), .clk(clk) );
		debounce restartdb( .pb_debounce(restart_db), .pb(restart), .clk(clk) );
		onepulse restartop( .pb_in(restart_db), .pb_out(restart_op), .clk(clk) );
		debounce endb( .pb_debounce(en_db), .pb(en), .clk(clk) );
		debounce enop( .pb_in(en_db), .pb_out(en_op), .clk(clk) );
	// enter_press
	wire enter_press;
	reg [6:0] seed = 7'd33;
	wire [6:0] random;
	reg [15:0] value;

	// new clk
	wire clk_div26;
	reg [5:0]current_time;
	wire [5:0]current_time_ten;
	wire  [5:0]current_time_one;
	assign current_time_one = current_time %10;
	assign current_time_ten = current_time / 10;
	clock_divider (.clk(clk), .clk_div(clk_div26));
	always @(posedge clk_div26) begin
		if(state == GAME) begin
			current_time <= current_time - 1;
			case(current_time_one)
				5'd0: value[11:8] <= 4'd0;
				5'd1: value[11:8] <= 4'd1;
				5'd2: value[11:8] <= 4'd2;
				5'd3: value[11:8] <= 4'd3;
				5'd4: value[11:8] <= 4'd4;
				5'd5: value[11:8] <= 4'd5;
				5'd6: value[11:8] <= 4'd6;
				5'd7: value[11:8] <= 4'd7;
				5'd8: value[11:8] <= 4'd8;
				5'd9: value[11:8] <= 4'd9;
			endcase
			case(current_time_ten)
				5'd0: value[15:12] <= 4'd0;
				5'd1: value[15:12] <= 4'd1;
				5'd2: value[15:12] <= 4'd2;
				5'd3: value[15:12] <= 4'd3;
				5'd4: value[15:12] <= 4'd4;
				5'd5: value[15:12] <= 4'd5;
				5'd6: value[15:12] <= 4'd6;
				5'd7: value[15:12] <= 4'd7;
				5'd8: value[15:12] <= 4'd8;
				5'd9: value[15:12] <= 4'd9;
			endcase
		end 
	end
	reg [1:0]count_2;
	always @(posedge clk_div26) begin
		if(state == CHECK) begin
			count_2 <= count_2+1;
		end else count_2 <=2'd0;
	end

	SevenSegment seven_seg (
		.display(display),
		.digit(digit),
		.nums(value),
		.rst(rst),
		.clk(clk)
	);

	Number_Generator num_gen (
		.clk(clk),
		.rst(rst),
		.seed(seed),
		.out(random)
	);

	// LED
	wire [2:0] player_score;
	reg [2:0] store_score;
	wire [6:0] player_ans;
	reg [6:0] store_ans;
	wire [15:0]tmp_led;
	assign player_score = {store_score[0], store_score[1], store_score[2]}; // reverse of the score
	assign player_ans = store_ans;
	assign tmp_led = {player_score , 6'd0, player_ans};
	reg win;
	always @(*) begin
		case (state)
			IDLE: begin 
				LED = 16'b1111_1111_1111_1111;
				value[15:12] = 4'd6;
				value[11:8] = 4'd0;
				value[7:4] = 4'd10;
				value[3:0] = 4'd10;
			end
			GAME: begin 
				LED = tmp_led;
			end 
			CHECK: begin 
				LED = tmp_led;
			end 
			FINAL:  begin 
				LED = 16'b1111_1111_1111_1111;
				if(win) begin
					value[15:12] = 4'd11;
					value[11:8] = 4'd11;
					value[7:4] = 4'd1;
					value[3:0] = 4'd12;
				end else begin
					value[15:12] = 4'd13;
					value[11:8] = 4'd14;
					value[7:4] = 4'd5;
					value[3:0] = 4'd15;
				end
			end 
		endcase 
    end
	
	

	//fsm transform
	always @(posedge clk or posedge rst_op) begin
        if(rst) begin 
            state <= IDLE; 
			store_score <= 0;
			store_ans <=0;
			current_time <= 6'd60;
			win <=1;

        end
        else begin 
            state <= next_state;
        end 
    end

	always @(*) begin
        case(state)
            IDLE: begin 
                next_state = (en_op) ? GAME : IDLE;
            end
            GAME: begin 
                if(enter_press) next_state = CHECK;
				else begin
					if(current_time == 0 )
						next_state = FINAL;
					else next_state = GAME;
				end
            end 
            CHECK: begin 
                next_state = ((count_2==2) || (player_score==3)) ? FINAL : GAME; 
            end 
            FINAL:  begin 
                next_state = restart_op ? IDLE : FINAL;
            end 

        endcase
    end
endmodule

