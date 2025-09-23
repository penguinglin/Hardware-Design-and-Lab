`timescale 10ps/1ps

`define WIDTH 8
`define DELAY 10
`define PATTERN_NUM 40
`define CYCLE 10
module lab2_1_tb;
    
    reg clk, rst;
    reg signed [`WIDTH-1:0] A, B, last_A, last_B;
    wire [1:0] out;

    reg [1:0] ans, last_ans;
    reg [17:0] mem [0 : `PATTERN_NUM-1 ];
    reg pass, feed_finish;

    integer feed_i, fetch_i;
    // integer file;
    integer scores;
    

    initial begin
        clk = 1'b0;
        while(1) #(`CYCLE/2) clk = ~clk;
    end
    lab2_1 sign_bit_detector(
        .clk(clk),
        .rst(rst),
        .A(A),
        .B(B),
        .out(out)
    );
   
    integer  a=0;
    integer  b=0;
    integer  c=0;
    integer  d=0;
    initial begin
        // input feeding init
        
        scores = 0;
        $readmemb("pattern_A.dat", mem);

        if(mem[1] !== 18'b00000000_11111011_00) begin
            $display(">>>>>>>>>>> [ERROR] Can not find pattern_A.dat, make sure you have added it to simulation source!");
            $finish;
        end
        
        pass = 1'b1;
  
        feed_finish = 1'b0;

        #(`CYCLE*10);
        A = {`WIDTH{1'bz}};
        B = {`WIDTH{1'bz}};
        rst = 1'b1;
        #(`CYCLE*10);
        rst = 1'b0;

        // Feed addition input
        for(feed_i = 0; feed_i < `PATTERN_NUM + 1; feed_i = feed_i+1) begin
            @(posedge clk);
            #1;
            {last_A, last_B, last_ans} = {A, B, ans}; 
            {A, B, ans} = mem[feed_i][17:0];
            
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
                if(out==1)begin
                    a=a+1;
                end
                else if(out==2)begin
                    b=b+1;
                end
                else if(out==3)begin
                    c=c+1;
                end
                else if(out==0)begin
                    d=d+1;
                end
                scores = scores + 1;
            end
        end 

        #(`CYCLE*20);
        

        // Scores
        if(pass) begin
            
            $display("Both positive :  %0d / 7", a);
            $display("Both negative :  %0d / 7", b);
            $display("Different signs :  %0d / 14", c);
            $display("At least one is zero :  %0d / 12", d);
            $display("scores =  %0d / 40", scores);
            $display("PASS!");
            
        end
        else begin
            $display("Both positive :  %0d / 7", a);
            $display("Both negative :  %0d / 7", b);
            $display("Different signs :  %0d / 14", c);
            $display("At least one is zero :  %0d / 12", d);
            $display("scores =  %0d / 40", scores);
            $display("FAIL!");
        end

      

        $finish;
    end

endmodule