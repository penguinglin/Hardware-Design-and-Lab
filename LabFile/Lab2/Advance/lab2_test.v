`timescale 1ns/1ps

module lab2_adv_1 (
    input clk,
    input rst,
    input [8:0] clause_1,
    input [8:0] clause_2,
    input [8:0] clause_3,
    input [8:0] clause_4,
    output reg satisfaction,
    output reg [2:0] out
);

// Output signals can be reg or wire
// add your design here
integer cnt;
reg [2:0]cnt_bit;
integer i;
integer a1;
integer a2;
integer a3;
integer haveAns = 0;
reg [2:0] result;
reg satis;
reg ans1,ans2,ans3,ans4;
always@(clause_1, clause_2, clause_3, clause_4)begin
    result = 3'b111;
    satis = 0;
    for(cnt = 0; cnt < 8; cnt = cnt + 1)begin
        cnt_bit = cnt;
        case (clause_1[7:6])
            2'b00: a1 = (clause_1[8] == 0) ? cnt_bit[0] : !cnt_bit[0] ;
            2'b01: a1 = (clause_1[8] == 0) ? cnt_bit[1] : !cnt_bit[1] ;
            2'b10: a1 = (clause_1[8] == 0) ? cnt_bit[2] : !cnt_bit[2] ;
        endcase
        case (clause_1[4:3])
            2'b00: a2 = (clause_1[5] == 0) ? cnt_bit[0] : !cnt_bit[0] ;
            2'b01: a2 = (clause_1[5] == 0) ? cnt_bit[1] : !cnt_bit[1] ;
            2'b10: a2 = (clause_1[5] == 0) ? cnt_bit[2] : !cnt_bit[2] ;
        endcase
        case (clause_1[1:0])
            2'b00: a3 = (clause_1[2] == 0) ? cnt_bit[0] : !cnt_bit[0] ;
            2'b01: a3 = (clause_1[2] == 0) ? cnt_bit[1] : !cnt_bit[1] ;
            2'b10: a3 = (clause_1[2] == 0) ? cnt_bit[2] : !cnt_bit[2] ;
        endcase
        ans1 = a1 || a2 || a3;

        case (clause_2[7:6])
            2'b00: a1 = (clause_2[8] == 0) ? cnt_bit[0] : !cnt_bit[0] ;
            2'b01: a1 = (clause_2[8] == 0) ? cnt_bit[1] : !cnt_bit[1] ;
            2'b10: a1 = (clause_2[8] == 0) ? cnt_bit[2] : !cnt_bit[2] ;
        endcase
        case (clause_2[4:3])
            2'b00: a2 = (clause_2[5] == 0) ? cnt_bit[0] : !cnt_bit[0] ;
            2'b01: a2 = (clause_2[5] == 0) ? cnt_bit[1] : !cnt_bit[1] ;
            2'b10: a2 = (clause_2[5] == 0) ? cnt_bit[2] : !cnt_bit[2] ;
        endcase
        case (clause_2[1:0])
            2'b00: a3 = (clause_2[2] == 0) ? cnt_bit[0] : !cnt_bit[0] ;
            2'b01: a3 = (clause_2[2] == 0) ? cnt_bit[1] : !cnt_bit[1] ;
            2'b10: a3 = (clause_2[2] == 0) ? cnt_bit[2] : !cnt_bit[2] ;
        endcase
        ans2 = a1 || a2 || a3;

        case (clause_3[7:6])
            2'b00: a1 = (clause_3[8] == 0) ? cnt_bit[0] : !cnt_bit[0] ;
            2'b01: a1 = (clause_3[8] == 0) ? cnt_bit[1] : !cnt_bit[1] ;
            2'b10: a1 = (clause_3[8] == 0) ? cnt_bit[2] : !cnt_bit[2] ;
        endcase
        case (clause_3[4:3])
            2'b00: a2 = (clause_3[5] == 0) ? cnt_bit[0] : !cnt_bit[0] ;
            2'b01: a2 = (clause_3[5] == 0) ? cnt_bit[1] : !cnt_bit[1] ;
            2'b10: a2 = (clause_3[5] == 0) ? cnt_bit[2] : !cnt_bit[2] ;
        endcase
        case (clause_3[1:0])
            2'b00: a3 = (clause_3[2] == 0) ? cnt_bit[0] : !cnt_bit[0] ;
            2'b01: a3 = (clause_3[2] == 0) ? cnt_bit[1] : !cnt_bit[1] ;
            2'b10: a3 = (clause_3[2] == 0) ? cnt_bit[2] : !cnt_bit[2] ;
        endcase
        ans3 = a1 || a2 || a3;

        case (clause_4[7:6])
            2'b00: a1 = (clause_4[8] == 0) ? cnt_bit[0] : !cnt_bit[0] ;
            2'b01: a1 = (clause_4[8] == 0) ? cnt_bit[1] : !cnt_bit[1] ;
            2'b10: a1 = (clause_4[8] == 0) ? cnt_bit[2] : !cnt_bit[2] ;
        endcase
        case (clause_4[4:3])
            2'b00: a2 = (clause_4[5] == 0) ? cnt_bit[0] : !cnt_bit[0] ;
            2'b01: a2 = (clause_4[5] == 0) ? cnt_bit[1] : !cnt_bit[1] ;
            2'b10: a2 = (clause_4[5] == 0) ? cnt_bit[2] : !cnt_bit[2] ;
        endcase
        case (clause_4[1:0])
            2'b00: a3 = (clause_4[2] == 0) ? cnt_bit[0] : !cnt_bit[0] ;
            2'b01: a3 = (clause_4[2] == 0) ? cnt_bit[1] : !cnt_bit[1] ;
            2'b10: a3 = (clause_4[2] == 0) ? cnt_bit[2] : !cnt_bit[2] ;
        endcase
        ans4 = a1 || a2 || a3;
        if(!satis)begin
            if(ans1 && ans2 && ans3 && ans4)begin
                result = cnt;
                satis = 1;
            end
        end


    end
    
end

always@(posedge clk)begin
    if(rst == 1)begin
        out <= 3'b000;
        satisfaction <= 0;
    end
    else begin
        out <= result;
        satisfaction <= satis;
    end
end
endmodule
