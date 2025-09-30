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
    wire clk_fast,clk_slow;
    wire sign_fast,sign_slow;
    wire final_cnt;
    reg [1:0] state; //00 = initial 01 = play 10 = final
    reg [1:0] nxt_state;
    reg[28:0]counter;
    reg flash;
    integer flash_time;
    assign sign_fast = (fast)? clk_fast : 0;
    assign sign_slow = (slow)? clk_slow : 0;

    clock_divider #(.n(28)) m1(
        .clk(clk),
        .clk_div(clk_slow)
    );

    clock_divider #(.n(27)) m2(
        .clk(clk),
        .clk_div(clk_fast)
    );

    // state update
    always @(posedge clk, posedge rst)begin
        if(rst == 1) state <= 2'b00;
        else state <= nxt_state;
    end

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

    //next state update
    always@*begin
        nxt_state <= 2'b00;
        case(state)
            2'b00:begin
                if(rst == 0) nxt_state <= 2'b01;
            end
            2'b01:begin
                if(end_light == 1) nxt_state <= 2'b10;
                else nxt_state <= 2'b01;
            end
            2'b10:begin
                if(flash_time == 5) nxt_state <= 2'b00;
                else nxt_state <= 2'b10;
            end
            default: ;
        endcase
    end

    //led assign
    always@*begin
        if(state == 2'b00)begin
            led <= 16'b1111_1111_1111_1111;
        end
        else if(state == 2'b01)begin
            led[0] <= sign_fast; led[1] <= sign_slow;
            led[2] <= sign_fast; led[3] <= sign_slow;
            led[4] <= sign_fast; led[5] <= sign_slow;
            led[6] <= sign_fast; led[7] <= sign_slow;
            led[8] <= sign_fast; led[9] <= sign_slow;
            led[10] <= sign_fast; led[11] <= sign_slow;
            led[12] <= sign_fast; led[13] <= sign_slow;
            led[14] <= sign_fast; led[15] <= sign_slow;
        end
        else begin
            if(flash) led <= 16'b1111_1111_1111_1111;
            else led <= 16'b0000_0000_0000_0000;
        end
    end
    // add your design here
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