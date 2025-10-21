module CompareUnit(
    input wire [15:0] secret,
    input wire [15:0] guess,
    output reg [3:0] A,
    output reg [3:0] B,
    output wire is_correct
);

wire [3:0] s0 = secret[3:0], s1 = secret[7:4], s2 = secret[11:8], s3 = secret[15:12];
wire [3:0] g0 = guess[3:0], g1 = guess[7:4], g2 = guess[11:8], g3 = guess[15:12];

reg [3:0] secret_used, guess_used;

always @(*) begin
    A = 0;
    B = 0;
    secret_used = 4'b0;
    guess_used = 4'b0;

    if (s0==g0) begin A=A+1; secret_used[0]=1; guess_used[0]=1; end
    if (s1==g1) begin A=A+1; secret_used[1]=1; guess_used[1]=1; end
    if (s2==g2) begin A=A+1; secret_used[2]=1; guess_used[2]=1; end
    if (s3==g3) begin A=A+1; secret_used[3]=1; guess_used[3]=1; end

    if (!guess_used[0]) begin
        if ((g0==s1 && !secret_used[1]) || (g0==s2 && !secret_used[2]) || (g0==s3 && !secret_used[3])) B = B+1;
    end
    if (!guess_used[1]) begin
        if ((g1==s0 && !secret_used[0]) || (g1==s2 && !secret_used[2]) || (g1==s3 && !secret_used[3])) B = B+1;
    end
    if (!guess_used[2]) begin
        if ((g2==s0 && !secret_used[0]) || (g2==s1 && !secret_used[1]) || (g2==s3 && !secret_used[3])) B = B+1;
    end
    if (!guess_used[3]) begin
        if ((g3==s0 && !secret_used[0]) || (g3==s1 && !secret_used[1]) || (g3==s2 && !secret_used[2])) B = B+1;
    end
end

assign is_correct = (A==4);

endmodule
