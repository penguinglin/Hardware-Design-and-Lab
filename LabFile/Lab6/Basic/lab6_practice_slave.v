module lab6_practice_slave (
	input wire clk,
	input wire rst,
	input wire [3:0] data_in, // data (number) from master
	output reg [7:0] led // LEDs
);

integer i;

always @ (posedge clk, posedge rst) begin
	if(rst == 1) led <= 8'b0;
	else begin
		if(data_in == 4'b1111) led <= 8'b0;
		else begin
			for(i = 0; i <= 7; i = i + 1) begin
				if(i == data_in - 1) led[i] <= 1'b1;
				else led[i] <= 1'b0;
			end
		end
	end
end

endmodule
