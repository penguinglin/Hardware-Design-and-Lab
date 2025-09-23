`timescale 10ps/1ps

`define WIDTH 8
`define DELAY 10
`define PATTERN_NUM 40
`define CYCLE 10
module lab2_1_practice_tb;
    
    reg clk, rst;
    reg signed [`WIDTH-1:0] A, B, last_A, last_B;
    wire signed [11:0] out;

    reg signed [11:0] ans, last_ans;
    reg [27:0] mem [0 : `PATTERN_NUM-1 ];
    reg pass, feed_finish;

    integer feed_i, fetch_i;
    // integer file;
    integer scores;

    initial begin
        clk = 1'b0;
        while(1) #(`CYCLE/2) clk = ~clk;
    end
    lab2_1_practice adder(
        .clk(clk),
        .rst(rst),
        .A(A),
        .B(B),
        .out(out)
    );
   
    
    initial begin
        // input feeding init
        $readmemb("pattern_A_practice.dat", mem);
        if(mem[1] !== 28'b11111111_00000001_000000000000) begin
            $display(">>>>>>>>>>> [ERROR] Can not find pattern_A_practice.dat, make sure you have added it to simulation source!");
            $finish;
        end

        scores = 0;
        pass = 1'b1;
  
        feed_finish = 1'b0;

        #(`CYCLE*10);
        A = {`WIDTH{1'bz}};
        B = {`WIDTH{1'bz}};
        rst = 1'b1;
        #(`CYCLE*10);
        rst = 1'b0;

        // Feed addition input
        for(feed_i = 0; feed_i < `PATTERN_NUM+1; feed_i = feed_i+1) begin
            @(posedge clk);
            #1;
            {last_A, last_B, last_ans} = {A, B, ans}; 
            {A, B, ans} = mem[feed_i][27:0];
            
        end 
        feed_finish = 1'b1;

        // Input feeding stop
        #(`CYCLE*10);
        A = {`WIDTH{1'bz}};
        B = {`WIDTH{1'bz}};
    end

    initial begin
        wait(rst == 1'b1);
        wait(rst == 1'b0);
        
        // Check your design
        @(negedge clk);
        for(fetch_i = 0; fetch_i < `PATTERN_NUM; fetch_i = fetch_i+1) begin
            @(negedge clk);
            
            if(out !== last_ans) begin
                $display("<ERROR> [pattern %0d] A=%d, B=%d, out=%d, ans=%d", fetch_i, last_A, last_B, out, last_ans);
                pass = 1'b0;
            end
            else begin
                scores = scores + 1;
            end
        end 

        #(`CYCLE*20);
        

        // Check function 1
        if(pass) begin
            $display("scores =  %0d / 40", scores);
            $display("PASS!");
        end
        else begin
            $display("scores =  %0d / 40", scores);
            $display("FAIL!");
        end

        // Check function 2
        
      

        $finish;
    end

endmodule