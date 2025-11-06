module lab5_2 (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [2:0] sw,
    inout wire PS2_CLK,
    inout wire PS2_DATA,
    output reg [3:0] vgaRed,
    output reg [3:0] vgaGreen,
    output reg [3:0] vgaBlue,
    output  hsync,
    output  vsync,
    output reg [15:0] led
);
// add your design here
endmodule

  