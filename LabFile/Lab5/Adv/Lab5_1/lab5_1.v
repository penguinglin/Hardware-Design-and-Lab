// lab5_1.v
module lab5_1 ( 
    input wire clk,
    input wire rst,
    // ---------------------
    // diff signal
    input wire dir_left,
    input wire dir_up,
    // ---------------------
    input wire vmir,
    input wire hmir,
    // ---------------------
    // extra signal
    input wire speed,
    // ---------------------
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen, 
    output wire [3:0] vgaBlue, 
    output wire hsync,
    output wire vsync 
);
    // add your design here
    wire [11:0] data;
    wire clk_2;
    wire clk_22;
    wire [16:0] pixel_addr;
    wire [11:0] pixel;
    wire valid;
    wire [9:0] h_cnt; //640
    wire [9:0] v_cnt;  //480

    wire debounce_rst, one_pulse_rst;
    debounce deb_1(.pb_debounced(debounce_rst), .pb(rst), .clk(clk));
    one_pulse one_1(.clk(clk), .pb_in(debounce_rst), .pb_out(one_pulse_rst));

    assign {vgaRed, vgaGreen, vgaBlue} = (valid==1'b1) ? pixel:12'h0;

    clock_divider #(.n(2)) clk_div_2(
        .clk(clk),
        .clk_div(clk_2)
    );

    clock_divider #(.n(22)) clk_div_22(
        .clk(clk),
        .clk_div(clk_22)
    );


    mem_addr_gen mem_inst(
        .clk(clk_22),
        .rst(rst),
        .dir_left(dir_left),
        .dir_up(dir_up),
        .vmir(vmir),
        .hmir(hmir),
        .speed(speed),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr(pixel_addr)
    );


    vga_controller vga_inst(
        .pclk(clk_2),
        .reset(rst),
        .hsync(hsync),
        .vsync(vsync),
        .valid(valid),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt)
    );


    blk_mem_gen_0 blk_inst(
        .clka(clk_2),
        .wea(0),
        .addra(pixel_addr),
        .dina(data[11:0]),
        .douta(pixel)
    );



endmodule 