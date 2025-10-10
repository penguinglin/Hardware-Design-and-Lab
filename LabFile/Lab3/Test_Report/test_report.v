`timescale 1ns/1ps

//===========================================================
//  One Pulse Demonstration
//===========================================================
module one_pulse_demo (
    input wire clk_fsm,
    input wire clk_fast,
    input wire clk_slow,
    input wire btn_raw,
    output reg fsm_trigger_correct,
    output reg fsm_trigger_fast,
    output reg fsm_trigger_slow
);
    // Debounce 模擬：直接延遲一下 (簡化)
    reg btn_debounced;
    always @(posedge clk_fsm) begin
        btn_debounced <= btn_raw;
    end

    //=============================
    // Case 1: 正確 one pulse (同時脈)
    //=============================
    reg btn_d1;
    wire pulse_correct;
    always @(posedge clk_fsm) btn_d1 <= btn_debounced;
    assign pulse_correct = btn_debounced & ~btn_d1;

    always @(posedge clk_fsm)
        if (pulse_correct)
            fsm_trigger_correct <= 1'b1;
        else
            fsm_trigger_correct <= 1'b0;

    //=============================
    // Case 2: One pulse 過快 (fast clock)
    //=============================
    reg btn_d2;
    wire pulse_fast;
    always @(posedge clk_fast) btn_d2 <= btn_debounced;
    assign pulse_fast = btn_debounced & ~btn_d2;

    always @(posedge clk_fsm)
        if (pulse_fast)
            fsm_trigger_fast <= 1'b1;
        else
            fsm_trigger_fast <= 1'b0;

    //=============================
    // Case 3: One pulse 過慢 (slow clock)
    //=============================
    reg btn_d3;
    wire pulse_slow;
    always @(posedge clk_slow) btn_d3 <= btn_debounced;
    assign pulse_slow = btn_debounced & ~btn_d3;

    always @(posedge clk_fsm)
        if (pulse_slow)
            fsm_trigger_slow <= 1'b1;
        else
            fsm_trigger_slow <= 1'b0;
endmodule


//===========================================================
//  Testbench
//===========================================================
module tb_one_pulse_demo;
    reg clk_fsm = 0;
    reg clk_fast = 0;
    reg clk_slow = 0;
    reg btn_raw = 0;

    wire fsm_trigger_correct;
    wire fsm_trigger_fast;
    wire fsm_trigger_slow;

    // Instantiate DUT
    one_pulse_demo uut (
        .clk_fsm(clk_fsm),
        .clk_fast(clk_fast),
        .clk_slow(clk_slow),
        .btn_raw(btn_raw),
        .fsm_trigger_correct(fsm_trigger_correct),
        .fsm_trigger_fast(fsm_trigger_fast),
        .fsm_trigger_slow(fsm_trigger_slow)
    );

    // Clock generation
    always #10 clk_fsm = ~clk_fsm;  // FSM clock = 50 MHz
    always #5  clk_fast = ~clk_fast; // Fast clock = 100 MHz
    always #20 clk_slow = ~clk_slow; // Slow clock = 25 MHz

    // Stimulus
    initial begin
        $dumpfile("one_pulse_demo.vcd");
        $dumpvars(0, tb_one_pulse_demo);

        btn_raw = 0;
        #50;

        // 第一次按下（長按）
        btn_raw = 1; #100;
        btn_raw = 0; #200;

        // 第二次（短按）
        btn_raw = 1; #50;
        btn_raw = 0; #150;

        // 第三次（長按）
        btn_raw = 1; #120;
        btn_raw = 0; #180;

        // 第四次（非常短按）
        btn_raw = 1; #30;
        btn_raw = 0; #150;

        // 第五次（長按）
        btn_raw = 1; #200;
        btn_raw = 0; #200;

        // 第六次（短按）
        btn_raw = 1; #60;
        btn_raw = 0; #300;

        // 結束模擬
        #1000;
        $finish;
    end
endmodule
