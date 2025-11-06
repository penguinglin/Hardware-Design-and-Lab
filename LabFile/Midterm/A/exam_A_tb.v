`timescale 10ps / 1ps
`define CYCLE 10
`define WIDTH 4
`define PATTERN_NUM 100
`define FIRST_PATTEN
`define LAST_PATTEN
`define SIM_TIME 10250 // 250 + `PATTERN_NUM * 10 * 10
`define TOTAL_SCORE 30
`define FUN1_SCORE 7
`define FUN2_SCORE 7
`define FUN3_SCORE 8
`define FUN4_SCORE 8

module exam_A_tb;
    reg clk = 1'b1;
    reg rst = 1'b0;
    reg [1:0] op, last_op;
    reg [`WIDTH-1:0] A, B, C, last_A, last_B, last_C;
    wire [`WIDTH-1:0] out;

    reg [`WIDTH-1:0] ans, last_ans;
    reg [17:0] pattern_mem [0:`PATTERN_NUM-1];
    reg [3:0] fun_pass;
    reg feed_done;
    integer feed_i, fetch_i;
    
    exam_A ALU(
        .clk(clk),
        .rst(rst),
        .op(op),
        .A(A),
        .B(B),
        .C(C),
        .out(out)
    );

    // Clock
    always #(`CYCLE/2) clk = ~clk;
    
    // Reset
    initial begin
        @(negedge clk)
        rst = 1'b1;
        @(negedge clk)
        rst = 1'b0;
    end
    
    // Pattern feeding
    initial begin
        $readmemb("testcase_A.dat", pattern_mem);
        if(pattern_mem[0] === 18'bxxxxxxxxxxxxxxxxxx) begin
            $display("<ERROR> Can not find testcase_A.dat, make sure you have added it to simulation source!");
            $finish;
        end
        else begin
            $display("(test) Pattern 0: %b", pattern_mem[0]);
            $display("(test) Pattern 99: %b", pattern_mem[99]);
        end

        feed_done = 1'b0;
        op = 2'bzz; A = 4'bzzzz; B = 4'bzzzz; C = 4'bzzzz; ans = 4'bzzzz;
        wait(rst == 1'b1);
        wait(rst == 1'b0);
        for (feed_i = 0; feed_i < `PATTERN_NUM; feed_i = feed_i + 1) begin
            {last_op, last_A, last_B, last_C, last_ans} = {op, A, B, C, ans};
            {op, A, B, C, ans} = pattern_mem[feed_i][17:0];
            @(negedge clk);
        end
        {last_op, last_A, last_B, last_C, last_ans} = {op, A, B, C, ans};
        op = 2'bzz; A = 4'bzzzz; B = 4'bzzzz; C = 4'bzzzz; ans = 4'bzzzz;
        feed_done = 1'b1;
        @(negedge clk);
        last_op = 2'bzz; last_A = 4'bzzzz; last_B = 4'bzzzz; last_C = 4'bzzzz; last_ans = 4'bzzzz;
    end
    
    // Result checking
    initial begin
        fun_pass = 4'b1111; // all ops pass by default
        wait(rst == 1'b1);
        wait(rst == 1'b0);
        @(negedge clk);     // wait 1 cycle for valid result

        for (fetch_i = 0; fetch_i < `PATTERN_NUM; fetch_i = fetch_i + 1) begin
            @(posedge clk);
            if (out !== last_ans) begin
                $display("<ERROR> [pattern %0d]: op=%b A=%b B=%b C=%b => out=%b (ans %b)", fetch_i, last_op, last_A, last_B, last_C, out, last_ans);
                fun_pass[last_op] = 1'b0;
            end 
        end

        $display("\n=== Summary ===");
        if (fun_pass[0]) begin
            $display("Function 1: PASS");
        end else $display("Function 1: FAIL");
        if (fun_pass[1]) begin
            $display("Function 2: PASS");
        end else $display("Function 2: FAIL");
        if (fun_pass[2]) begin
            $display("Function 3: PASS");
        end else $display("Function 3: FAIL");
        if (fun_pass[3]) begin
            $display("Function 4: PASS");
        end else $display("Function 4: FAIL");
        
        if (!feed_done)
            $display("<ERROR> Simulation time is not enough, please add it to %0d ps", `SIM_TIME);

        $finish;
    end
endmodule
