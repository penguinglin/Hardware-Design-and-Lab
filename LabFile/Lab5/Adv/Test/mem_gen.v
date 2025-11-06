module mem_addr_gen(
    input clk,
    input rst,
    input state,
    input [15:0] correct,
    input hint,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    output [16:0] pixel_addr
);

    parameter IMAGE_WIDTH = 320;
    parameter IMAGE_HEIGHT = 240;
    parameter IMAGE_SIZE = 76800;

    wire [3:0] grid_x;
    wire [3:0] grid_y;
    wire [3:0] index;

    wire [9:0] h_cnt_new, v_cnt_new;
    assign h_cnt_new = h_cnt >> 1;  // 320
    assign v_cnt_new = v_cnt >> 1;  // 240

    // 計算現在要輸出的位置位於哪個block
    assign grid_x = h_cnt_new / 80; 
    assign grid_y = v_cnt_new / 60; 
    assign index = grid_y * 4 + grid_x; 

    reg [9:0] v_res;
    reg [15:0] new_correct;

    // 若hint = 1，翻轉顛倒的block
    always @ (*) begin
        if(hint == 1) new_correct = 16'b0111_0010_1100_1001;
        else new_correct = correct;
    end

    // 實作翻轉單個block
    always @ (*) begin
        if(new_correct[index] == 1) begin
            v_res = (60 * (grid_y + 1) - 1 - v_cnt_new + 60 * grid_y);
        end else begin
            v_res = v_cnt_new;
        end
    end

    assign pixel_addr = ((h_cnt_new) % IMAGE_WIDTH) + (((v_res) % IMAGE_HEIGHT) * IMAGE_WIDTH) % IMAGE_SIZE;


endmodule
