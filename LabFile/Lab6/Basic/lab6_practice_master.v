module lab6_practice_master (
	input wire clk,
	input wire rst,
	input wire [7:0] sw, // switches
	output reg [3:0] data_out  // data (number) to slave 
);

reg [3:0] i;
reg [3:0] sum;
reg [3:0] next_data_out;

always @ (posedge clk, posedge rst) begin
	if(rst == 1) data_out <= 4'b1111;
	else if(sum == 1) data_out <= next_data_out;
	else data_out <= 4'b1111;
end

always @ (*) begin
	next_data_out = 4'b1111;
	sum = 4'b0000;
	for(i = 4'b0000; i <= 4'b0111; i = i + 1) begin
		if(sw[i] == 1) begin
			next_data_out = i + 1;
			sum = sum + 1;
		end
	end
end

endmodule

