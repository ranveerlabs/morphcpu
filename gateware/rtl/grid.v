`timescale 1ns / 1ps
`default_nettype none

module grid #(
    parameter DATA_W = 8,
    parameter ROWS   = 4,
    parameter COLS   = 4
) (
    input  wire                        clk,
    input  wire                        rst,
    input  wire                        clr,

    input  wire                        cfg_shift,
    input  wire                        cfg_in,
    output wire                        cfg_out,

    input  wire                        tick,

    input  wire [ROWS*DATA_W-1:0]      west_in_data,
    input  wire [ROWS-1:0]             west_in_val,

    output wire [ROWS*DATA_W-1:0]      east_out_data,
    output wire [ROWS-1:0]             east_out_val,

    output wire [ROWS*COLS-1:0]        active
);

    localparam [1:0] DIR_N = 2'd0;
    localparam [1:0] DIR_E = 2'd1;
    localparam [1:0] DIR_S = 2'd2;
    localparam [1:0] DIR_W = 2'd3;

    localparam N_CELLS = ROWS * COLS;

    wire [N_CELLS*DATA_W-1:0] c_data;
    wire [N_CELLS-1:0]        c_val;
    wire [N_CELLS*2-1:0]      c_dir;

    wire [N_CELLS:0] cfg_link;
    assign cfg_link[N_CELLS] = cfg_in;
    assign cfg_out           = cfg_link[0];

    genvar gr, gc;
    generate
        for (gr = 0; gr < ROWS; gr = gr + 1) begin : row
            for (gc = 0; gc < COLS; gc = gc + 1) begin : col

                localparam integer IDX = gr * COLS + gc;

                localparam integer NIDX = (gr > 0)        ? IDX - COLS : IDX;
                localparam integer SIDX = (gr < ROWS - 1) ? IDX + COLS : IDX;
                localparam integer EIDX = (gc < COLS - 1) ? IDX + 1    : IDX;
                localparam integer WIDX = (gc > 0)        ? IDX - 1    : IDX;

                wire n_sel = (gr > 0)        && (c_dir[NIDX*2 +: 2] == DIR_S);
                wire s_sel = (gr < ROWS - 1) && (c_dir[SIDX*2 +: 2] == DIR_N);
                wire e_sel = (gc < COLS - 1) && (c_dir[EIDX*2 +: 2] == DIR_W);
                wire w_sel = (gc > 0)        && (c_dir[WIDX*2 +: 2] == DIR_E);

                wire [DATA_W-1:0] n_data = n_sel ? c_data[NIDX*DATA_W +: DATA_W]
                                                 : {DATA_W{1'b0}};
                wire              n_val  = n_sel && c_val[NIDX];

                wire [DATA_W-1:0] s_data = s_sel ? c_data[SIDX*DATA_W +: DATA_W]
                                                 : {DATA_W{1'b0}};
                wire              s_val  = s_sel && c_val[SIDX];

                wire [DATA_W-1:0] e_data = e_sel ? c_data[EIDX*DATA_W +: DATA_W]
                                                 : {DATA_W{1'b0}};
                wire              e_val  = e_sel && c_val[EIDX];

                wire [DATA_W-1:0] w_data = (gc == 0)
                                         ? west_in_data[gr*DATA_W +: DATA_W]
                                         : (w_sel ? c_data[WIDX*DATA_W +: DATA_W]
                                                  : {DATA_W{1'b0}});
                wire              w_val  = (gc == 0) ? west_in_val[gr]
                                                     : (w_sel && c_val[WIDX]);

                morph_cell #(
                    .DATA_W   (DATA_W)
                ) u_cell (
                    .clk      (clk),
                    .rst      (rst),
                    .clr      (clr),
                    .cfg_shift(cfg_shift),
                    .cfg_in   (cfg_link[IDX + 1]),
                    .cfg_out  (cfg_link[IDX]),
                    .tick     (tick),
                    .in_n_data(n_data), .in_n_val(n_val),
                    .in_e_data(e_data), .in_e_val(e_val),
                    .in_s_data(s_data), .in_s_val(s_val),
                    .in_w_data(w_data), .in_w_val(w_val),
                    .out_data (c_data[IDX*DATA_W +: DATA_W]),
                    .out_val  (c_val[IDX]),
                    .out_dir  (c_dir[IDX*2 +: 2]),
                    .active   (active[IDX])
                );
            end
        end

        for (gr = 0; gr < ROWS; gr = gr + 1) begin : eastedge
            localparam integer LIDX = gr * COLS + (COLS - 1);
            assign east_out_data[gr*DATA_W +: DATA_W] = c_data[LIDX*DATA_W +: DATA_W];
            assign east_out_val[gr] = c_val[LIDX] && (c_dir[LIDX*2 +: 2] == DIR_E);
        end
    endgenerate

endmodule

`default_nettype wire
