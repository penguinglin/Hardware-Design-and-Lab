`timescale 10ps / 1ps
`define CYCLE 10
`define PATTERN_NUM 100
`define FIRST_PATTEN
`define LAST_PATTEN
`define SIM_TIME 10150 // 150 + `PATTERN_NUM * 10 * 10
`define TOTAL_SCORE 20
`define LFSR_SCORE 5
`define FSM_SCORE 15

module exam_B_tb;
    reg clk = 1'b1;
    reg rst = 1'b0;
    reg [3:0] seed = 4'b1100;
    wire [3:0] random;
    wire seq, dec;
    
    reg [1:0] pattern_mem [0:`PATTERN_NUM-1];
    reg seq_ans, dec_ans;
    reg [1:0] pass;
    reg feed_done;
    integer feed_i, fetch_i;
    
    exam_B seq_dec(
        .clk(clk),
        .rst(rst),
        .seed(seed),
        .random(random),
        .seq(seq),
        .dec(dec)
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
        $readmemb("testcase_B.dat", pattern_mem);
        if(pattern_mem[0] === 2'bxx) begin
            $display("<ERROR> Can not find testcase_B.dat, make sure you have added it to simulation source!");
            $finish;
        end
        else begin
            $display("(test) Pattern 0: %b", pattern_mem[0]);
            $display("(test) Pattern 99: %b", pattern_mem[99]);
        end
        feed_done = 1'b0;
        seq_ans = 1'bz; dec_ans = 1'bz;
        wait(rst == 1'b1);
        for (feed_i = 0; feed_i < `PATTERN_NUM; feed_i = feed_i + 1) begin
            @(posedge clk);
            {seq_ans, dec_ans} = pattern_mem[feed_i][17:0];
        end
        feed_done = 1'b1;
    end
    
    // Result checking
    initial begin
        pass = 2'b11;       // pass by default
        wait(rst == 1'b1);
        wait(rst == 1'b0);

        for (fetch_i = 0; fetch_i < `PATTERN_NUM; fetch_i = fetch_i + 1) begin
            if (seq !== seq_ans) begin
                $display("<ERROR> [pattern %0d]: seq=%b (ans %b) => dec=%b (ans %b)", fetch_i, seq, seq_ans, dec, dec_ans);
                pass[1] = 1'b0;
            end 
            if (dec !== dec_ans) begin
                $display("<ERROR> [pattern %0d]: seq=%b (ans %b) => dec=%b (ans %b)", fetch_i, seq, seq_ans, dec, dec_ans);
                pass[0] = 1'b0;
            end 
            
            @(negedge clk);
        end

        $display("\n=== Summary ===");
        if (pass[1]) begin
            $display("LFSR: PASS");
        end 
        else $display("LFSR: FAIL");
        
        if (pass[0]) begin
            $display("FSM: PASS");
        end 
        else $display("FSM: FAIL");
        
        if (!feed_done)
            $display("<ERROR> Simulation time is not enough, please add it to %0d ps", `SIM_TIME);

        $finish;
    end
endmodule