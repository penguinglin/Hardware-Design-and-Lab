`timescale 1ns/100ps

module practice_2(
  input wire G,
  input wire D,
  output wire P,
  output wire Pn
);
  
  wire Dn;
  wire S, R;


  not (Dn, D);
  and (S, D, G);
  and (R, Dn, G);
  nor (P, R, Pn);
  nor (Pn, S, P);

endmodule
