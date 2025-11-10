module GameCenter(
    input wire clk,
    input wire rst,
    input wire check_en,                      // Enable signal to start the check
    input wire [31:0] answer,                 // The chosen puzzle answer (e.g., puzzle_one_ans)
    input wire [31:0] display_puzzle_transform, // Player's input to be checked
    output reg [15:0] puzzle_solved           // 16-bit output: a '1' indicates a correct 2-bit segment
);

    integer i;

    always @(*) begin
        puzzle_solved = 16'h0000; 

        if (check_en) begin
            for(i=0; i<16; i=i+1) begin
                
                if (answer[i*2 +:2] == display_puzzle_transform[i*2 +:2]) begin
                    puzzle_solved[i] = 1'b1;
                end
            end
        end
    end

endmodule