`timescale 1ns/100ps

module lab1_2_t();
    reg clk = 0, T;
    wire Q, Qn, expected_Q, expected_Qn;

    //====================================
    // TODO
    // Connect your lab1_2 module here with "clk", "T", "Q", and "Qn".
    // Please connect it by port name but not order, or you will get no points for this part.
    // (WARNING: You are only permitted to write code in this section. Do not modify any other part of the testbench.)
    lab1_2 implement(.clk(clk), .T(T), .Q(Q), .Qn(Qn));



    //====================================

    golden_2 golden_TFF(.clk(clk), .T(T), .Q(expected_Q), .Qn(expected_Qn));

    // Data input T: 0 -> 1 -> 1 -> 0 -> 0 -> 1 -> 0 -> 1, ...
    parameter LEN = 20;
    reg [0:LEN-1] T_pattern = 20'b0110_0101_1010_1111_0000;  

    reg [0:LEN-1] student_Qs;
    reg [0:LEN-1] student_Qns;
    reg [0:LEN-1] golden_Qs;
    reg [0:LEN-1] golden_Qns;
    integer error_count, i;

    always #5 clk = ~clk; // clock signal, period 10ns

    initial begin 
        error_count = 0;
        for (i = 0; i < LEN; i = i + 1) begin
            #1; // small delay for TFF to read the correct input
            T = T_pattern[i];
            #1; // small delay to ensure output is ready
            student_Qs[i] = Q;
            student_Qns[i] = Qn;
            golden_Qs[i] = expected_Q;
            golden_Qns[i] = expected_Qn;
            if (Q !== expected_Q) error_count = error_count + 1;
            if (Qn !== expected_Qn) error_count = error_count + 1;

            #8; // wait till next rising-edge
        end

        if (error_count === 0) $display("[SUCCESS]: All tests passed successfully!");
        else begin
            $display("[ERROR]: There were %d errors.", error_count);

            $write("     Data input T: %b", T_pattern[0]);
            for (i = 1; i < LEN; i = i + 1) $write(" -> %b", T_pattern[i]);
            $write("\n");

            $write("    Your output Q: %b", student_Qs[0]);
            for (i = 1; i < LEN; i = i + 1) $write(" -> %b", student_Qs[i]);
            $write("\n");

            $write("   Your output Qn: %b", student_Qns[0]);
            for (i = 1; i < LEN; i = i + 1) $write(" -> %b", student_Qns[i]);
            $write("\n");

            $write(" Correct output Q: %b", golden_Qs[0]); 
            for (i = 1; i < LEN; i = i + 1) $write(" -> %b", golden_Qs[i]);
            $write("\n");

            $write("Correct output Qn: %b", golden_Qns[0]);
            for (i = 1; i < LEN; i = i + 1) $write(" -> %b", golden_Qns[i]);
            $write("\n");
        end
        $finish;            
    end
endmodule

module golden_2 (
    input wire clk,
    input wire T,
    output reg Q,
    output wire Qn
);
    initial Q = 0;
    assign Qn = ~Q;
    always @(posedge clk) Q <= T ? ~Q : Q;
endmodule