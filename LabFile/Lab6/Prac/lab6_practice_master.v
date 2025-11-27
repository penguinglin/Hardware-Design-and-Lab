module lab6_practice_master (
	input wire clk,
	input wire rst,
	input wire [7:0] sw, // switches
	output reg [3:0] data_out  // data (number) to slave 
);

// add your design here

always @(posedge clk or posedge rst) begin
    if (rst) begin
        data_out <= 4'b0000;
    end else begin
        if (sw[0]) 
            data_out <= 4'd1;
        else if (sw[1]) 
            data_out <= 4'd2;
        else if (sw[2]) 
            data_out <= 4'd3;
        else if (sw[3]) 
            data_out <= 4'd4;
        else if (sw[4]) 
            data_out <= 4'd5;
        else if (sw[5]) 
            data_out <= 4'd6;
        else if (sw[6]) 
            data_out <= 4'd7;
        else if (sw[7]) 
            data_out <= 4'd8;
				else data_out <= 4'd0;
    end
end



endmodule



