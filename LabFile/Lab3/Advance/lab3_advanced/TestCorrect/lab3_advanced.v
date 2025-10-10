module lab3_basic (
    input wire clk,
    // Switch Inputs
    input wire rst,
    input wire mode,
    // Button Inputs
    input wire play, 
    input wire right,
    input wire left,
    input wire forward,
    // Outputs
    output reg [15:0] LED,
    output wire [3:0] DIGIT,  
    output wire [6:0] DISPLAY 
);
    // ======================================//
    // Wires and Registers
    // ======================================//
    // BCD registers are kept as 'reg' because they are driven by the sequential block
    reg [4:0] BCD4, BCD1, BCD2, BCD3; 
    wire clk_scan;
    wire clk_slow;
    // Debounce and One-Pulse Signals for Buttons
    wire right_debounce;
    wire right_one_pulse;
    wire left_debounce;
    wire left_one_pulse;
    wire play_debounce;
    wire play_one_pulse;
    wire forward_debounce;
    wire forward_one_pulse;
    // state
    localparam [2:0] INITIAL   = 3'b000,
                     PRACTICE  = 3'b001,
                     TIMING    = 3'b010,
                     FINAL     = 3'b011;
    reg [2:0] current_state, next_state;
    reg [20:0] count, count2, count3; // counters for different modes
    debounce db_play (.clk(clk_div_100Hz), .pb(play), .pb_debounced(play_db));
    one_pulse op_play (.clk(clk_div_100Hz), .pb_in(play_db), .pb_out(play_pulse));
    debounce db_right (.clk(clk_div_100Hz), .pb(right), .pb_debounced(right_db));
    one_pulse op_right (.clk(clk_div_100Hz), .pb_in(right_db), .pb_out(right_pulse));
    debounce db_left (.clk(clk_div_100Hz), .pb(left), .pb_debounced(left_db));
    one_pulse op_left (.clk(clk_div_100Hz), .pb_in(left_db), .pb_out(left_pulse));
    debounce db_forward (.clk(clk_div_100Hz), .pb(forward), .pb_debounced(forward_db));
    one_pulse op_forward (.clk(clk_div_100Hz), .pb_in(forward_db), .pb_out(forward_pulse));

    // counter clock dividers
    









    
    // NEW: State for the sequential display pattern
    reg [4:0] display_pattern; 

    // ======================================//
    // 1. Clock Dividers 
    // ======================================//
    // Original clock_divider for 7-segment scanning
    clock_divider #(.n(16)) scan_div (
        .clk(clk),
        .clk_div(clk_scan)
    );
    
    // Clock divider for slowing down the sequential display pattern change
    clock_divider #(.n(25)) slow_div (
        .clk(clk),
        .clk_div(clk_slow)
    );
    
    // ======================================//
    // 2. Sequential Control Logic
    // ======================================//
    // This state machine runs on the slow clock to cycle the pattern 0-18
    always @(posedge clk_slow or posedge rst) begin
        if (rst) begin
            display_pattern <= 5'd0; // Start at pattern 0
            // Initial assignment to BCD registers
            BCD4 <= 5'd0;
            BCD3 <= 5'd0;
            BCD2 <= 5'd0;
            BCD1 <= 5'd0;
        end else begin
            // Increment the display pattern from 0 to 18
            if (display_pattern < 5'd18) begin
                display_pattern <= display_pattern + 1;
            end else begin
                display_pattern <= 5'd0; // Roll back to 0 after 18
            end
            
            // Assign the current pattern to all BCD registers
            BCD4 <= display_pattern;
            BCD3 <= display_pattern;
            BCD2 <= display_pattern;
            BCD1 <= display_pattern;
        end
    end

    // ======================================//
    // 3. Display Controller Instantiation
    // ======================================//
    display_controller_4digit display_unit (
        .clk_scan (clk_scan),
        .rst      (rst),
        .BCD1     (BCD1),
        .BCD2     (BCD2),
        .BCD3     (BCD3),
        .BCD4     (BCD4),
        .DIGIT    (DIGIT), 
        .DISPLAY  (DISPLAY)  
    );

    // ======================================//
    // 4. Other I/O (LEDs)
    // ======================================//
    always @(*) begin
        LED = (rst) ? 16'hFFFF : 16'h0000; 
    end
    
endmodule