module mem_addr_gen(
    input clk,          // clk_20
    input rst,          // asynchronous reset
    input dir_left,     // scroll left enable
    input dir_up,       // scroll up enable
    input vmir,         // vertical mirror
    input hmir,         // horizontal mirror
    input speed,        // 0: slow, 1: fast
    input [9:0] h_cnt,  // from VGA controller
    input [9:0] v_cnt,  // from VGA controller
    output [16:0] pixel_addr
);

    parameter IMAGE_WIDTH  = 320;
    parameter IMAGE_HEIGHT = 240;
    parameter IMAGE_SIZE   = 76800;

    // downscale VGA coordinates to image coordinates
    wire [9:0] h_cnt_new = h_cnt >> 1;
    wire [9:0] v_cnt_new = v_cnt >> 1;

    // mirror coordinate mapping (purely display effect)
    wire [9:0] x_res = hmir ? (IMAGE_WIDTH  - 1 - h_cnt_new) : h_cnt_new;
    wire [9:0] y_res = vmir ? (IMAGE_HEIGHT - 1 - v_cnt_new) : v_cnt_new;

    // scrolling offset registers
    reg [9:0] x_off, y_off;
    reg [2:0] count_4;  // small divider for slow speed

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x_off  <= 0;
            y_off  <= 0;
            count_4 <= 0;
        end else begin
            // -----------------------------
            // Update rate control by speed
            // -----------------------------
            if (speed == 0) begin
                if (count_4 >= 3'd3) begin
                    count_4 <= 0;
                    // --- X offset update ---
                    if (dir_left) begin
                        if (hmir) begin
                            // mirror mode → offset direction reversed
                            x_off <= (x_off == 0) ? IMAGE_WIDTH - 1 : x_off - 1;
                        end else begin
                            x_off <= (x_off == IMAGE_WIDTH - 1) ? 0 : x_off + 1;
                        end
                    end

                    // --- Y offset update ---
                    if (dir_up) begin
                        if (vmir) begin
                            // mirror mode → offset direction reversed
                            y_off <= (y_off == 0) ? IMAGE_HEIGHT - 1 : y_off - 1;
                        end else begin
                            y_off <= (y_off == IMAGE_HEIGHT - 1) ? 0 : y_off + 1;
                        end
                    end
                end else begin
                    count_4 <= count_4 + 1;
                end
            end else begin
                // fast mode → update every cycle
                if (dir_left) begin
                    if (hmir)
                        x_off <= (x_off == 0) ? IMAGE_WIDTH - 1 : x_off - 1;
                    else
                        x_off <= (x_off == IMAGE_WIDTH - 1) ? 0 : x_off + 1;
                end
                if (dir_up) begin
                    if (vmir)
                        y_off <= (y_off == 0) ? IMAGE_HEIGHT - 1 : y_off - 1;
                    else
                        y_off <= (y_off == IMAGE_HEIGHT - 1) ? 0 : y_off + 1;
                end
            end
        end
    end

    // coordinate wrapping (prevent overflow)
    wire [9:0] x_tmp = x_res + x_off;
    wire [9:0] y_tmp = y_res + y_off;

    wire [9:0] x_addr = (x_tmp >= IMAGE_WIDTH)  ? x_tmp - IMAGE_WIDTH  : x_tmp;
    wire [9:0] y_addr = (y_tmp >= IMAGE_HEIGHT) ? y_tmp - IMAGE_HEIGHT : y_tmp;

    // compute final pixel address
    assign pixel_addr = x_addr + y_addr * IMAGE_WIDTH;

endmodule