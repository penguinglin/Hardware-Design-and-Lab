`timescale 1ns/100ps
module lab1_1 (
    input wire a,
    input wire b,
    input wire [1:0] c,
    output wire out
);

    // Write your code here
    wire out0,out1,out2,out3;
    and(out0,a&b);
    or(out1,a|b);
    xor(out2,a^b);
    nand(out3, ~(a&b));
    wire mux_out1,mux_out2;

    mux m1(out0,out1,c[0],mux_out1);
    mux m2(out2,out3,c[0],mux_out2);
    mux m3(mux_out1,mux_out2,c[1],out);

endmodule

/* Uncomment the following code if needed */
module mux (
    input wire a,
    input wire b,
    input wire c,
    output wire y
);

//     Write your code here
    wire not_c;
    not(not_c, c);
    wire and1_out, and2_out;
    and(and1_out, a, not_c);
    and(and2_out, b, c);
    or(y, and1_out, and2_out);
    
endmodule