module lab3_basic (
    input wire clk,
    input wire rst,
    input wire end_count,
    output reg [15:0] led
);
    /* Note that output port can be either reg or wire.
    * It depends on how you design your module. */
    
    // add your design here
    localparam [1:0] INITIAL = 2'b00,
                     PLAY    = 2'b01,
                     FINAL   = 2'b10;
    reg [1:0] state, next_state;

    // flash Final state
    wire flash_final;
    clock_divider #(.n(27)) counterfinal (
        .clk(clk),
        .clk_div(flash_final)
    );


    integer F_time;
    // use flash_final as clock, not clk
    always @(posedge flash_final or posedge rst) begin
        if (rst) begin
            F_time <= 0;
        end
        else if (state == FINAL) begin
            F_time <= F_time + 1;
        end
        else begin
            F_time <= 0;
        end
    end


    always@(posedge clk or posedge rst) begin
        if(rst) begin
            state <= INITIAL;

        end
        else state <= next_state;
    end


    reg[28:0]counter_half_sec;
    reg [5:0]LED_Left; // LD15~LD10, light from 000000 to 111111
    reg [9:0]LED_Right; // LD9~LD0, light from 0000000001 to 1111111111
    // half sec counter
    always @(posedge clk)begin
        if(state == PLAY)begin
            if(counter_half_sec < 50000000 - 1)begin
                counter_half_sec <= counter_half_sec + 1; // count to 0.5 sec
            end
            // count to 0.5 sec
            else begin
                counter_half_sec <= 0; // reset counter
                // light LD9~LD0
                if(LED_Right == 10'b1111111111)begin
                    LED_Right <= 10'b0000000001; // restart
                end
                else begin
                    LED_Right <= LED_Right << 1; // shift left
                    LED_Right[0] <= 1'b1; // right most bit always 1
                end

                // light LD15~LD10
                if(LED_Left == 6'b111111)begin
                    LED_Left <= 6'b000000; // restart
                end
                else begin
                    if(LED_Right[9] == 1'b1) begin // shift val and add 1 
                        LED_Left <= LED_Left << 1; // shift left
                        LED_Left[0] <= 1'b1; // right most bit always 1
                    end
                end
            end
        end
        // other state => reset all value
        else begin
            LED_Left <= 6'b0;
            LED_Right <= 10'b0000000001;
            counter_half_sec <= 0;
        end
    end

    // FSM & LED logic
    always @(*) begin
        case (state)
            INITIAL:begin
                led = 16'hFFFF;
                next_state = PLAY;
            end 
            // TODO
            PLAY:begin
                led = {LED_Left,LED_Right};
                next_state = (end_count || led[15] == 1) ? FINAL : PLAY;
            end
            FINAL:begin
                led = (flash_final) ? 16'hFFFF : 16'h0000;
                next_state = (F_time >= 4) ? INITIAL : FINAL;
            end
            default: begin
                led = 16'h0000;
                next_state = INITIAL;
            end
        endcase
    end

endmodule

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