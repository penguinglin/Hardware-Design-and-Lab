`timescale 1ns/100ps
module practice_1 (
    input wire A,
    input wire B,
    input wire C,
    output wire out
);

    wire and_1, or_2;
    and (and_1, A, B);
    or  (or_2, A, B);
    mux m1 (and_1, or_2, C, out);

endmodule

module mux (
    input wire a,
    input wire b,
    input wire c,
    output wire y
);

    wire c_not;
    wire and1_out, and2_out;

    not (c_not, c);           
    and (and1_out, a, c_not);
    and (and2_out, b, c);
    or  (y, and1_out, and2_out);

endmodule