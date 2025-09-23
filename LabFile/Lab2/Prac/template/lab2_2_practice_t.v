`timescale 10ps/1ps

`define PATTERN_NUM 60
`define CYCLE 10
module lab2_2_practice_tb;

    reg clk, rst;
    reg signed [7:0] A, B ;
    reg signed [7:0] last1_A, last1_B;
    reg signed [7:0] last2_A, last2_B;
    reg signed [11:0] answer,last1_answer,last2_answer;
    wire signed [11:0] out;

    reg [27:0] mem[0:`PATTERN_NUM-1];
    reg pass, feed_finish;

    integer feed_i, fetch_i, scores;
    
    initial begin
        clk = 1'b0;
        while(1) #(`CYCLE/2) clk = ~clk;
    end
    
    lab2_2_practice sum(
        .clk(clk),
        .rst(rst),
        .A(A),
        .B(B),
        .out(out)
    );

    initial begin
        // input feeding init
        $readmemb("pattern_B_practice.dat", mem);

        if(mem[1] !== 28'b11011110_00000100_111111011010) begin
            $display(">>>>>>>>>>> [ERROR] Can not find pattern_B_practice.dat, make sure you have added it to simulation source!");
            $finish;
        end


        scores = 0;
        pass = 1'b1;
  
        feed_finish = 1'b0;

        #(`CYCLE*10);
       // A = {`WIDTH{1'bz}};
       // B = {`WIDTH{1'bz}};
        rst = 1'b1;
        #(`CYCLE*10);
        rst = 1'b0;

        // Feed addition input
        for(feed_i = 0; feed_i < `PATTERN_NUM + 2; feed_i = feed_i+1) begin
            @(posedge clk);
            #1; 
            {last2_A, last2_B, last2_answer} = {last1_A, last1_B, last1_answer}; 
            {last1_A, last1_B, last1_answer} = {A, B, answer}; 
            {A, B, answer} = mem[feed_i][27:0];
            
        end 
        feed_finish = 1'b1;

        // Input feeding stop
        #(`CYCLE*10);
        //A = {`WIDTH{1'bz}};
        //B = {`WIDTH{1'bz}};
    end

    initial begin
        wait(rst == 1'b1);
        wait(rst == 1'b0);
        
        // Check your design
        @(negedge clk);
        @(negedge clk);
        for(fetch_i = 0; fetch_i < `PATTERN_NUM; fetch_i = fetch_i+1) begin
            @(negedge clk);
            
            if(out !== last2_answer) begin
                $display("<ERROR> [pattern %0d] A=%d, B=%d, your_ans=%d, correct_ans=%d", fetch_i, last2_A, last2_B, out, last2_answer);
                pass = 1'b0;
            end
            else begin
                scores = scores + 1;
            end
        end 

        #(`CYCLE*20);
        

        // Check 
        if(pass) begin
            
            $display("scores =  %0d / 60", scores);
            $display("PASS!");
        end
        else begin
            $display("scores =  %0d / 60", scores);
            $display("FAIL!");
        end

      

        $finish;
    end

endmodule