`timescale 10ps/1ps

`define PATTERN_NUM 30
`define CYCLE 10
module lab2_2_tb;

    reg clk, rst;
    reg signed [7:0] A, B ;
    reg signed [7:0] last1_A,last2_A,last3_A;
    reg signed [7:0] last1_B,last2_B,last3_B;
    reg impulse,last1_impulse,last2_impulse,last3_impulse;
    reg signed [15:0] answer1,last1_answer1,last2_answer1,last3_answer1;
    reg  [7:0] answer2,last1_answer2,last2_answer2,last3_answer2;
    wire signed [15:0] OUT1;
    wire  [7:0] OUT2;
    reg [40:0] mem[0:`PATTERN_NUM-1+2];
    reg pass, feed_finish;

    integer feed_i, fetch_i, scores,out1_score,out2_score;
    
    initial begin
        clk = 1'b0;
        while(1) #(`CYCLE/2) clk = ~clk;
    end
    
    lab2_2 sum(
        .clk(clk),
        .rst(rst),
        .impulse(impulse),
        .A(A),
        .B(B),
        .OUT1(OUT1),
        .OUT2(OUT2)
    );

    initial begin
        // input feeding init
        $readmemb("pattern_B.dat", mem);

        if(mem[1] !== 41'b1_01001011_00100111_0100101100100111_01101101) begin
            $display(">>>>>>>>>>> [ERROR] Can not find pattern_B.dat, make sure you have added it to simulation source!");
            $finish;
        end
        
        out1_score = 30;
        out2_score = 30;
        pass = 1'b1;
  
        feed_finish = 1'b0;

        #(`CYCLE*10);
        //A = {`WIDTH{1'bz}};
        //B = {`WIDTH{1'bz}};
        rst = 1'b1;
        #(`CYCLE*10);
        rst = 1'b0;

        // Feed addition input
        for(feed_i = 0; feed_i < `PATTERN_NUM + 3; feed_i = feed_i+1) begin
            @(posedge clk);
            #1; 
            {last3_impulse ,last3_A, last3_B, last3_answer1,last3_answer2} = {last2_impulse ,last2_A, last2_B, last2_answer1,last2_answer2}; 
            {last2_impulse ,last2_A, last2_B, last2_answer1,last2_answer2} = {last1_impulse ,last1_A, last1_B, last1_answer1,last1_answer2}; 
            {last1_impulse ,last1_A, last1_B, last1_answer1,last1_answer2} = {impulse ,A, B, answer1,answer2}; 
            {impulse ,A, B, answer1,answer2} = mem[feed_i][40:0];
            
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
        @(negedge clk);
        for(fetch_i = 0; fetch_i < `PATTERN_NUM; fetch_i = fetch_i+1) begin
            @(negedge clk);
           
            if(OUT1 !== last1_answer1 || OUT2 !== last3_answer2) begin
                if(OUT1 !== last1_answer1)begin
                    $display("<ERROR> [check %0d] last1_impulse=%0d, last1_A=%0d, last1_B=%0d, your_out1=%0d,correct_out1=%0d ", fetch_i,last1_impulse, last1_A, last1_B, OUT1, last1_answer1);
                    out1_score = out1_score - 1;
                end
                if(OUT2 !== last3_answer2)begin
                    $display("<ERROR> [check %0d] last3_impulse=%0d,last3_A=%0d, last3_B=%0d, your_out2=%0d, correct_out2=%0d", fetch_i,last3_impulse, last3_A, last3_B, OUT2, last3_answer2);
                    out2_score = out2_score - 1;
                end
                pass = 1'b0;
            end
            else begin
                
               
            end
        end 

        #(`CYCLE*20);
        

        // Check 
        if(pass) begin
            $display("OUT1 :  %0d / 30", out1_score);
            $display("OUT2 :  %0d / 30", out2_score);
            $display("scores =  %0d / 60", out1_score + out2_score);
            $display("PASS!");
        end
        else begin
            $display("OUT1 :  %0d / 30", out1_score);
            $display("OUT2 :  %0d / 30", out2_score);
            $display("scores =  %0d / 60", out1_score + out2_score);
            $display("FAIL!");
        end

      

        $finish;
    end

endmodule