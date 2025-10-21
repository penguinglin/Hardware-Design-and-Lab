module GameTimer #(
    parameter CLK_FREQ = 100000000,    
    parameter S_RESULT = 3'b011,       
    parameter S_FINAL  = 3'b100
)(
    input  wire clk,
    input  wire rst,
    input  wire [2:0] state,             
    output wire clk_1s,
    output wire done_3s, 
    output wire done_5s               // for S_FINAL
);

    // === Counter for 1 second ===
    reg[28:0] counter_1s;
    reg [3:0]  sec_counter;   
    reg clk_1s_reg; 
    assign clk_1s = clk_1s_reg; 
    assign done_3s =  (sec_counter >= 3);
    assign done_5s =  (sec_counter >= 5);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_1s   <= 0;
            sec_counter  <= 0;
            clk_1s_reg   <= 0; 
        end else begin
            if (state == S_RESULT || state == S_FINAL) begin

                if (counter_1s < CLK_FREQ - 1) begin
                    counter_1s <= counter_1s + 1;
                end else begin
                    counter_1s <= 0;
                    clk_1s_reg <= ~clk_1s_reg; 
                    sec_counter <= sec_counter + 1;
                end

            end else begin
                counter_1s  <= 0;
                clk_1s_reg  <= 0;
                sec_counter <= 0;
            end
        end
    end
endmodule