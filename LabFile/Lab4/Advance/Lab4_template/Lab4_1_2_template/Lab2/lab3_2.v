module lab4_2 (
  input wire clk,
  input wire rst,
  input wire set, 
  inout wire PS2_DATA,
  inout wire PS2_CLK,
  output wire [15:0] LED,
  output wire [3:0] digit,
  output wire [6:0] display
);

  // -----------------------------
  // Clock divider
  // -----------------------------
  wire clk_1s;
  wire done_3s, done_5s;
  reg [2:0] state, next_state;
  
  GameTimer timer(
      .clk(clk),
      .rst(rst),
      .clk_1s(clk_1s),
      .state(state),
      .done_3s(done_3s),
      .done_5s(done_5s)
  );
  // display override buffer
  reg [15:0] display_mux_num;
  reg display_override; // 1 -> show display_mux_num, 0 -> show num_wire  
  // LED override buffer
  reg [15:0] led_mux_num;
  reg led_override; // 1 -> show led_mux_num, 0 -> show led_wire
  


  // -----------------------------
  // FSM State Definition
  // -----------------------------
  localparam S_INIT        = 3'b000;
  localparam S_SET         = 3'b001;
  localparam S_GUESS       = 3'b010;
  localparam S_RESULT      = 3'b011;
  localparam S_FINAL       = 3'b100;
  reg set_flag, guest_flag;
  wire kb_init_request;
  assign kb_init_request = (state == S_SET && set_flag) || (state == S_GUESS && guest_flag);


  // -----------------------------
  // Game data registers
  // -----------------------------
  reg [15:0] secret_num;  
  reg [15:0] guess_num; 
  reg [1:0] sel_pos;   
  wire [3:0] A_wire, B_wire;     
  reg [3:0] A, B;

  // -----------------------------
  // Keyboard Control wires
  // -----------------------------
  wire [15:0] num_wire;
  wire submit;
  wire [15:0] led_wire;

  // -----------------------------
  // Instantiate KeyboardControl
  // -----------------------------
  KeyboardControl kb(
      .clk(clk),
      .rst(rst),
      .PS2_DATA(PS2_DATA),
      .PS2_CLK(PS2_CLK),
      .state_init_request(kb_init_request), 
      .num(num_wire),
      .LED(led_wire),
      .submit(submit),
      .led_en((state==S_SET)||(state==S_GUESS)),
      .segment_en((state==S_SET)||(state==S_GUESS))
  );
  reg submit_d; // Submit signal delayed by one clock cycle
  wire submit_pulse; // Single-cycle pulse on submit rising edge
  assign submit_pulse = submit & ~submit_d;

  // Capture the previous state of submit (Sequential)
  always @(posedge clk or posedge rst) begin
      if (rst)
          submit_d <= 1'b0;
      else
          submit_d <= submit;
  end
  

  // -----------------------------
  // Instantiate SevenSegment
  // -----------------------------
  // decide which num goes to display
  wire [15:0] display_source_num;
  assign display_source_num = display_override ? display_mux_num : num_wire;
  assign LED = led_override ? led_mux_num : led_wire;

  // SevenSegment instance: feed display_source_num
  SevenSegment seven_seg(
      .clk(clk),
      .rst(rst),
      .nums(display_source_num), 
      .digit(digit),
      .display(display)
  );


  // -----------------------------
  // FSM Sequential
  // -----------------------------
  always @(posedge clk or posedge rst) begin
      if (rst)
          state <= S_INIT;
      else
          state <= next_state;
  end

  // -----------------------------
  // Compare Unit
  // -----------------------------
  wire is_correct;
  CompareUnit cmp(
      .secret(secret_num),
      .guess(guess_num),
      .A(A_wire),
      .B(B_wire),
      .is_correct(is_correct)
  );

  // -----------------------------
  // FSM Combinational: Transition
  // -----------------------------
  always @(*) begin
    next_state = state;
    case(state)
        S_INIT:   if(set) next_state = S_SET;
        S_SET:    if(submit_pulse) next_state = S_GUESS;
        S_GUESS:  if(submit_pulse) next_state = is_correct ? S_FINAL : S_RESULT;
        S_RESULT: if (done_3s) next_state = S_GUESS;
        S_FINAL:  if (done_5s) next_state = S_INIT;
    endcase
  end

  always @(posedge clk or posedge rst) begin
    if(rst) begin
        A <= 0;
        B <= 0;
    end else begin
        A <= A_wire;
        B <= B_wire;
    end
end

  // -----------------------------
  // FSM Sequential: Output & Behavior
  // -----------------------------
  
  always @(posedge clk or posedge rst) begin
      if(rst) begin
          sel_pos <= 0;
          display_override <= 0;
          display_mux_num <= 16'hCCCC;
          set_flag <= 1;
          guest_flag <= 1;
          secret_num <= 16'b0;
          guess_num <= 16'b0;
          led_mux_num <= 16'b0;
          led_override <= 0;
      end else begin
          case(state)
              S_INIT: begin
                  display_mux_num <= 16'hCCCC;
                  display_override <= 1'b1;
                  set_flag <= 1;
                  guest_flag <= 1;
                  secret_num <= 16'b0;
                  guess_num <= 16'b0;
                  led_mux_num <= 16'b0;
                  led_override <= 1;
              end
              S_SET, S_GUESS: begin
                  display_override <= 1'b0;
                  led_override <= 1'b0;
                  if(set_flag && (state==S_SET)) begin
                      set_flag <= 0;
                      secret_num <= 16'b0;
                  end else if(set_flag == 0 && (state==S_SET)) begin
                    secret_num <= num_wire;
                  end

                  if(guest_flag && (state==S_GUESS)) begin
                      guest_flag <= 0;
                      guess_num <= 16'b0;
                  end else if(guest_flag ==0 && (state==S_GUESS)) begin
                    guess_num <= num_wire;
                  end
              end
              S_RESULT: begin
                  display_mux_num <= { A_wire, 4'd10, B_wire, 4'd11 };
                  display_override <= 1'b1;
                  guest_flag <= 1;
                  led_mux_num <= 16'b0; 
                  led_override <= 1'b1;
              end
              S_FINAL: begin
                  display_mux_num <= { 4'd4, 4'd10, 4'd0, 4'd11 };
                  led_mux_num <= clk_1s ? 16'h0000 : 16'hFFFF;
                  display_override <= 1'b1;
                  led_override <= 1'b1;
                  guest_flag <= 1;
                  set_flag <= 1;
              end
          endcase
      end
  end

endmodule
