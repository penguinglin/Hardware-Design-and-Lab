// ====================================//
//    Debounce and One Pulse Modules   //
// ====================================//
module debounce(
  input wire clk,
  input wire in,
  output wire out
);
  reg [3:0] shift_reg;  // 4-bit shift register
  always @(posedge clk) begin //synchronous clk
    shift_reg[3:1] <= shift_reg[2:0]; //shift
    shift_reg[0] <= in; //new input
  end
  assign out = ((shift_reg == 4'b1111) ? 1'b1 : 1'b0);
endmodule


module one_pulse(
  input wire clk,
  input wire in,
  output wire out
);
  reg in_delay;
  reg out_reg;
  always @(posedge clk) begin
    if (in == 1'b1 && in_delay == 1'b0) begin
      out_reg <= 1'b1;
    end else begin
      out_reg <= 1'b0;
    end
  end
  // Delay the input signal by one clock cycle
  always @(posedge clk) begin
    in_delay <= in;
  end

  // Output logic
  assign out = out_reg;
endmodule




// ====================================//
//       Clock Division Module         //
// ====================================//
module clock_divider #(
    parameter n = 27
)(
    input wire  clk,
    output wire clk_div  
);

    reg [n-1:0] num;
    wire [n-1:0] next_num;

    always @(posedge clk) begin
        num <= next_num;
    end

    assign next_num = num + 1;
    assign clk_div = num[n-1];
endmodule