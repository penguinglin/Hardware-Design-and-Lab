module lab6_practice_slave (
    input wire clk,
    input wire rst,
    input wire [3:0] data_in, // data (number) from master
    output wire [7:0] led     // LEDs
);

reg [7:0] led_reg;

always @(posedge clk or posedge rst) begin
    if (data_in == 8'd0) begin
        led_reg <= 8'b11111111; 
    end else begin
        led_reg <= 8'b11111111 & ~(8'b00000001 << (data_in-1));
    end
end

assign led = led_reg;

endmodule
