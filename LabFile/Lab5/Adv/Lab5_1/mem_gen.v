module mem_addr_gen(
    input clk,
    input rst,
    input dir_left,
    input dir_up,
    //input en,
    //input dir,
    input vmir,
    input hmir,
    input speed,
    //input enlarge,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    output [16:0] pixel_addr
);

    parameter IMAGE_WIDTH = 320;
    parameter IMAGE_HEIGHT = 240;
    parameter IMAGE_SIZE = 76800;

    wire [9:0] h_cnt_new, v_cnt_new;
    assign h_cnt_new = h_cnt >> 1;  // 320
    assign v_cnt_new = v_cnt >> 1;  // 240


    wire [9:0] x_trans, y_trans;
    assign x_trans = hmir ? (IMAGE_WIDTH - 1 - h_cnt_new) : h_cnt_new;
    assign y_trans = vmir ? (IMAGE_HEIGHT - 1 - v_cnt_new) : v_cnt_new;


    // enable enlarge
    wire [9:0] x_res, y_res;
    assign x_res =  x_trans;
    assign y_res =  y_trans;


    reg [21:0] scroll_cnt;
    wire scroll_en;
    always @(posedge clk or posedge rst) begin
        if (rst)
            scroll_cnt <= 0;
        else
            scroll_cnt <= scroll_cnt + 1;
    end
    assign scroll_en = speed ? (scroll_cnt[19]) : (scroll_cnt[21]);


    reg [9:0] x_off, y_off;
    always @(posedge clk or posedge rst) begin
        if (rst == 1) begin
            x_off <= 0;
            y_off <= 0;
        end else if (scroll_en) begin
            if (dir_left || dir_up) begin
                if (dir_left)
                    x_off <= x_off + 1;
                else
                    x_off <= x_off;

                if (dir_up)
                    y_off <= y_off + 1;
                else
                    y_off <= y_off;
            end
        end
    end
    
    assign pixel_addr =
        (((x_res + x_off) % IMAGE_WIDTH)
        + (((y_res + y_off) % IMAGE_HEIGHT) * IMAGE_WIDTH)) % IMAGE_SIZE;

endmodule
