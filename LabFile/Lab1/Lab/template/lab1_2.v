`timescale 1ns/100ps

module lab1_2(
    input wire clk,
    input wire T,
    output wire Q,
    output wire Qn
);
    // write your code here
    wire D;
    xor(D, T,Q);

    DFF dff_inst (
        .clk(clk),
        .D(D),
        .Q(Q),
        .Qn(Qn)
    );

endmodule

module gated_D_latch(
    input wire Data,    
    input wire Gate,    
    output wire P,
    output wire Pn
);
    wire Data_n, tmp1, tmp2;
    not(Data_n, Data);
    nand(tmp1, Data, Gate);
    nand(tmp2, Data_n, Gate);
    nand(P, tmp1, Pn);
    nand(Pn, tmp2, P);
endmodule

/* Uncomment the following code if needed */
module DFF (
    input wire clk,
    input wire D,
    output wire Q,
    output wire Qn
);
    wire m, mn;  // master outputs
    wire s, sn;  // slave outputs

     // master latch, enabled when clk=0
    gated_D_latch master (
        .Data(D),
        .Gate(~clk),
        .P(m),
        .Pn(mn)
    );

    // slave latch, enabled when clk=1
    gated_D_latch slave (
        .Data(m),
        .Gate(clk),
        .P(Q),
        .Pn(Qn)
    );

// Initial simulation force to define startup state
   initial begin
        force Q  = 1'b0;
        force Qn = 1'b1;
        #1;
        release Q;
        release Qn;
    end

// Write your code here
    
endmodule