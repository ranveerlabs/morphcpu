`timescale 1ns / 1ps
`default_nettype none

module morph_cell #(
    parameter DATA_W = 8
) (
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 clr,

    input  wire                 cfg_shift,
    input  wire                 cfg_in,
    output wire                 cfg_out,

    input  wire                 tick,

    input  wire [DATA_W-1:0]    in_n_data,
    input  wire                 in_n_val,
    input  wire [DATA_W-1:0]    in_e_data,
    input  wire                 in_e_val,
    input  wire [DATA_W-1:0]    in_s_data,
    input  wire                 in_s_val,
    input  wire [DATA_W-1:0]    in_w_data,
    input  wire                 in_w_val,

    output wire [DATA_W-1:0]    out_data,
    output wire                 out_val,
    output wire [1:0]           out_dir,
    output wire                 active
);

    localparam [1:0] OP_PASS = 2'd0;
    localparam [1:0] OP_INV  = 2'd1;
    localparam [1:0] OP_ADD  = 2'd2;
    localparam [1:0] OP_XOR  = 2'd3;

    localparam [1:0] DIR_N   = 2'd0;
    localparam [1:0] DIR_E   = 2'd1;
    localparam [1:0] DIR_S   = 2'd2;
    localparam [1:0] DIR_W   = 2'd3;

    reg [3:0] cfg;

    always @(posedge clk) begin
        if (rst)
            cfg <= 4'b0;
        else if (cfg_shift)
            cfg <= {cfg[2:0], cfg_in};
    end

    assign cfg_out = cfg[3];

    wire [1:0] op  = cfg[3:2];
    wire [1:0] dir = cfg[1:0];

    wire [3:0]          vmask = {in_w_val, in_s_val, in_e_val, in_n_val};
    wire [4*DATA_W-1:0] idata = {in_w_data, in_s_data, in_e_data, in_n_data};

    reg  [DATA_W-1:0] a, b_in;
    reg               a_val, b_val;
    integer           i;

    always @* begin
        a     = {DATA_W{1'b0}};
        b_in  = {DATA_W{1'b0}};
        a_val = 1'b0;
        b_val = 1'b0;
        for (i = 0; i < 4; i = i + 1) begin
            if (vmask[i]) begin
                if (!a_val) begin
                    a     = idata[i*DATA_W +: DATA_W];
                    a_val = 1'b1;
                end else if (!b_val) begin
                    b_in  = idata[i*DATA_W +: DATA_W];
                    b_val = 1'b1;
                end
            end
        end
    end

    reg [DATA_W-1:0] pizza;
    reg              tip;

    wire [DATA_W-1:0] b = b_val ? b_in : pizza;

    reg [DATA_W-1:0] alu;
    always @* begin
        case (op)
            OP_PASS: alu = a;
            OP_INV:  alu = ~a;
            OP_ADD:  alu = a + b;
            OP_XOR:  alu = a ^ b;
            default: alu = a;
        endcase
    end

    always @(posedge clk) begin
        if (rst || clr) begin
            pizza <= {DATA_W{1'b0}};
            tip   <= 1'b0;
        end else if (tick) begin
            tip <= a_val;
            if (a_val)
                pizza <= alu;
        end
    end

    assign out_data = pizza;
    assign out_val  = tip;
    assign out_dir  = dir;
    assign active   = tip;

endmodule

`default_nettype wire
