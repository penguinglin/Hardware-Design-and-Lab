module mem_addr_gen(
    input clk,
    input rst,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    output [14:0] pixel_addr
);
    assign pixel_addr = (  (h_cnt) +  160 * (v_cnt)) % 19200;
endmodule
