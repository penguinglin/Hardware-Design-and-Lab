module lab5_2 (
    input wire clk,
    input wire rst,
    input wire start,
    input wire hint,
    inout wire PS2_CLK,
    inout wire PS2_DATA,
    output reg [3:0] vgaRed,
    output reg [3:0] vgaGreen,
    output reg [3:0] vgaBlue,
    output wire hsync,
    output wire vsync,
    output reg pass
);

    parameter INIT = 2'b00, SHOW = 2'b01, GAME = 2'b10, FINISH = 2'b11;
    reg [1:0] state;
    reg [1:0] next_state;

    wire [11:0] data;
    wire clk_2;
    wire clk_22;
    wire [16:0] pixel_addr;
    wire [11:0] pixel;
    wire valid;
    wire [9:0] h_cnt; //640
    wire [9:0] v_cnt;  //480

    reg [15:0] flip = 16'b0;                            // 紀錄那些block被翻開
    reg [15:0] correct = 16'b0;                         // 記錄在GAME中，翻轉那些block (為1代表block有轉)
    reg [15:0] tmp_correct = 16'b1000_1101_0011_0110;   // 紀錄哪些block一開始返的 (為1代表block是正的)

    wire [3:0] grid_x;
    wire [3:0] grid_y;
    wire [3:0] index;

    reg [1:0] round;
    reg [4:0] pre_key_1;
    reg [4:0] pre_key_2;

    reg [2:0] image_grid [0:15];

    reg [4:0] key_num;
	wire [511:0] key_down;
	wire [8:0] last_change;
	wire been_ready;

    reg label;
    integer i;

    wire debounce_rst, one_pulse_rst;
    debounce deb_1(.pb_debounced(debounce_rst), .pb(rst), .clk(clk));
    one_pulse one_1(.clk(clk), .pb_in(debounce_rst), .pb_out(one_pulse_rst));

    wire debounce_start, one_pulse_start;
    debounce deb_2(.pb_debounced(debounce_start), .pb(start), .clk(clk));
    one_pulse one_2(.clk(clk), .pb_in(debounce_start), .pb_out(one_pulse_start));

    clock_divider #(.n(2)) clk_div_2(
        .clk(clk),
        .clk_div(clk_2)
    );

    clock_divider #(.n(22)) clk_div_22(
        .clk(clk),
        .clk_div(clk_22)
    );

    mem_addr_gen mem_inst(
        .clk(clk_22),
        .rst(rst),
        .state(state),
        .correct(correct),
        .hint(hint),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr(pixel_addr)
    );

    blk_mem_gen_0 blk_inst(
        .clka(clk_2),
        .wea(0),
        .addra(pixel_addr),
        .dina(data[11:0]),
        .douta(pixel)
    ); 

    vga_controller vga_inst(
        .pclk(clk_2),
        .reset(rst),
        .hsync(hsync),
        .vsync(vsync),
        .valid(valid),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt)
    );


    always @ (posedge clk) begin
        if(rst == 1) begin
            state <= INIT;
        end else begin
            state <= next_state;
        end
    end

    always @ (*) begin
        next_state = state;
        if(state == INIT) begin
            if(one_pulse_start == 1) next_state = SHOW;
        end else if(state == SHOW) begin
            if(one_pulse_start == 1) next_state = GAME;
        end else if(state == GAME) begin
            if(flip == 16'hFFFF) next_state = FINISH;
        end else if(state == FINISH) begin
            if(one_pulse_start == 1) next_state = INIT;
        end
    end


    assign grid_x = h_cnt / 160; 
    assign grid_y = v_cnt / 120; 
    assign index = grid_y * 4 + grid_x; 

    // 實作在不同狀態下，螢幕該如何顯示
    always @ (*) begin
        if(state == INIT) begin
            {vgaRed, vgaGreen, vgaBlue} = 12'h0;
        end else if(state == SHOW) begin
            {vgaRed, vgaGreen, vgaBlue} = pixel;
        end else if(state == GAME) begin
            if(hint == 1) {vgaRed, vgaGreen, vgaBlue} = pixel;
            else if(flip[index] == 1) {vgaRed, vgaGreen, vgaBlue} = pixel;
            else {vgaRed, vgaGreen, vgaBlue} = 12'h0;
        end else if(state == FINISH) begin
            {vgaRed, vgaGreen, vgaBlue} = pixel;
        end    
    end

    always @ (*) begin
        pass = 0;
        if(state == FINISH) pass = 1;
    end

    

    initial begin
        image_grid[0] = 3'b000;
        image_grid[1] = 3'b001;
        image_grid[2] = 3'b010;
        image_grid[3] = 3'b011;
        image_grid[4] = 3'b011;
        image_grid[5] = 3'b000;
        image_grid[6] = 3'b100;
        image_grid[7] = 3'b101;
        image_grid[8] = 3'b110;
        image_grid[9] = 3'b111;
        image_grid[10] = 3'b101;
        image_grid[11] = 3'b111;
        image_grid[12] = 3'b010;
        image_grid[13] = 3'b001;
        image_grid[14] = 3'b110;
        image_grid[15] = 3'b100;
    end

	parameter [8:0] KEY_CODES [0:17] = {
		9'b0_0001_0110,	// 1 => 16
		9'b0_0001_1110,	// 2 => 1E
		9'b0_0010_0110,	// 3 => 26
		9'b0_0010_0101,	// 4 => 25
		9'b0_0001_0101,	// Q => 15
		9'b0_0001_1101,	// W => 1D
		9'b0_0010_0100,	// E => 24
		9'b0_0010_1101,	// R => 2D
		9'b0_0001_1100,	// A => 1C
		9'b0_0001_1011, // S => 1B
		9'b0_0010_0011, // D => 23
		9'b0_0010_1011, // F => 2B
		9'b0_0001_1010, // Z => 1A
		9'b0_0010_0010, // X => 22
		9'b0_0010_0001, // C => 21
		9'b0_0010_1010, // V => 2A
		9'b0_0101_1001, // shift => 59
        9'b0_0101_1010 // enter => 5A
	};
	
	KeyboardDecoder key_d (
		.key_down(key_down),
		.last_change(last_change),
		.key_valid(been_ready),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
	);

 

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            flip <= 16'b0;
            round <= 2'b00;
            pre_key_1 <= 5'b00000;
            pre_key_2 <= 5'b00000;
            correct <= 16'b0;
            tmp_correct <= 16'b0110_1100_1011_0001;
        end else begin
            if (state == INIT || state == SHOW) begin
                flip <= 16'b0;
                round <= 2'b00;
                pre_key_1 <= 5'b00000;
                pre_key_2 <= 5'b00000;
                correct <= 16'b0;
                tmp_correct <= 16'b1000_1101_0011_0110;
            end else if(state == FINISH) begin
                flip <= 16'b0;
                round <= 2'b00;
                pre_key_1 <= 5'b00000;
                pre_key_2 <= 5'b00000;
                correct <= 16'b0111_0010_1100_1001;
                tmp_correct <= 16'b1000_1101_0011_0110;
            end else if (been_ready == 1) begin
                if (key_down[last_change] == 1'b1) begin
                    if (hint == 0) begin
                        if (key_num != 5'b10000 && key_num != 5'b10001 && key_num != 5'b11111) begin
                            if (round == 2'b00) begin
                                flip[key_num] <= 1;     // 更新對應block的flip
                                pre_key_1 <= key_num;   // 記錄第一個按鍵為何
                                round <= 2'b01;
                            end else if (round == 2'b01 && key_num != pre_key_1) begin
                                flip[key_num] <= 1;     // 更新對應block的flip
                                pre_key_2 <= key_num;   // 記錄第二個按鍵為何
                                round <= 2'b10;
                            end
                        end else if (key_num == 5'b10001) begin // 按下 Enter
                            if (round == 2'b10) begin
                                if(pre_key_2 != 5'b10000) begin
                                    if (image_grid[pre_key_1] != image_grid[pre_key_2] || tmp_correct[pre_key_1] == 0 || tmp_correct[pre_key_2] == 0) begin // 兩個block不match
                                        flip[pre_key_1] <= 0;
                                        flip[pre_key_2] <= 0;
                                    end
                                end else begin
                                    flip[pre_key_1] <= 0;
                                end
                                round <= 2'b00; 
                            end
                        end else if (key_num == 5'b10000) begin // 按下 Shift
                            if(round == 2'b01) begin
                                correct[pre_key_1] = ~correct[pre_key_1];
                                tmp_correct[pre_key_1] = ~tmp_correct[pre_key_1];
                                pre_key_2 <= key_num;
                            end
                            round <= 2'b10;
                        end
                    end
                end
            end
        end
    end



	always @ (*) begin
		label = 0;
		for(i = 0; i < 512; i = i + 1) begin
			if(key_down[i] == 1) begin
                label = 1;
            end
		end
	end
	
	always @ (*) begin
		case (last_change)
			KEY_CODES[00] : key_num = 5'b00000; //1
			KEY_CODES[01] : key_num = 5'b00001; //2
			KEY_CODES[02] : key_num = 5'b00010; //3
			KEY_CODES[03] : key_num = 5'b00011; //4
			KEY_CODES[04] : key_num = 5'b00100; //Q
			KEY_CODES[05] : key_num = 5'b00101; //W
			KEY_CODES[06] : key_num = 5'b00110; //E
			KEY_CODES[07] : key_num = 5'b00111; //R
			KEY_CODES[08] : key_num = 5'b01000; //A
			KEY_CODES[09] : key_num = 5'b01001; //S
			KEY_CODES[10] : key_num = 5'b01010; //D
			KEY_CODES[11] : key_num = 5'b01011; //F
			KEY_CODES[12] : key_num = 5'b01100; //Z
			KEY_CODES[13] : key_num = 5'b01101; //X
			KEY_CODES[14] : key_num = 5'b01110; //C
			KEY_CODES[15] : key_num = 5'b01111; //V
			KEY_CODES[16] : key_num = 5'b10000; //shift
            KEY_CODES[17] : key_num = 5'b10001; //enter

			default		  : key_num = 5'b11111; //other
		endcase
	end


endmodule



