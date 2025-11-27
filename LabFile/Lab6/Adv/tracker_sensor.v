module tracker_sensor(clk, reset, left_track, right_track, mid_track, state);
    input clk;
    input reset;
    input left_track, right_track, mid_track;
    output reg [2:0] state;

    // TODO: Receive three tracks and create your own policy.
    // Hint: You can use output state to change your action.
    wire [2:0]now_detect;
    assign now_detect={left_track, mid_track, right_track};
    always @(posedge clk, posedge reset) begin
        if(reset) state <= 3'b111;
        else begin
            case(now_detect)
                3'b101: state <= 3'b010;
                3'b011, 3'b001: state <= 3'b100;
                3'b110, 3'b100: state <= 3'b001;
                default: state <= state;
            endcase
        end        
    end

endmodule
