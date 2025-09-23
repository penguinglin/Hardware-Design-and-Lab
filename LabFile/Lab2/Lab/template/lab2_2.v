module lab2_2 (
    input  wire        clk,
    input  wire        rst,       // synchronous active-high reset
    input  wire        impulse,   // trigger
    input  wire signed [7:0] A,
    input  wire signed [7:0] B,
    output reg  signed [15:0] OUT1,
    output reg  signed [7:0]  OUT2
);

    reg signed [7:0]storeAB;
    reg signed [7:0] buf1;

    always @(posedge clk) begin
        if(rst || impulse == 0) begin 
            storeAB <= 0;
            //
            OUT1 <= 16'b0;
            //
            OUT2 <= 8'b0;
        end
        else if (impulse == 1)begin
            // storeAB <= ((A*B) >= 15'b0 ) ? ((A*B) % 128) : (-(A*B))%128;
            if(A*B >= 0) begin
                storeAB <= (A*B) % 128;
            end
            else begin
                storeAB <= (-(A*B)) % 128;
            end
            //
            OUT1 <= {A, B};
            //
        end

        OUT2 <= buf1;
        buf1 <= storeAB;
    end

endmodule
