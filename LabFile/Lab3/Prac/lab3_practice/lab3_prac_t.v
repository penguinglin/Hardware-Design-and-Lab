`timescale 1ns/1ps

module tb_lab3_practice;

    // Testbench signals
    reg clk;
    reg rst;
    reg slow;
    reg fast;
    reg end_light;
    wire [15:0] led;

    // Instantiate DUT
    lab3_practice uut (
        .clk(clk),
        .rst(rst),
        .slow(slow),
        .fast(fast),
        .end_light(end_light),
        .led(led)
    );

    // Clock generator (10ns period = 100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  
    end

    // Stimulus
    initial begin
        // 初始化
        rst = 1; slow = 0; fast = 0; end_light = 0;
        #50;            // 保持 reset 一段時間
        rst = 0;        // 放掉 reset，進入 INITIAL -> PLAY

        // 測試 slow mode
        slow = 1; fast = 0;
        #500;           

        // 測試 fast mode
        slow = 0; fast = 1;
        #500;

        // 測試 slow + fast 同時
        slow = 1; fast = 1;
        #500;

        // 觸發 FINAL state
        end_light = 1;
        #20;
        end_light = 0;

        // FINAL 持續 6 秒 (6 個 sec_clk 週期，應該會回到 INITIAL)
        #6000000000;   // (模擬時間太長可以縮小 clock_divider n 值)

        $stop; // 結束模擬
    end

    // Dump VCD for waveform (if using GTKWave)
    initial begin
        $dumpfile("lab3_wave.vcd");
        $dumpvars(0, tb_lab3_practice);
    end

    // 即時監控輸出
    initial begin
        $monitor("t=%0t rst=%b state=%b slow=%b fast=%b end=%b led=%h",
                 $time, rst, uut.state, slow, fast, end_light, led);
    end

endmodule
