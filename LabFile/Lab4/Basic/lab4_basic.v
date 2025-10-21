module lab4_basic ( 
    input wire clk,
    input wire rst,
    input wire btnL,
    input wire btnR,
    input wire btnD,
    input wire btnU,
    output reg [3:0]num,
    output reg [1:0]out,
    output reg [3:0]LED
); 
    // clock divider
    wire clk_div;
    clock_divider #(.n(16)) u_clk_div (.clk(clk), .clk_div(clk_div)); 


    wire left_db, right_db, down_db, up_db; // Debounced signals for left, right, down, next buttons
    debounce debounce_left (.pb_debounced(left_db), .pb(btnL), .clk(clk_div)); 
    debounce debounce_right (.pb_debounced(right_db), .pb(btnR), .clk(clk_div));
    debounce debounce_down (.pb_debounced(down_db), .pb(btnD), .clk(clk_div));
    debounce debounce_up (.pb_debounced(up_db), .pb(btnU), .clk(clk_div));
    wire left_op, right_op, down_op, up_op; // One pulse signals for left, right, down and next buttons
    one_pulse one_pulse_left (.clk(clk_div), .pb_in(left_db), .pb_out(left_op));
    one_pulse one_pulse_right (.clk(clk_div), .pb_in(right_db), .pb_out(right_op));
    one_pulse one_pulse_down (.clk(clk_div), .pb_in(down_db), .pb_out(down_op));
    one_pulse one_pulse_next (.clk(clk_div), .pb_in(up_db), .pb_out(up_op));

    reg [1:0] state, next_state; // FSM state
    parameter IDLE = 0; // FSM idle state
    parameter PLAY = 1; // FSM play state
    parameter FINAL = 2; // FSM final state
    /* Note that output ports can be either reg or wire. 
       It depends on how you design your module. */
    // add your design here
    wire [3:0] lfsr_out;
    lfsr9_custom u_lfsr (
        .clk(clk_div),
        .rst(rst),     
        .shift_en(down_op),
        .lfsr(lfsr_out)
    );

    reg [3:0] password;  // stores password
    reg [2:0] input_count; // track number of bits entered


    always @(posedge clk_div or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            password <= 4'b1001;
            num <= 4'b0000;
            out <= 2'b00;
            LED <= 4'b1001;
            input_count <= 0;
        end else begin
            state <= next_state;

            case (state)

                IDLE: begin
                    LED <= lfsr_out;
                    password <= lfsr_out;
                    out <= 2'b00;
                    num <= 4'b0000;
                    input_count <= 0;
                end


                PLAY: begin
                    LED[3:0] <= password; 
                    if (down_op) begin
                        num <= 4'b0000;
                        input_count <= 0;
                    end else if (input_count < 4) begin
                        if (left_op) begin // input '1'
                            num <= {num[2:0], 1'b1};
                            input_count <= input_count + 1;
                        end else if (right_op) begin // input '0'
                            num <= {num[2:0], 1'b0};
                            input_count <= input_count + 1;
                        end
                    end
                    // check password match
                    if (input_count == 4 && num == password) begin
                        out <= 2'b11;
                    end else begin
                        out <= 2'b00;
                    end
                end

                FINAL: begin
                    num <= 4'b0000;
                    out <= 2'b11;
                    LED <= password; 
                    if (up_op) begin
                        LED <= 4'b1001; 
                    end
                end
            endcase
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (up_op) next_state = PLAY;
            PLAY: if (input_count == 4 && num == password) next_state = FINAL;
            FINAL: if (up_op) next_state = IDLE;
        endcase
    end



endmodule


