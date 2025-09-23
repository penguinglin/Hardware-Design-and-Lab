`timescale 1ns/1ps

module lab2_adv_1_t;

    reg clk;
    reg rst;
    reg [8:0] clause_1, clause_2, clause_3, clause_4;
    wire [2:0] out;
    wire satisfaction;


    // Clock generation: 10 ns period
    initial clk = 1;
    always #5 clk = ~clk;

    //================================================
    // TODO1
    // Connect your lab2_adv_1 module here 
    // Please connect it by port name but not order
    lab2_adv_1 mod(
        .clk(clk),
        .rst(rst),
        .clause_1(clause_1),
        .clause_2(clause_2),
        .clause_3(clause_3),
        .clause_4(clause_4),
        .satisfaction(satisfaction),
        .out(out)
    );
    //================================================


    // TODO 2
    //you should test these 8 cases:
    //Test 0:
    //clause_1 = 9'b000_001_010;
    //clause_2 = 9'b100_101_110;
    //clause_3 = 9'b000_101_110;
    //clause_4 = 9'b100_001_010;

    //Test 1:
    //clause_1 = 9'b000_000_000;
    //clause_2 = 9'b100_100_100;
    //clause_3 = 9'b001_001_001;
    //clause_4 = 9'b101_101_101;

    //Test 2:
    //clause_1 = 9'b010_010_010;
    //clause_2 = 9'b110_110_110;
    //clause_3 = 9'b000_001_010;
    //clause_4 = 9'b100_101_110;

    //Test 3:
    //clause_1 = 9'b000_101_100; 
    //clause_2 = 9'b010_010_010;
    //clause_3 = 9'b100_101_010;
    //clause_4 = 9'b000_001_110;

    //Test 4:
    //clause_1 = 9'b000_101_110; 
    //clause_2 = 9'b100_001_010; 
    //clause_3 = 9'b001_110_000; 
    //clause_4 = 9'b101_010_100; 

    //Test 5:
    //clause_1 = 9'b000_000_000;
    //clause_2 = 9'b100_100_100;
    //clause_3 = 9'b001_001_001;
    //clause_4 = 9'b101_101_101;

    //Test 6:
    //clause_1 = 9'b010_001_000;
    //clause_2 = 9'b001_100_010; 
    //clause_3 = 9'b000_101_010;
    //clause_4 = 9'b100_101_010; 

    //Test 7:
    //clause_1 = 9'b000_000_001; 
    //clause_2 = 9'b001_001_010; 
    //clause_3 = 9'b010_010_000; 
    //clause_4 = 9'b100_101_110; 
        
    


    //================================================

    // TODO 3
    //write some code here to change the input of the moudle above
    integer i;  // test index

    initial begin
        @(negedge clk); // let rst signal start at 15ns
        @(negedge clk);
        rst = 1;
        clause_1 = 0; clause_2 = 0; clause_3 = 0; clause_4 = 0;
        @(negedge clk);
        @(negedge clk); // let rst signal work for 20ns
        rst = 0;

        for (i = 0; i < 8; i = i + 1) begin
            clause_1 = 0; clause_2 = 0; clause_3 = 0; clause_4 = 0;
            rst = 0;
            
            case (i)
                0: begin
                    clause_1 = 9'b000_001_010;
                    clause_2 = 9'b100_101_110;
                    clause_3 = 9'b000_101_110;
                    clause_4 = 9'b100_001_010;
                end
                1: begin
                    clause_1 = 9'b000_000_000;
                    clause_2 = 9'b100_100_100;
                    clause_3 = 9'b001_001_001;
                    clause_4 = 9'b101_101_101;
                end
                2: begin
                    clause_1 = 9'b010_010_010;
                    clause_2 = 9'b110_110_110;
                    clause_3 = 9'b000_001_010;
                    clause_4 = 9'b100_101_110;
                end
                3: begin
                    //clause_1 = 9'b000_101_100; 
    //clause_2 = 9'b010_010_010;
    //clause_3 = 9'b100_101_010;
    //clause_4 = 9'b000_001_110;
                    clause_1 = 9'b000_101_100; 
                    clause_2 = 9'b010_010_010;
                    clause_3 = 9'b100_101_010;
                    clause_4 = 9'b000_001_110;
                end
                4: begin
                    //clause_1 = 9'b000_101_110; 
    //clause_2 = 9'b100_001_010; 
    //clause_3 = 9'b001_110_000; 
    //clause_4 = 9'b101_010_100; 
                    clause_1 = 9'b000_101_110; 
                    clause_2 = 9'b100_001_010; 
                    clause_3 = 9'b001_110_000; 
                    clause_4 = 9'b101_010_100;
                end
                5: begin
                    //clause_1 = 9'b000_000_000;
    //clause_2 = 9'b100_100_100;
    //clause_3 = 9'b001_001_001;
    //clause_4 = 9'b101_101_101;
                    clause_1 = 9'b000_000_000;
                    clause_2 = 9'b100_100_100;
                    clause_3 = 9'b001_001_001;
                    clause_4 = 9'b101_101_101;
                end
                6: begin
                    //clause_1 = 9'b010_001_000;
    //clause_2 = 9'b001_100_010; 
    //clause_3 = 9'b000_101_010;
    //clause_4 = 9'b100_101_010; 
                    clause_1 = 9'b010_001_000;
                    clause_2 = 9'b001_100_010; 
                    clause_3 = 9'b000_101_010;
                    clause_4 = 9'b100_101_010;
                end
                7: begin
                    clause_1 = 9'b000_000_001; 
                    clause_2 = 9'b001_001_010; 
                    clause_3 = 9'b010_010_000; 
                    clause_4 = 9'b100_101_110;
                end
            endcase

            @(negedge clk); // wait for a clock cycle
        end
        @(posedge clk); // let simulation run til 120000ns.
        $display("All test cases done.");
        $finish;
    end
    
    
    //================================================


endmodule
