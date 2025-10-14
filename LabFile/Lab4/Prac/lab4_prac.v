module lab4_Practice (  
  input wire clk,
  input wire rst,
  input wire next,
  input wire shift,
  output reg [1:0] state,
  output reg [8:0] LED
);
  // clock divider
  wire clk_div;
  clock_divider #(15) u_clk_div (.clk(clk), .clk_div(clk_div));    

  
  // ================================================= //
  //           debounce and one pulse                  //
  // ================================================= //
  wire rst_db, next_db, shift_db;
  wire rst_pulse, next_pulse, shift_pulse;

  // debounce and one pulse
  debounce db0 (.clk(clk_div), .in(rst), .out(rst_db));
  one_pulse op0 (.clk(clk_div), .in(rst_db), .out(rst_pulse));
  debounce db1 (.clk(clk_div), .in(next), .out(next_db));
  one_pulse op1 (.clk(clk_div), .in(next_db), .out(next_pulse));
  debounce db2 (.clk(clk_div), .in(shift), .out(shift_db));
  one_pulse op2 (.clk(clk_div), .in(shift_db), .out(shift_pulse));

  // ================================================= //
  //           LFSR instantiation                      //
  // ================================================= //
  wire [8:0] lfsr_out;
  lfsr9_custom u_lfsr (
      .clk(clk_div),
      .rst(rst),     
      .shift_en(shift_pulse),
      .lfsr(lfsr_out)
  );

  always @(posedge clk_div or posedge rst) begin
    if (rst) begin
        LED <= 9'b101011001;
        state <= 2'b00;
    end else begin
        if (shift_pulse) LED <= lfsr_out;
        if (next_pulse) begin
            case (state)
                2'b00: state <= (lfsr_out[0] == 1'b1) ? 2'b10 : 2'b00;
                2'b01: state <= (lfsr_out[0] == 1'b1) ? 2'b00 : 2'b11;
                2'b10: state <= (lfsr_out[0] == 1'b1) ? 2'b01 : 2'b10;
                2'b11: state <= (lfsr_out[0] == 1'b1) ? 2'b11 : 2'b10;
            endcase
        end
    end
end






endmodule


