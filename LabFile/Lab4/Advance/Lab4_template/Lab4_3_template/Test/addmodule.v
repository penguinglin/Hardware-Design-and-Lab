module display(
    input wire clk,
    input wire [6:0] display0,
    input wire [6:0] display1,
    input wire [6:0] display2,
    input wire [6:0] display3,
    output wire [6:0] display,
    output wire [3:0] digit
);
    wire new_clk;
    reg [3:0] index = 0;
    wire start;
    assign start = 1;

    wire flash;
    reg [6:0] display_;
    reg [3:0] digit_;

    assign display = display_;
    assign digit = digit_;
    clock_divider #(.n(17)) m1(
        .clk(clk),
        .clk_div(new_clk)
    );

    counter #(.n(5)) m2(
        .clk(clk),
        .start(start),
        .flash(flash),
        .round()
    );
    always@(posedge new_clk)begin
     
        if(index == 3) index <= 0;
        else index <= index + 1;
        
        case(index)
            0:begin
                digit_ = 4'b0111;
                display_ = display0;
            end
            1:begin
                digit_ = 4'b1011;
                display_ = display1;
            end
            2:begin
                digit_ = 4'b1101;
                display_ = display2;
            end
            3:begin
                digit_ = 4'b1110;
                display_ = display3;
            end
        endcase
    end
endmodule

module clock_divider #(
    parameter n = 27
)(
    input wire  clk,
    output wire clk_div  
);

    reg [n-1:0] num;
    wire [n-1:0] next_num;

    always @(posedge clk) begin
        num <= next_num;
    end

    assign next_num = num + 1;
    assign clk_div = num[n-1];
endmodule

module counter #(
    parameter integer n = 1
)(
    input wire start,
    input wire  clk,
    output wire [9:0] round,
    output wire flash
);
    reg [9:0] round_;
    reg flash_;
    reg[29:0] counter;
    always@(posedge clk)begin
        if(start)begin
            if(counter < n * 100000000 - 1)begin
                counter <= counter + 1;
            end
            else begin
                counter <= 0;
                round_ <= round_ + 1;
                flash_ <= !flash_;
            end
        end
        else begin
            counter <= 0;
            round_ <= 0;
            flash_ <= 0;
        end
    end
    assign round = round_;
    assign flash = flash_;
endmodule