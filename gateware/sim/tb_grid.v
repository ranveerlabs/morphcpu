`timescale 1ns / 1ps
`default_nettype none

module tb_grid;

    localparam DATA_W = 8;
    localparam ROWS   = 4;
    localparam COLS   = 4;

    localparam [1:0] OP_PASS = 2'd0, OP_INV = 2'd1, OP_ADD = 2'd2, OP_XOR = 2'd3;
    localparam [1:0] DIR_N   = 2'd0, DIR_E  = 2'd1, DIR_S  = 2'd2, DIR_W  = 2'd3;

    reg                     clk = 1'b0;
    reg                     rst = 1'b1;
    reg                     clr = 1'b0;
    reg                     cfg_shift = 1'b0;
    reg                     cfg_in = 1'b0;
    wire                    cfg_out;
    reg                     tick = 1'b0;
    reg  [ROWS*DATA_W-1:0]  west_in_data = 0;
    reg  [ROWS-1:0]         west_in_val  = 0;
    wire [ROWS*DATA_W-1:0]  east_out_data;
    wire [ROWS-1:0]         east_out_val;
    wire [ROWS*COLS-1:0]    active;

    integer errors = 0;
    integer checks = 0;

    always #5 clk = ~clk;

    grid #(
        .DATA_W       (DATA_W),
        .ROWS         (ROWS),
        .COLS         (COLS)
    ) dut (
        .clk          (clk),
        .rst          (rst),
        .clr          (clr),
        .cfg_shift    (cfg_shift),
        .cfg_in       (cfg_in),
        .cfg_out      (cfg_out),
        .tick         (tick),
        .west_in_data (west_in_data),
        .west_in_val  (west_in_val),
        .east_out_data(east_out_data),
        .east_out_val (east_out_val),
        .active       (active)
    );

    reg [63:0] cfgw;

    task cfg_clear;
        begin
            cfgw = 64'd0;
        end
    endtask

    task set_cell(input integer idx, input [1:0] op, input [1:0] dir);
        begin
            cfgw[(60 - 4*idx) +: 4] = {op, dir};
        end
    endtask

    task load_cfg;
        integer k;
        begin
            for (k = 63; k >= 0; k = k - 1) begin
                @(negedge clk);
                cfg_in    = cfgw[k];
                cfg_shift = 1'b1;
            end
            @(negedge clk);
            cfg_shift = 1'b0;
            cfg_in    = 1'b0;
        end
    endtask

    task do_tick;
        begin
            @(negedge clk);
            tick = 1'b1;
            @(negedge clk);
            tick = 1'b0;
        end
    endtask

    task inject(input integer row, input [7:0] val);
        begin
            @(negedge clk);
            west_in_data[row*DATA_W +: DATA_W] = val;
            west_in_val[row]                   = 1'b1;
            do_tick;
            west_in_val[row]                   = 1'b0;
        end
    endtask

    task reset_fabric;
        begin
            @(negedge clk);
            clr = 1'b1;
            @(negedge clk);
            clr = 1'b0;
        end
    endtask

    task expect_east(input integer row, input [7:0] val, input [511:0] what);
        begin
            checks = checks + 1;
            if (east_out_val[row] !== 1'b1) begin
                $display("FAIL %0s: east_out_val[%0d] = %b, expected 1",
                         what, row, east_out_val[row]);
                errors = errors + 1;
            end else if (east_out_data[row*DATA_W +: DATA_W] !== val) begin
                $display("FAIL %0s: east row %0d = 0x%02x, expected 0x%02x",
                         what, row, east_out_data[row*DATA_W +: DATA_W], val);
                errors = errors + 1;
            end else begin
                $display("  ok  %0s -> row %0d = 0x%02x", what, row, val);
            end
        end
    endtask

    task expect_no_east(input integer row, input [511:0] what);
        begin
            checks = checks + 1;
            if (east_out_val[row] !== 1'b0) begin
                $display("FAIL %0s: east_out_val[%0d] asserted early", what, row);
                errors = errors + 1;
            end else begin
                $display("  ok  %0s -> row %0d still quiet", what, row);
            end
        end
    endtask

    integer t;
    initial begin
        $dumpfile("tb_grid.vcd");
        $dumpvars(0, tb_grid);

        repeat (4) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);

        $display("TEST 1: straight PASS chain across row 0");
        cfg_clear;
        set_cell(0, OP_PASS, DIR_E);
        set_cell(1, OP_PASS, DIR_E);
        set_cell(2, OP_PASS, DIR_E);
        set_cell(3, OP_PASS, DIR_E);
        load_cfg;

        inject(0, 8'hA5);
        expect_no_east(0, "after 1 tick");
        do_tick;
        expect_no_east(0, "after 2 ticks");
        do_tick;
        expect_no_east(0, "after 3 ticks");
        do_tick;
        expect_east(0, 8'hA5, "PASS chain, 4 ticks");
        do_tick;
        expect_no_east(0, "value has left the fabric");
        reset_fabric;

        $display("TEST 2: INV in the middle of the chain");
        cfg_clear;
        set_cell(0, OP_PASS, DIR_E);
        set_cell(1, OP_INV,  DIR_E);
        set_cell(2, OP_PASS, DIR_E);
        set_cell(3, OP_PASS, DIR_E);
        load_cfg;

        inject(0, 8'hA5);
        repeat (3) do_tick;
        expect_east(0, 8'h5A, "INV chain gives complement of 0xA5");
        reset_fabric;

        $display("TEST 3: XOR convergence, two streams meeting in cell 4");
        cfg_clear;
        set_cell(0, OP_PASS, DIR_S);
        set_cell(4, OP_XOR,  DIR_E);
        set_cell(5, OP_PASS, DIR_E);
        set_cell(6, OP_PASS, DIR_E);
        set_cell(7, OP_PASS, DIR_E);
        load_cfg;

        inject(0, 8'hF0);
        inject(1, 8'h3C);
        repeat (3) do_tick;
        expect_east(1, 8'hF0 ^ 8'h3C, "XOR convergence");
        reset_fabric;

        $display("TEST 4: ADD convergence, same topology");
        cfg_clear;
        set_cell(0, OP_PASS, DIR_S);
        set_cell(4, OP_ADD,  DIR_E);
        set_cell(5, OP_PASS, DIR_E);
        set_cell(6, OP_PASS, DIR_E);
        set_cell(7, OP_PASS, DIR_E);
        load_cfg;

        inject(0, 8'd200);
        inject(1, 8'd100);
        repeat (3) do_tick;
        expect_east(1, 8'd44, "ADD convergence wraps at 8 bits");
        reset_fabric;

        $display("TEST 5: configuration survives a data clear");
        inject(0, 8'd1);
        inject(1, 8'd2);
        repeat (3) do_tick;
        expect_east(1, 8'd3, "ADD topology still loaded after clear");

        $display("TEST 6: activity taps follow the value across the row");
        cfg_clear;
        set_cell(0, OP_PASS, DIR_E);
        set_cell(1, OP_PASS, DIR_E);
        set_cell(2, OP_PASS, DIR_E);
        set_cell(3, OP_PASS, DIR_E);
        load_cfg;
        reset_fabric;

        inject(0, 8'h11);
        for (t = 0; t < 4; t = t + 1) begin
            checks = checks + 1;
            if (active !== (16'd1 << t)) begin
                $display("FAIL activity: tick %0d expected only cell %0d lit, got %b",
                         t+1, t, active);
                errors = errors + 1;
            end else begin
                $display("  ok  tick %0d -> only cell %0d lit", t+1, t);
            end
            if (t < 3) do_tick;
        end

        $display("");
        if (errors == 0)
            $display("PASS: %0d/%0d checks", checks, checks);
        else
            $display("FAIL: %0d of %0d checks failed", errors, checks);
        $display("");
        if (errors != 0) $fatal(1);
        $finish;
    end

    initial begin
        #500000;
        $display("FAIL: timeout");
        $fatal(1);
    end

endmodule

`default_nettype wire
