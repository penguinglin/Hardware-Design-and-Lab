module GameTimer_Modified #(
    parameter CLK_FREQ = 100000000, 
    parameter integer TIMER_DURATION_S = 1, 
    parameter S_RESULT = 3'b011,
    parameter S_FINAL  = 3'b100
)(
    input  wire clk,
    input  wire rst,
    input  wire [2:0] state,   
    output wire [9:0] round_count, 
    output wire is_blinking    
);

    reg[31:0] main_counter; 
    
    reg [9:0] round_count_reg; 
    reg is_blinking_reg; 

    assign round_count = round_count_reg; 
    assign is_blinking = is_blinking_reg; 
    
    localparam COUNT_LIMIT = CLK_FREQ * TIMER_DURATION_S - 1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            main_counter    <= 0;
            round_count_reg <= 0;
            is_blinking_reg <= 1'b0; 
        end else begin
            if (state == S_RESULT || state == S_FINAL) begin

                if (main_counter < COUNT_LIMIT) begin
                    main_counter <= main_counter + 1;
                end else begin
                    main_counter    <= 0;
                    round_count_reg <= round_count_reg + 1;
                    is_blinking_reg <= ~is_blinking_reg; 
                end

            end else begin
                main_counter    <= 0;
                round_count_reg <= 0;
                is_blinking_reg <= 1'b0; 
            end
        end
    end
endmodule