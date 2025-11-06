`timescale 1ns/1ps

module lab5_basic (
    input wire clk,
    input wire rst,
    input wire we,
    input wire re,
    input wire [2:0] addr,
    input wire [9:0] din,
    output reg dirty,
    output reg [9:0] dout
);
    // add your design here
    reg [9:0]memory[0:7]; 
    reg used[0:7];
    reg sec_used[0:7];
    integer now_id;

    integer i;
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            for(i=0;i<8;i=i+1)begin
                memory[i] <= 10'd0;
                used[i]<= 0;
                sec_used[i]<=0;
            end
            dout <= 10'd0;
            dirty <= 0;
            now_id <= 0;
        end else begin
            // write
            if(we) begin
                //write
                memory[now_id] <= din;

                // if item first used
                if(used[now_id] == 0 && sec_used[now_id]==0)
                    used[now_id] <= 1;
                else if(used[now_id] == 1 && sec_used[now_id]==0) // second used
                    sec_used[now_id] <=1;
                
                // update now_id
                now_id <= ((now_id + 1) == 8)? 0 : now_id + 1;
                dirty <= 0;
            end
            // read 
            else if (re) begin
                // check if used 
                dirty <= (sec_used[addr]) ? 1 : 0;
                dout <= memory[addr];
            end else begin 
                dout <= 10'd0;
                dirty <= 0;
            end 
        end        
    end

endmodule
