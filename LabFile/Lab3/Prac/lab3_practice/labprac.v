module lab3_practice (
    input wire clk,
    input wire rst,
    input wire slow,
    input wire fast,
    input wire end_light,
    output reg [15:0] led // change led here
);

  // state design
  // FSM
  localparam [1:0] INITIAL = 2'b00,
                   PLAY    = 2'b01,
                   FINAL   = 2'b10;

  // state reg
  // because we need to reassign the state => reg
  reg [1:0] state, next_state; // need eatra reg to store the transform of the reg

  // clock driver trigger
  // because the clock need to be trigger anytime => wire
  wire slow_clk, fast_clk;
  // add count HW here 
  //{HW name} {#(.n()) reassign parametr} {the insert hw name <= you can decided it for yourself}{.clk(), .clk_div() assign wire here}
  clock_divider #(.n(28)) div_slow(
      .clk(clk),
      .clk_div(slow_clk)
  );
  clock_divider #(.n(27)) div_fast(
      .clk(clk),
      .clk_div(fast_clk)
  );

  // count final state
  reg[28:0]counter; // because we need to count as 100000000 ~ 2^27 (2^10 = 1024)
  // use extra reg to store the flash signel to trigger the state change
  reg flash; // flash led
  integer flash_time; // count the time of flash
  always @(posedge clk) begin
      if(state == 2'b10) begin // only count when in final state
          if(counter < 100000000 - 1) begin // count to 1 sec
              counter <= counter + 1;
          end
          // else, counter == 100000000
          else begin
              counter <= 0; // reset counter
              flash <= !flash; // change flash signal to let led flash
              flash_time <= flash_time + 1; // count the time of flash // achieve 5 sec
          end
      end
      // not in final state
      else begin
          flash <= 1; // reset flash signal
          flash_time <= 0; // reset flash time
      end
  end

  // store the LED val
  // use always to set value => reg
  reg [15:0] tmp;
  // change the LED signel
  always @(*) begin
    // change by state
    case(state)
      INITIAL: begin
        led = 16'hFFFF;
      end

      PLAY: begin
        led = 16'h0000; // all off
        if (slow) 
            led = led | (slow_clk ? 16'h5555 : 16'h0000); // even LEDs
        if (fast) 
            led = led | (fast_clk ? 16'hAAAA : 16'h0000); // odd LEDs
      end

      FINAL: begin
        led = (flash) ? 16'hFFFF : 16'h0000; // flash led
      end

      default:begin
        led = 16'h0000;
      end

    endcase
  end


  // FSM next state logic
  // because we need to use singel to reassign the next_state => use *
  always @(*) begin
      case (state)
          INITIAL: next_state = PLAY;
          
          PLAY:    next_state = (end_light) ? FINAL : PLAY;
          
          FINAL:   next_state = (flash_time == 3'd5) ? INITIAL : FINAL;

          default: next_state = INITIAL;
      endcase
  end

  // FSM sequential
  // let the state change at posedge clk or rst
  always @(posedge clk or posedge rst) begin
      if (rst) 
          state <= INITIAL;
      else 
          state <= next_state;
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