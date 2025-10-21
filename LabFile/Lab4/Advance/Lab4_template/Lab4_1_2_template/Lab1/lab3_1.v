module lab4_1 (
input wire clk,
input wire rst,
inout wire PS2_DATA,
inout wire PS2_CLK,
output wire [3:0] digit,
output wire [6:0] display
);
/* Note that output ports can be either reg or wire.
* It depends on how you design your module. */
// add you design here
  SampleDisplay sample_display_inst (
        .display(display),
        .digit(digit),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(rst),
        .clk(clk)
  );
endmodule