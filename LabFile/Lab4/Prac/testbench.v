`timescale 1ns/1ps
module tb_lab4_Practice;

    reg clk;
    reg rst;
    reg next;
    reg shift;
    wire [1:0] state;
    wire [8:0] LED;

    lab4_Practice dut (
        .clk(clk),
        .rst(rst),
        .next(next),
        .shift(shift),
        .state(state),
        .LED(LED)
    );

    initial clk = 0;
    always #5 clk = ~clk; // 10ns clock

    integer i; // 在 initial 外面宣告

    initial begin
        rst = 0; next = 0; shift = 0;

        // Reset
        #10 rst = 1; #50 rst = 0; #50;
        $display("Simulation start: state=%b, LED=%b", state, LED);

        // FSM traversal loop
        for (i = 0; i < 200; i = i + 1) begin
            // Shift LFSR
            #10 shift = 1; #50 shift = 0; #50;

            // Press next every time
            #10 next = 1; #50 next = 0; #50;

            // 等待下一個 clk 上升緣，確保 FSM 更新
            @(posedge clk);

            // 每次按下 next 都顯示
            $display("Time=%0t | After next pressed | state=%b, LED=%b, LED[0]=%b",
                      $time, state, LED, LED[0]);
        end

        $display("Simulation finished.");
        $stop;
    end

endmodule
