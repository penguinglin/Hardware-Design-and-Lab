`timescale 1ns/1ps

module lab2_adv_1 (
    input clk,
    input rst,
    input [8:0] clause_1,
    input [8:0] clause_2,
    input [8:0] clause_3,
    input [8:0] clause_4,
    output reg satisfaction,
    output reg [2:0] out
);

    integer i;
    reg [2:0] assign_val;
    reg found;

    // function: evaluate one literal given assignment
    function eval_lit;
        input [2:0] lit;      // literal encoding
        input [2:0] val;      // {A,B,C}
        begin
            case(lit)
                3'b000: eval_lit = val[0];     // A
                3'b100: eval_lit = ~val[0];    // ~A
                3'b001: eval_lit = val[1];     // B
                3'b101: eval_lit = ~val[1];    // ~B
                3'b010: eval_lit = val[2];     // C
                3'b110: eval_lit = ~val[2];    // ~C
                default: eval_lit = 1'b0;      // invalid literal = false
            endcase            
        end
    endfunction

    // function: evaluate one clause
    function eval_clause;
        input [8:0] clause;
        input [2:0] val;
        reg l1, l2, l3;
        begin
            l1 = eval_lit(clause[8:6], val);
            l2 = eval_lit(clause[5:3], val);
            l3 = eval_lit(clause[2:0], val);
            eval_clause = l1 | l2 | l3;
            
            // display the clauses and the return result as
            // Clause %d, with each literal %s, %s, %s and assignment %b: result=%b
            $display("Clause %b, with literals %s, %s, %s and assignment %b: result=%b", clause, 
                (clause[8:6] == 3'b000) ? "A"  : (clause[8:6] == 3'b100) ? "~A" :
                (clause[8:6] == 3'b001) ? "B"  : (clause[8:6] == 3'b101) ? "~B" :
                (clause[8:6] == 3'b010) ? "C"  : (clause[8:6] == 3'b110) ? "~C" : "Invalid",

                (clause[5:3] == 3'b000) ? "A"  : (clause[5:3] == 3'b100) ? "~A" :
                (clause[5:3] == 3'b001) ? "B"  : (clause[5:3] == 3'b101) ? "~B" :
                (clause[5:3] == 3'b010) ? "C"  : (clause[5:3] == 3'b110) ? "~C" : "Invalid",

                (clause[2:0] == 3'b000) ? "A"  : (clause[2:0] == 3'b100) ? "~A" :
                (clause[2:0] == 3'b001) ? "B"  : (clause[2:0] == 3'b101) ? "~B" :
                (clause[2:0] == 3'b010) ? "C"  : (clause[2:0] == 3'b110) ? "~C" : "Invalid",
                val, eval_clause
            );
        end        
    endfunction

    // 新增暫存變數
    reg [2:0] temp_out;
    reg temp_satisfaction;

    always @(posedge clk) begin
        if (rst) begin
            satisfaction <= 0;
            out <= 3'b000;
        end else begin
            temp_satisfaction = 0;
            temp_out = 3'b111;
            found = 0;  

            for (i = 0; i < 8 && !found; i = i + 1) begin
                assign_val = i[2:0];
                if (eval_clause(clause_1, assign_val) &&
                    eval_clause(clause_2, assign_val) &&
                    eval_clause(clause_3, assign_val) &&
                    eval_clause(clause_4, assign_val) ) begin
                    temp_out = assign_val;      
                    temp_satisfaction = 1;
                    found = 1;       
                    $display("Found satisfying assignment %b", temp_out);
                end else begin
                    // do nothing, try next assignment
                    // display the assignment tried
                    $display("Tried assignment %b: not satisfied", assign_val);
                end
            end

            out <= temp_out;
            satisfaction <= temp_satisfaction;
        end
    end

endmodule
