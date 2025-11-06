module lab5_practice (
    input wire clk,
    input wire rst,
    input wire [2:0] addr,
    input wire we, 
    input wire [7:0] din,
    input wire re,
    input wire start,
    output reg [7:0] dout,
    output reg done,
    output reg [7:0] ans
);


    reg [7:0] memory [0:5];
    
    integer i;
    reg [2:0] count;
    reg start_sum = 0;

    always @ (posedge clk, posedge rst) begin
        if(rst == 1) begin
            for(i = 0; i < 6; i = i + 1) begin
                memory[i] <= 8'b0;
            end
            dout <= 8'b0;
            done <= 1'b0;
            ans <= 8'b0;
            start_sum <= 1'b0;
            count <= 3'b0;
        end else begin
            if(we == 1) begin
                memory[addr] <= din;
            end

            if(re == 1) begin
                dout <= memory[addr];
            end

            if(start == 1 && start_sum == 0) begin
                ans <= 8'b0;
                count <= 3'b0;
                start_sum <= 1'b1;
                done <= 1'b0;
            end

            if(start_sum == 1) begin
                ans <= ans + memory[count];
                count <= count + 1;
                if(count == 3'b101) begin
                    done <= 1;
                    start_sum <= 0;
                end
            end

        end
    end



    
endmodule