`timescale 1ns/1ps
module lab5_precaitc_t;
    reg clk;
    reg rst;

    reg we;
    reg [2:0] w_addr;
    reg [3:0] din;

    reg re_a;
    reg [2:0] r_addr_a;
    wire [3:0] dout_a;

    reg re_b;
    reg [2:0] r_addr_b;
    wire [3:0] dout_b;

    initial clk = 1;
    always #5 clk = ~clk;

    lab5_practice m1(
        .clk(clk),
        .rst(rst),
        .we(we),
        .w_addr(w_addr),
        .din(din),
        .re_a(re_a),
        .r_addr_a(r_addr_a),
        .dout_a(dout_a),
        .re_b(re_b),
        .r_addr_b(r_addr_b),
        .dout_b(dout_b)
    );

    initial begin
        rst = 0;
        #1
        rst = 1;
        #10
        rst = 0;
    end

    initial begin
        re_a = 0;
        re_b = 0;
        #32
        we = 1;
        w_addr = 2;
        din = 10;
        #10
        we = 0;

        #10

        we = 1;
        w_addr = 6;
        din = 4;
        #10
        w_addr = 7;
        din = 14;
        re_a = 1;
        re_b = 1;
        r_addr_a = 2;
        r_addr_b = 6;
        #10
        we = 0;
        re_a = 0;
        re_b = 0;

        #10

        we = 1;
        w_addr = 3;
        din = 8;
        re_b = 1;
        r_addr_b = 7;
        #10
        w_addr = 6;
        din = 9;
        re_a = 1;
        r_addr_a = 6;
        re_b = 0;
        #10
        we = 0;
        re_a = 0;



    end

    initial begin
        #150
        $finish;
    end

endmodule