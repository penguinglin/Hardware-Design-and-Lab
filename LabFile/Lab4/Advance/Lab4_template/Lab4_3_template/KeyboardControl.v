module KeyboardControl(
    input wire clk,
    input wire rst,
    inout wire PS2_DATA,
    inout wire PS2_CLK,
    input wire state_init_request, // 來自 main module，表示在guess且需要初始化顯示
    input wire stateIsGuess,       // 來自 main module，表示目前是否在guess狀態
    output wire [15:0] num,
    output reg [8:0] LED,
    output reg [2:0] volume,       // W increase, S decrease
    output reg submit,             // Enter 鍵觸發
    output reg RST,                // R 鍵觸發
    output wire [8:0] lfsr_transfer_ready // LFSR 狀態
);

    // -----------------------------
    // Keyboard Decoder Signals
    // -----------------------------
    wire [511:0] key_down;  
    wire [8:0] last_change; 
    wire been_ready;         
    
    // -----------------------------
    // 內部狀態與輸入緩衝
    // -----------------------------
    reg [3:0] BCD1, BCD2, BCD3, BCD4;
    assign num = {BCD4, BCD3, BCD2, BCD1}; 

    reg [1:0] input_state;     

    // -----------------------------
    // PS/2 Control (RST/Debounce/One-pulse for Decoder)
    // -----------------------------
    wire rst_in_debounced;   // rst_
    wire rst_processed;      // onepulse rst_processed

    KeyboardDecoder key_de (
        .key_down(key_down),
        .last_change(last_change),
        .key_valid(been_ready), 
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(rst_in_debounced), 
        .clk(clk)
    );
    
    debounce rst1(
        .clk(clk),
        .pb(rst),
        .pb_debounced(rst_in_debounced)
    );
    
    onepulse rst2(
        .clk(clk),
        .signal(rst_in_debounced),
        .op(rst_processed)
    );

    // -----------------------------
    // Key Codes
    // -----------------------------
    parameter SCAN_C = 9'h21;
    parameter SCAN_D = 9'h23;
    parameter SCAN_E = 9'h24;
    parameter SCAN_F = 9'h29;
    parameter SCAN_G = 9'h34;
    parameter SCAN_A = 9'h1C;
    parameter SCAN_B = 9'h32;

    parameter SCAN_4 = 9'h25;
    parameter SCAN_5 = 9'h2E;
    parameter SCAN_NUM_4 = 9'h6B;
    parameter SCAN_NUM_5 = 9'h73;
    
    parameter SCAN_R = 9'h2D;
    parameter SCAN_W = 9'h1D;
    parameter SCAN_S = 9'h1B;
    parameter SCAN_N = 9'h31;
    parameter SCAN_ENTER = 9'h5A;
    parameter SCAN_BACKSPACE = 9'h66;

    // -----------------------------
    // Key Press Detection (One-pulse for R, Enter, Backspace, W, S)
    // -----------------------------
    wire key_press_n = been_ready && last_change == SCAN_N && key_down[SCAN_N];
    wire key_press_w = been_ready && last_change == SCAN_W && key_down[SCAN_W];
    wire key_press_s = been_ready && last_change == SCAN_S && key_down[SCAN_S];
    wire key_press_r = been_ready && last_change == SCAN_R && key_down[SCAN_R];
    wire key_press_enter = been_ready && last_change == SCAN_ENTER && key_down[SCAN_ENTER];
    wire key_press_backspace = been_ready && last_change == SCAN_BACKSPACE && key_down[SCAN_BACKSPACE];

    // -----------------------------
    // LFSR
    // -----------------------------
    wire [8:0] led_lfsr_out;
    wire lfsr_shift_en = state_init_request | key_press_n;
    
    lfsr9_custom led_lfsr (
        .clk(clk),
        .rst(rst),
        .shift_en(lfsr_shift_en),
        .lfsr(led_lfsr_out)
    );
    
    always @(*) begin
        LED = led_lfsr_out; 
    end

    

    // -----------------------------
    // Volume Control (Sequential)
    // -----------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            volume <= 3'd2;
        end else if (key_press_w) begin
            if (volume < 3'd3)
                volume <= volume + 1;
        end else if (key_press_s) begin
            if (volume > 3'd1)
                volume <= volume - 1;
        end
    end

    // -----------------------------
    // FSM Control Outputs (RST, Submit)
    // -----------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            RST <= 1'b0;
        else
            RST <= key_press_r;
    end

    always @(posedge clk or posedge rst) begin
        if (rst)
            submit <= 1'b0;
        else
            submit <= key_press_enter && input_state == 2'd2; 
    end

    // -----------------------------
    // Input Logic (Sequential)
    // -----------------------------
    always @(posedge clk or posedge rst) begin
        if (rst || state_init_request) begin
            input_state <= 2'd0;
            BCD1 <= 4'hF;
            BCD2 <= 4'hF;
        end else if (stateIsGuess && been_ready && key_down[last_change]) begin
            if (key_press_backspace) begin
                if (input_state == 2'd2) begin
                    input_state <= 2'd1;
                    BCD1 <= 4'hF;
                end else if (input_state == 2'd1) begin
                    input_state <= 2'd0;
                    BCD2 <= 4'hF;
                end
            end else begin 
                case (input_state)
                    2'd0: begin
                        case (last_change)
                            SCAN_C: {BCD2, input_state} <= {4'd0, 2'd1};
                            SCAN_D: {BCD2, input_state} <= {4'd1, 2'd1};
                            SCAN_E: {BCD2, input_state} <= {4'd2, 2'd1};
                            SCAN_F: {BCD2, input_state} <= {4'd3, 2'd1};
                            SCAN_G: {BCD2, input_state} <= {4'd4, 2'd1};
                            SCAN_A: {BCD2, input_state} <= {4'd5, 2'd1};
                            SCAN_B: {BCD2, input_state} <= {4'd6, 2'd1};
                            default: begin BCD2 <= BCD2; input_state <= input_state; end
                        endcase
                    end
                    2'd1: begin
                        case (last_change)
                            SCAN_4, SCAN_NUM_4: {BCD1, input_state} <= {4'd4, 2'd2};
                            SCAN_5, SCAN_NUM_5: {BCD1, input_state} <= {4'd5, 2'd2};
                            default: begin BCD1 <= BCD1; input_state <= input_state; end
                        endcase
                    end
                    default: ; 
                endcase
            end
        end
    end 

endmodule
