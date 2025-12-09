// <Student_ID> <Name>
module exam2_A(
    input clk, 
    input rst, 
    output [3:0] DIGIT, 
    output [6:0] DISPLAY
);
    // add your design here
		reg [3:0]ten; //display num
		reg [3:0]one;
		reg [3:0]hundred;
		reg [3:0]thousand;
		wire [15:0]num = {thousand, hundred, ten, one}; // display

		SevenSegment S(
    .clk(clk),
    .rst(rst),
    .nums(num),
    .digit(DIGIT),
    .display(DISPLAY)
);

		reg [15:0]xi;
		wire signed[15:0]temp_max_answer;
		reg signed[15:0]answer;

		always @(posedge clk) begin
			if(rst) begin
				// display
				thousand <= 4'd0;
				hundred <= 4'd0;
				ten <= 4'd0;
				one <= 4'd0;

				// xi initial
				xi <= 16'd0;

				// answer initial
				answer <= 16'd0;

			end else begin
				answer <= (temp_max_answer > answer) ? temp_max_answer : answer;
				one <= answer %10;
				ten <= (answer / 10) %10 ;
				hundred <= (answer / 100) %10;
				thousand <= (answer / 1000) %10;
				xi <= (xi == 16'b1111_1111_1111_1111) ? xi : xi+1;
			end			
		end

		integer i;
		reg signed[15:0] temp1;
		reg signed[15:0] temp2;
		reg signed[15:0] temp3;

		always @(*) begin
			temp1 = 16'd0;
			temp2 = 16'd0;
			temp3 = 16'd0;

			for(i=0;i<16;i=i+1) temp1 = temp1 + (i*xi[i]);
			for(i=0;i<8;i=i+1) temp2 = temp2 + (i*xi[i]);
			for(i=8;i<16;i=i+1) temp3 = temp3 + (i*xi[i]);
			
		end
		assign temp_max_answer =
    (temp1 - (temp2-temp3)*(temp2-temp3)) > 0 ?
    (temp1 - (temp2-temp3)*(temp2-temp3)) :
    0;
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