module lab3_practice (
    input wire clk,
    input wire rst,
    input wire slow,
    input wire fast,
    input wire end_light,
    output reg [15:0] led
);
    /* Note that output port can be either reg or wire.
    * It depends on how you design your module. */
    // add your design here
    // FSM states
    localparam [1:0] INITIAL = 2'b00,
                     PLAY    = 2'b01,
                     FINAL   = 2'b10;

    reg [1:0] state, next_state;

    // Clock dividers
    wire slow_clk, fast_clk;
    clock_divider #(.n(28)) div_slow (
        .clk(clk),
        .clk_div(slow_clk)
    );
    clock_divider #(.n(27)) div_fast (
        .clk(clk),
        .clk_div(fast_clk)
    );
    

    // Counter for FINAL state (5 seconds)
    reg[28:0]counter;
    reg flash;
    integer flash_time;
    // one sec counter
    always @(posedge clk)begin
        if(state == 2'b10)begin
            if(counter < 100000000 - 1)begin
                counter <= counter + 1;
            end
            else begin
                counter <= 0;
                flash <= !flash;
                flash_time <= flash_time + 1;
            end
        end
        else begin
            flash <= 1;
            flash_time <= 0;
        end
    end


    // FSM sequential
    always @(posedge clk or posedge rst) begin
        if (rst) 
            state <= INITIAL;
        else 
            state <= next_state;
    end

    // FSM next state logic
    always @(*) begin
        case (state)
            INITIAL: next_state = PLAY;
            
            PLAY:    next_state = (end_light) ? FINAL : PLAY;
            
            FINAL:   next_state = (flash_time == 3'd5) ? INITIAL : FINAL;

            default: next_state = INITIAL;
        endcase
    end
    

    // LED output logic
    always @(*) begin
        case (state)
            INITIAL: led = 16'hFFFF;

            PLAY: begin
                led = 16'h0000;
                if (slow) 
                    led = led | (slow_clk ? 16'h5555 : 16'h0000); // even LEDs
                if (fast) 
                    led = led | (fast_clk ? 16'hAAAA : 16'h0000); // odd LEDs
            end

            FINAL: led = (flash) ? 16'hFFFF : 16'h0000;
            default: led = 16'h0000;
        endcase
    end    
endmodule


// ======= Divider module (provide by TA) =======
module clock_divider #(
    parameter n = 10 // 100MHz / (2^10)
)(
    input wire  clk,
    output wire clk_div  
);

    reg [n-1:0] num;
    wire [n-1:0] next_num;

    always @(posedge clk) begin
        num <= next_num;
    end

    assign next_num = num + 1;
    assign clk_div = num[n-1];
endmodule

