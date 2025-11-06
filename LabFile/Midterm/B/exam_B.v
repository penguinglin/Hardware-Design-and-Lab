module LFSR(
    input wire clk,
    input wire rst,
    input wire [3:0] seed,
    output reg [3:0] random
);
    always @(posedge clk) begin
        if(rst) 
            random <= seed;
        else begin
            random[2:0] <= random [3:1];
            random[3] <= (random[0] ^ random[1]);
        end
    end
endmodule

module FSM(
    input wire clk,
    input wire rst,
    input wire seq,
    output reg dec
);
    reg [1:0] state;
    reg [1:0] next_state;
    
    parameter S0 = 2'd0;
    parameter S1 = 2'd1;
    parameter S2 = 2'd2;
    parameter S3 = 2'd3;
    
    // FSM transform
    always @(posedge clk or posedge rst) begin
        /*TODO*/
        if(rst) begin 
            state <= S0; 
            dec <= 0;
        end
        else begin 
            state <= next_state;
        end 
    end
    reg tmp_dec;
    always @(*) begin
        case(state)
            S0: begin 
		        /*TODO*/
                next_state = seq ? S1 : S0;
                dec = 0;
            end
            S1: begin 
		        /*TODO*/
                next_state = seq ? S1 : S2;
                dec = 0;
            end 
            S2: begin 
		        /*TODO*/
                next_state = seq ? S3 : S0;
                dec = seq ? 1 : 0;
            end 
            S3:  begin 
		        /*TODO*/ 
                next_state = seq ? S1 : S2;
                dec = 0;
            end 

        endcase
    end
endmodule

module exam_B(
    input wire clk,
    input wire rst,
    input wire [3:0] seed,
    output wire [3:0] random,
    output wire seq,
    output wire dec
);
    assign seq = random[3];

    LFSR lfsr(
        .clk(clk),
        .rst(rst),
        .seed(seed),
        .random(random)
    );

    FSM fsm(
        .clk(clk),
        .rst(rst),
        .seq(seq),
        .dec(dec)
    );
endmodule