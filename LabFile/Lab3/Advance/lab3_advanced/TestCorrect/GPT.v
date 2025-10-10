module lab3_basic (
    input wire clk,
    input wire rst,
    input wire mode,
    input wire play, 
    input wire right,
    input wire left,
    input wire forward,
    output reg [15:0] LED,
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY
);

    // FSM state encoding
    localparam [2:0] INITIAL = 3'b000,
                     PRACTICE = 3'b001,
                     TIMING   = 3'b010,
                     FINAL    = 3'b011;

    reg [2:0] state, next_state;

    // Clock divider
    wire clk_1Hz, clk_2Hz, clk_100Hz;
    clock_divider #(27) div1 (.clk(clk), .clk_div(clk_1Hz));
    clock_divider #(26) div2 (.clk(clk), .clk_div(clk_2Hz));
    clock_divider #(20) div100 (.clk(clk), .clk_div(clk_100Hz));

    // Debounce + one pulse
    wire play_db, right_db, left_db, forward_db;
    wire play_pulse, right_pulse, left_pulse, forward_pulse;
    debounce db0 (.clk(clk_100Hz), .pb(play), .pb_debounced(play_db));
    debounce db1 (.clk(clk_100Hz), .pb(right), .pb_debounced(right_db));
    debounce db2 (.clk(clk_100Hz), .pb(left), .pb_debounced(left_db));
    debounce db3 (.clk(clk_100Hz), .pb(forward), .pb_debounced(forward_db));

    one_pulse op0 (.clk(clk_100Hz), .pb_in(play_db), .pb_out(play_pulse));
    one_pulse op1 (.clk(clk_100Hz), .pb_in(right_db), .pb_out(right_pulse));
    one_pulse op2 (.clk(clk_100Hz), .pb_in(left_db), .pb_out(left_pulse));
    one_pulse op3 (.clk(clk_100Hz), .pb_in(forward_db), .pb_out(forward_pulse));

    // Puzzle selection
    reg [1:0] puzzle_id; // 1~3

    // Time counter (for timing mode)
    reg [6:0] sec_counter;
    reg [6:0] best_time [1:3];  // best records

    // FSM state transition
    always @(posedge clk_100Hz or posedge rst) begin
        if (rst) state <= INITIAL;
        else state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            INITIAL: begin
                if (play_pulse) next_state = (mode == 1'b0) ? PRACTICE : TIMING;
            end
            PRACTICE, TIMING: begin
                if (/* puzzle solved */ 0) next_state = FINAL;
            end
            FINAL: begin
                if (/* after 3 sec */ 0) next_state = INITIAL;
            end
        endcase
    end

    // Display control (簡化示例)
    always @(*) begin
        case (state)
            INITIAL: begin
                // show puzzle number + best score
            end
            PRACTICE: begin
                // show current pen and puzzle pattern
            end
            TIMING: begin
                // show puzzle + time
            end
            FINAL: begin
                // show PrAC or record
            end
        endcase
    end

endmodule
