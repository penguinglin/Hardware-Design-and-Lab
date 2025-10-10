module lab3_basic (
    input wire clk,
    input wire rst,
    input wire mode,
    input wire play, 
    input wire right,
    input wire left,
    input wire forward,
    output reg [15:0] LED,
    output wire [3:0] DIGIT,  
    output wire [6:0] DISPLAY 
);
    // ======================================//
    // Wires and Registers
    // ======================================//
    // BCD registers are kept as 'reg' because they are driven by the sequential block
    reg [4:0] BCD4, BCD1, BCD2, BCD3; // 4 BCD digits
    wire clk_scan;
    wire clk_slow;
    
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