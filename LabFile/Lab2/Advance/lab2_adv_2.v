module lab2_adv_2 (
    input  wire        clk,
    input  wire        rst,                // {SW15} = {R2}
    input  wire [8:0]  switch_input,       // {SW8..SW0} = {V2, W13, W14, V15, W15, W17, W16, V16, V17}
    input  wire [1:0]  switch_inputtype,   // {SW13, SW12} = {U1, W2}

    input  wire        valid,              // SW14 = T1
    output reg  [13:0] out,                // LD13..LD0 mapping per spec
    output reg         satisfaction        // LD15 = L1
);

  // Internal storage (state)
  reg [8:0] clause1;
  reg [8:0] clause2;
  reg [8:0] clause3;
  reg [2:0] assign_reg; // {C,B,A} with A = assign_reg[0] (SW0)

  // temporary signals used in combinational evaluation
  reg c1_sat, c2_sat, c3_sat;

  // ------------------------------------------------------------
  // helper function: evaluate one literal
  // literal encoding assumed:
  // 3'b000 -> A     , 3'b100 -> ~A
  // 3'b001 -> B     , 3'b101 -> ~B
  // 3'b010 -> C     , 3'b110 -> ~C
  // others -> false
  // ------------------------------------------------------------
  function eval_literal;
    input [2:0] lit;
    input [2:0] a; // a = {C,B,A} with A = a[0]
    begin
      case (lit)
        3'b000: eval_literal = a[0];      // A
        3'b100: eval_literal = ~a[0];     // ~A
        3'b001: eval_literal = a[1];      // B
        3'b101: eval_literal = ~a[1];     // ~B
        3'b010: eval_literal = a[2];      // C
        3'b110: eval_literal = ~a[2];     // ~C
        default: eval_literal = 1'b0;
      endcase
    end
  endfunction

  // ------------------------------------------------------------
  // helper function: evaluate a 3-literal clause (9 bits)
  // clause[8:6], clause[5:3], clause[2:0]
  // ------------------------------------------------------------
  function eval_clause;
    input [8:0] clause;
    input [2:0] a;
    reg l1, l2, l3;
    begin
      l1 = eval_literal(clause[8:6], a);
      l2 = eval_literal(clause[5:3], a);
      l3 = eval_literal(clause[2:0], a);
      eval_clause = l1 | l2 | l3;
    end
  endfunction

  // ------------------------------------------------------------
  // Combinational: evaluate clauses and build outputs from stored regs
  // This makes simulation easier to reason about (outputs = f(state))
  // ------------------------------------------------------------
  always @(posedge clk or posedge rst) begin
    if (rst == 1) begin
      clause1      <= 9'b0;
      clause2      <= 9'b0;
      clause3      <= 9'b0;
      assign_reg   <= 3'b000;
      out          <= 14'b0;
      satisfaction <= 1'b0;
    end else if (valid == 1) begin
        case (switch_inputtype)
          2'b00: clause1    = switch_input;
          2'b01: clause2    = switch_input;
          2'b10: clause3    = switch_input; 
          2'b11: assign_reg = switch_input[2:0]; // only SW2..SW0 used
          default: ;
        endcase
        // note: outputs are computed in combinational block below
        c1_sat = eval_clause(clause1, assign_reg); // evaluate clause1 with current assignment
        c2_sat = eval_clause(clause2, assign_reg); // evaluate clause2 with current assignment
        c3_sat = eval_clause(clause3, assign_reg); // evaluate clause3 with current assignment
        
        // final satisfaction output
        satisfaction = (c1_sat && c2_sat && c3_sat) ? 1'b1 : 1'b0;
        out[13:10] = (c1_sat)? 4'b1111 : 4'b0000;
        out[8:5] = (c2_sat)? 4'b1111 : 4'b0000;
        out[3:0] = (c3_sat)? 4'b1111 : 4'b0000;
    end
end
endmodule
