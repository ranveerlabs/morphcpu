// ---------------------------------------------------------------------------
// morph_cell.v - one reconfigurable MorphCPU cell
//
// A cell is the atomic unit of the fabric. It holds 4 bits of configuration:
//
//     cfg[3:2] = op   (what this cell does to data passing through it)
//     cfg[1:0] = dir  (which neighbour this cell hands its result to)
//
// Configuration arrives over a serial shift chain shared by every cell in the
// grid (see grid.v for the chain ordering). Data arrives from any neighbour
// that is routing *at* this cell, is transformed by op, and is presented on
// out_data/out_val for the neighbour named by dir to pick up next tick.
//
// One tick = one hop. A value therefore takes exactly one tick per cell it
// travels through, which is what makes the ripple visible on the LED grid.
//
// Operand selection
// -----------------
// Inputs are scanned in fixed priority order N, E, S, W:
//   * the first valid input is the primary operand (a)
//   * the second valid input, if any, is the secondary operand (b)
//   * if only one input is valid, b falls back to this cell's own held value,
//     which turns ADD into an accumulator when a stream loops or repeats
//
// That gives ADD/XOR a real meaning: two streams converging on one cell are
// combined by it. Convergence is how you build anything more interesting than
// a delay line out of this fabric.
// ---------------------------------------------------------------------------

`timescale 1ns / 1ps
`default_nettype none

module morph_cell #(
    parameter DATA_W = 8
) (
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 clr,         // clear held data, keep config

    // --- configuration shift chain -----------------------------------------
    input  wire                 cfg_shift,   // 1 = advance the chain this clk
    input  wire                 cfg_in,      // serial in  (from previous cell)
    output wire                 cfg_out,     // serial out (to next cell)

    // --- grid advance -------------------------------------------------------
    input  wire                 tick,        // 1 = advance the fabric one hop

    // --- neighbour inputs ---------------------------------------------------
    input  wire [DATA_W-1:0]    in_n_data,
    input  wire                 in_n_val,
    input  wire [DATA_W-1:0]    in_e_data,
    input  wire                 in_e_val,
    input  wire [DATA_W-1:0]    in_s_data,
    input  wire                 in_s_val,
    input  wire [DATA_W-1:0]    in_w_data,
    input  wire                 in_w_val,

    // --- outputs ------------------------------------------------------------
    output wire [DATA_W-1:0]    out_data,
    output wire                 out_val,
    output wire [1:0]           out_dir,     // where out_data is headed
    output wire                 active       // 1 = holding live data (LED tap)
);

    // --- opcode / direction encoding ---------------------------------------
    localparam [1:0] OP_PASS = 2'd0;  // out = a          (pure routing)
    localparam [1:0] OP_INV  = 2'd1;  // out = ~a
    localparam [1:0] OP_ADD  = 2'd2;  // out = a + b      (wraps, no carry out)
    localparam [1:0] OP_XOR  = 2'd3;  // out = a ^ b

    localparam [1:0] DIR_N   = 2'd0;
    localparam [1:0] DIR_E   = 2'd1;
    localparam [1:0] DIR_S   = 2'd2;
    localparam [1:0] DIR_W   = 2'd3;

    // -----------------------------------------------------------------------
    // Configuration register / shift chain
    //
    // Shifts MSB-out, LSB-in: a bit entering cfg_in needs 4 shifts to cross
    // one cell. grid.v relies on that to work out the whole-chain bit order.
    // -----------------------------------------------------------------------
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

    // -----------------------------------------------------------------------
    // Operand selection - first and second valid input, priority N,E,S,W
    // -----------------------------------------------------------------------
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

    // -----------------------------------------------------------------------
    // Held value + ALU
    // -----------------------------------------------------------------------
    reg [DATA_W-1:0] d_reg;
    reg              v_reg;

    // secondary operand: a second arriving stream, else what we already hold
    wire [DATA_W-1:0] b = b_val ? b_in : d_reg;

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
            d_reg <= {DATA_W{1'b0}};
            v_reg <= 1'b0;
        end else if (tick) begin
            v_reg <= a_val;
            if (a_val)
                d_reg <= alu;
        end
    end

    assign out_data = d_reg;
    assign out_val  = v_reg;
    assign out_dir  = dir;
    assign active   = v_reg;

endmodule

`default_nettype wire
