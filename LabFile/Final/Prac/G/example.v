module demo_2(
   input clk,
   input rst,
   output [3:0] vgaRed,
   output [3:0] vgaGreen,
   output [3:0] vgaBlue,
   output hsync,
   output vsync
    );
  // clk
    wire clk_1, clk_22;
    clock_divider c1(.clk(clk), .clk1(clk_1), .clk22(clk_22));
  // vga + mem_gen
    wire [9:0]h_cnt;
    wire [9:0]v_cnt;
    wire valid;
    vga_controller vc(.pclk(clk_1), .reset(rst), .hsync(hsync), .vsync(vsync), .valid(valid), .h_cnt(h_cnt), .v_cnt(v_cnt));
    wire [16:0]pixel_addr;
    mem_addr_gen mg(.clk(clk_1), .rst(rst), .h_cnt(h_cnt), .v_cnt(v_cnt), .pixel_addr(pixel_addr));
  // blk_mem_gen + rgb
    wire [11:0]pixel;
    wire [11:0]data;
    blk_mem_gen_0 bg0(.clka(clk_1), .wea(0), .dina(data[11:0]), .douta(pixel), .addra(pixel_addr));
    assign {vgaRed, vgaGreen, vgaBlue} = (valid) ? pixel : 12'd0;
endmodule

module mem_addr_gen(
  input wire clk,
  input wire rst,
  input wire [9:0]h_cnt,
  input wire [9:0]v_cnt,
  output wire [16:0]pixel_addr
);
  //320*240 = 76800
  assign pixel_addr = ((h_cnt>>1) + 320*(v_cnt>>1)) % 76800;

  // offset count?
endmodule