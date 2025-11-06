`timescale 1ns/1ps

module lab5_basic_tb;
    reg clk = 1'b0;
    reg rst = 1'b0;
    reg we = 1'b0;
    reg re = 1'b0;
    reg [2:0] addr = 3'd0;
    reg [9:0] din;
    wire dirty;
    wire [9:0] dout;

    always #5 clk = ~clk;

    lab5_basic basic (
        .clk(clk), 
        .rst(rst), 
        .we(we),
        .re(re),
        .addr(addr),
        .din(din),
        .dout(dout),
        .dirty(dirty)
    );

    integer error_count;
    integer file, scan_file;
    reg [9:0] test_din;
    reg [9:0] test_dout;
    reg test_dirty;

    initial begin
        $display("==== Simulation Starts ====");
        error_count = 0;

        // Initialize signals
        rst = 1'b1;
        addr = 3'd0;
        we = 1'b0;
        re = 1'b0;
        din = 10'd0;

        file = $fopen("input_data1.dat", "r");
        if (file == 0) begin
            $display("Failed to open file");
            $finish;
        end

        @(negedge clk);
        rst = 1'b0;

        // write
        #30;
        for (integer i = 0; i < 8; i = i + 1) begin
            @(negedge clk);
            if(i == 0)
                we = 1'b1;
            scan_file = $fscanf(file, "%d\n", test_din); 
            din = test_din;
            #3;
            if (i == 6) we = 1'b0;
            #7;
        end

        // read
        #50;
        for (integer i = 0; i < 6; i = i + 1) begin
            @(negedge clk);
            if (i <= 5) re = 1'b1;
            else re = 1'b0;
            scan_file = $fscanf(file, "%d\n", test_dout);
            addr = i[2:0];
            #8;
            if (dout !== test_dout) begin
                $display("Error at index %d:  expected dout=%d, got dout=%d", i, test_dout, dout);
                error_count = error_count + 1;
            end
        end
        re = 1'b0;
        addr = 3'd0;
        test_dout = 10'd0;
        
        if (error_count === 0) begin
            $display("==== Case 1 Passed (20%%) ====");
        end 
        else begin
            $display("==== Error in Case 1 ====");
        end

        @(posedge clk);
        rst = 1'b1;
        #50;
        
        // tb2
        @(posedge clk);
        rst = 1'b0;
        error_count = 0;
        
        // write
        #80;
        for (integer i = 0; i < 6; i = i + 1) begin
            @(negedge clk);
            if(i == 0)
                we = 1'b1;
            scan_file = $fscanf(file, "%d\n", test_din); 
            din = test_din;
            #3;
            if (i == 5) we = 1'b0; 
            #7;
        end
        we = 1'b0;
        
        // read
        #50;
        for (integer i = 0; i < 4; i = i + 1) begin
            @(negedge clk);
            re = 1'b1;
            scan_file = $fscanf(file, "%d\n", test_dout);
            scan_file = $fscanf(file, "%d\n", addr);
            #8;
            if (dout !== test_dout) begin
                $display("Error at index %d:  expected dout=%d, got dout=%d", i, test_dout, dout);
                error_count = error_count + 1;
            end
        end

        @(negedge clk);
        re = 1'b0;
        addr = 3'd0;
        test_dout = 10'd0;
        
        //if (dout != 0) error_count = error_count + 1;
        
        #20;
        $fclose(file);
        
        if (error_count === 0) begin
            $display("==== Case 2 Passed (20%%) ====");
        end
        else begin
            $display("==== Error in Case 2 ====");
        end

        @(posedge clk);
        rst = 1'b1;
        #50;
        
        @(posedge clk);
        rst = 1'b0;
        error_count = 0;
        
        // tb3
        file = $fopen("input_data2.dat", "r");
        if (file == 0) begin
            $display("Failed to open file");
            $finish;
        end

        @(negedge clk);
        rst = 1'b0;
        
        // write
        #80;
        for (integer i = 0; i < 12; i = i + 1) begin
            @(negedge clk);
            if(i == 0)
                we = 1'b1;
            scan_file = $fscanf(file, "%d\n", test_din); 
            din = test_din;
            #8;
            if (i == 11) we = 1'b0;
        end
        we = 1'b0;

         // write
        #50;
        for (integer i = 0; i < 6; i = i + 1) begin
            @(negedge clk);
            if (i <= 4)begin 
                re = 1'b1;
                scan_file = $fscanf(file, "%d\n", addr);
                scan_file = $fscanf(file, "%d\n", test_dout);
                scan_file = $fscanf(file, "%d\n", test_dirty);
                #8;
                if (dout !== test_dout) begin
                    $display("Error at index %d: expected dout=%d, got dout=%d", i, test_dout, dout);
                    error_count = error_count + 1;
                end
                if(dirty !== test_dirty) begin
                    $display("Error at index %d: expected dirty=%b, got dirty=%b", i, test_dirty, dirty);
                    error_count = error_count + 1;
                end 
            end
            if (i >= 4) re = 1'b0;
        end
        re = 1'b0;
        addr = 3'd0;
        test_dout = 10'd0;
        test_dirty = 1'b0;
        
        #50;
        // final
        if (error_count === 0) begin
            $display("==== Case 3 Passed (20%%) ====");
        end 
        else begin
            $display("==== Error in Case 3 ====");
        end
        rst = 1'b1;

        //tb4
        #50;
        @(negedge clk);
        rst = 1'b0;
        error_count = 0;
        
        // write
        #40;
        for (integer i = 0; i < 7; i = i + 1) begin
            @(negedge clk);
            if(i == 0)
                we = 1'b1;
            scan_file = $fscanf(file, "%d\n", test_din); 
            din = test_din;
            #8;            
            if (i == 5) we = 1'b0;
        end
        
        // read
        #50;
        @(negedge clk);
        re = 1'b1;
        scan_file = $fscanf(file, "%d\n", addr);
        scan_file = $fscanf(file, "%d\n", test_dout);
        scan_file = $fscanf(file, "%d\n", test_dirty);
        #8;
        if (dout !== test_dout) begin
            $display("Error in tb4: expected dout=%d, got dout=%d", test_dout, dout);
            error_count = error_count + 1;
        end
        if (dirty !== test_dirty) begin
            $display("Error in tb4: expected dirty=%b, got dirty=%b", test_dirty, dirty);
            error_count = error_count + 1;
        end
        re = 1'b0;
        addr = 3'd0;
        test_dout = 10'd0;
        test_dirty = 1'b0;

        // // write 2
        #40;
        for (integer i = 0; i < 7; i = i + 1) begin
            @(negedge clk);
            if(i == 0)
                we = 1'b1;
            scan_file = $fscanf(file, "%d\n", test_din); 
            din = test_din;
            #8;            
            if (i == 5) we = 1'b0;
        end
        
        // read 2
        #40;

        for (integer i = 0; i < 3; i = i + 1) begin
            @(negedge clk);
            if (i <= 2)begin 
                re = 1'b1;
                scan_file = $fscanf(file, "%d\n", addr);
                scan_file = $fscanf(file, "%d\n", test_dout);
                scan_file = $fscanf(file, "%d\n", test_dirty);
                #8;
                if (dout !== test_dout) begin
                    $display("Error at index %d: expected dout=%d, got dout=%d", i, test_dout, dout);
                    error_count = error_count + 1;
                end
                if(dirty !== test_dirty) begin
                    $display("Error at index %d: expected dirty=%b, got dirty=%b", i, test_dirty, dirty);
                    error_count = error_count + 1;
                end
            end
            if (i >= 2) re = 1'b0;
        end

        re = 1'b0;
        addr = 3'd0;
        test_dout = 10'd0;
        test_dirty = 1'b0;
        #50;

        // final
        if (error_count === 0) begin
            $display("==== Case 4 Passed (20%%) ====");
        end 
        else begin
            $display("==== Error in Case 4 ====");
        end
        
        #30;
        @(negedge clk);
        rst = 1'b1;
        error_count = 0;
        $fclose(file);
        
        // tb5
        #40;
        @(negedge clk);
        rst = 1'b0;
        re = 1'b1;
        addr = 3'd0;
        
        #8;
        if (dout === 0 && dirty === 0) $display("==== Case 5 Passed (10%%) ====");
        else $display("==== Error in Case 5 ====");
        
        //#3;
        re = 1'b0;
        
        #30;
        @(negedge clk);
        rst = 1'b1;

        #20
        @(negedge clk);
        rst = 1'b0;
        error_count = 0;


        // tb6
        #40;
        @(negedge clk);
        we = 1'b1;
        din = 10'd5;

        #120;
        we = 1'b0;
        @(negedge clk);
        re = 1'b1;
        addr = 3'd2;
        test_dout = 10'd5;
        test_dirty = 1'b1;

        #8;
        if (dout !== 10'd5 || dirty !== test_dirty)
            error_count = error_count + 1;

        @(negedge clk);
        addr = 3'd7;
        test_dout = 10'd5;
        test_dirty = 1'b0;

        #8;
        if (dout !== 10'd5 || dirty !== test_dirty)
            error_count = error_count + 1;
        @(negedge clk);
        re = 1'b0;
        addr = 3'd0;

        if (error_count === 0) $display("==== Case 6 Passed (10%%) ====");
        else $display("==== Error in Case 6 ====");
        
        #30;
        @(negedge clk);
        rst = 1'b1;
    end
endmodule
