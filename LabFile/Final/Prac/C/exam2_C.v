// <Student_ID> <Name>
module exam2_A(
    input clk, 
		input rst,
		input btnC,
		input btnU,
		input btnR,
		input [15:0]sw,
		output [15:0]led,
    output [3:0] DIGIT, 
    output [6:0] DISPLAY
);
    // add your design here
		wire btnC_d, btnC_op, btnU_d, btnU_op, btnR_d, btnR_op,rst_d, rst_op;
		debounce d1( .pb(btnC), .clk(clk), .pb_debounced(btnC_d));
		debounce d2( .pb(btnU), .clk(clk), .pb_debounced(btnU_d));
		debounce d3( .pb(rst), .clk(clk), .pb_debounced(rst_d));
		one_pulse o3( .pb_debounced(rst_d), .clk(clk), .pb_one_pulse(rst_op));
		debounce d4( .pb(btnR), .clk(clk), .pb_debounced(btnR_d));

		reg [15:0]temp_led;
		reg [4:0]temp_total;
		reg [4:0]total ;
		wire [4:0]one = total % 10;
		wire [4:0]ten = (total /10) %10;
		wire [15:0]nums = {8'd0, ten[3:0], one[3:0]};
		integer  i;		
		assign led = (btnU) ? 16'hFFFF : temp_led;

		always @(posedge clk or posedge rst_op)begin
			if(rst_op) begin
				total <= 5'd0;
			end else begin
				total <= (btnU) ? 5'd16 : (btnC) ? (16 - temp_total) : temp_total;
			end
		end

		
		always @(*) begin
			temp_total = 0;
			for(i=0;i<=15;i=i+1)begin
				temp_led[i] = (sw[i]) ? 1 : 0;
				temp_total = (sw[i]) ? temp_total +1 : temp_total;
			end
			temp_led = (btnC) ? ~temp_led : temp_led;
			temp_led = (btnR) ? {temp_led[0],temp_led[15:1]} : temp_led;			
		end	

		SevenSegment S(
			.display(DISPLAY),
			.digit(DIGIT),
			.nums(nums),
			.rst(rst),
			.clk(clk)
		);	
endmodule

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

module count_half(
	input wire clk,
	input wire rst,
	input wire [1:0]state,
	input wire count_en,
	output reg [3:0] count,
	output reg flash // 0 nothing, 1 flash
	); 

	reg [30:0]temp; // half second: 50000000

	always @(posedge clk or posedge rst)begin
		if(rst) begin
			temp <= 31'd0;
			count <= 4'd0;
			flash <= 0;
		end else if(state == 2'b01 && count_en) begin
			if(temp < 50000000 -1) temp <= temp +1;
			else begin
				temp <= 31'd0;
				count <= count +1;
				flash <= ~flash;
			end
		end else begin
			temp <= 31'd0;
			count <= 3'd0;
			flash <= 0;
		end
	end
endmodule