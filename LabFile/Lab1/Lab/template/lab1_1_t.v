`timescale 1ns/100ps
module lab1_1_t ();

    parameter DELAY = 5;
    wire out;
    reg a, b;
    reg [1:0] c;

    //====================================
    // TODO
    // Connect your lab1_1 module here with "a", "b", "c", "out"
    // Please connect it by port name but not order, or you will get no points for this part.
    // (WARNING: You are only permitted to write code in this section. Do not modify any other part of the testbench.)
    lab1_1 mux_4to1(.a(a), .b(b), .c(c), .out(out));


    //====================================

    reg answer;
    integer i, error_count;
    initial begin
        $display("===== Simulation ======");
        error_count = 0;
        {a, b, c} = 4'b000;

        for (i = 0; i < 16; i = i + 1) begin

            {a, b, c} = {a, b, c} + 1;
            #DELAY;
            case (c)
                2'b00: answer = a & b; // AND
                2'b01: answer = a | b; // OR
                2'b10: answer = a ^ b; // XOR
                2'b11: answer = ~(a & b); // NAND
                default: answer = 1'b0; // Default case
            endcase

            if (out !== answer) begin
                $display("Error: a=%b, b=%b, c=%b, out=%b", a, b, c, out);
                $display("Correct answer should be: out=%b", answer);
                error_count = error_count + 1;
            end else begin
                $display("Correct: a=%b, b=%b, c=%b, out=%b", a, b, c, out);
            end

        end

        if (error_count === 0) begin
            $display("===== All Correct ======");
        end else begin
            $display("===== There are %d errors ======", error_count);
        end
    end


endmodule