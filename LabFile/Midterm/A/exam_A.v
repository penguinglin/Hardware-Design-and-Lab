module exam_A(
    input wire clk,
    input wire rst,
    input wire [1:0] op,
    input wire [3:0] A,
    input wire [3:0] B,
    input wire [3:0] C,
    output reg [3:0] out // You can modify "reg" to "wire" if needed
);
    // You can add extra wire or reg here
    // for 2'b00 input
    reg [3:0]zero_compute;
    integer  i;

    // conpute 2'b10
    reg [3:0]vote_result;
    reg [3:0]AB;
    reg [3:0]AC;
    reg [3:0]BC;
    integer j;

    // compute 2'b11
    wire  [15:0]leftshift_result;
    assign leftshift_result = {A, B, A, B};
    reg [15:0]shift_result;    

    
    always @(*) begin
        /*TODO*/
        // conpute 0
        for(i=0;i<4;i=i+1) begin 
            zero_compute[i] = (A[i]==B[i])? C[i] : ~C[i];
        end

        // compute 1
        for(j=0;j<4;j=j+1) begin
            AB[j] = A[j] & B[j];
            AC[j] = A[j] & C[j];
            BC[j] = B[j] & C[j];

            vote_result[j] = (AB[j] || AC[j] || BC[j]) ? 1 : 0;
        end

        shift_result = ( leftshift_result << C );
        //shift_result = ( leftshift_result );
    end

    always @(posedge clk or posedge rst) begin
        if(rst) out <= 4'd0;
        else begin
        case(op)
            2'b00:
            	/*TODO*/
                out <= zero_compute;
            2'b01:
		        /*TODO*/
                out <= ((A + B + C) > 15) ? 4'd15 : (A+B+C) ;
            2'b10:
		        /*TODO*/
                out <= vote_result;
            2'b11:
		        /*TODO*/
                out <= shift_result[15:12];
        endcase
        end
    end    

endmodule