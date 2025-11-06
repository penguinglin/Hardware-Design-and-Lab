module lab5_prac(
  input wire clk,
  input wire rst,

  // write
  input wire we,
  input wire [2:0] w_addr,
  input wire [3:0] din,

  //read A
  input wire re_a,
  input wire [2:0] r_addr_a,
  output reg [3:0] dout_a,

  //read B
  input wire re_b,
  input wire [2:0] r_addr_b,
  output reg [3:0] dout_b
);
  // memory declaration: 8 x 4 bits
  reg [3:0] memory [0:7];

  // sequential logic
  integer i;
  always @(posedge clk or posedge rst) begin
    if(rst) begin
      for (i = 0;i<8;i=i+1) memory[i] <= 4'b0000;
      // reset
      dout_a <= 4'b0000;
      dout_b <= 4'b0000;
    end else begin
      if(we) memory[w_addr] <= din;
    
      // read port A
      if(re_a) begin
        if (we && (w_addr == r_addr_a))
          dout_a <= din; // write-first
        else
          dout_a <= memory[r_addr_a];
      end else dout_a <= 4'b0000;

      // read port B
      if(re_b) begin
        if (we && (w_addr == r_addr_b))
          dout_b <= din; // write-first
        else
          dout_b <= memory[r_addr_b];
      end else dout_b <= 4'b0000;
    end
  end

endmodule