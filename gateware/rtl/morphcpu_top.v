// morphcpu_top.v - top level for the iCE40UP5K-SG48
// ties the fabric to the outside world:
//   16 MHz oscillator ---> clk
//   FT231X TXD     ---> uart_rx_i   (host -> board: config, inject, control)
//   FT231X RXD     <--- uart_tx_o   (board -> host: east-edge results)
//   reset button   ---> rst_n       (active low, external pull-up)
//   16 LEDs        <--- led[15:0]   (one per cell, cell 0 = led[0])
// two deliberate choices worth knowing abt.
// the fabric tick defaults to 4 Hz, not 16 MHz. whole point of the board is
// watching data ripple across the LED grid and a hop every 83 ns is invisible.
// send TICKDIV to speed it up, or drive it by hand with STEP.
// LEDs are pulse-stretched to ~150 ms. even at a slow tick a cell is only
// active for one tick, and without stretching a fast tick just looks like a
// uniform dim glow. stretching keeps the ripple legible at any rate.
// east-edge results get latched at tick and drained to the UART one byte at a
// time. at the default tick rate theres ~3M clocks between ticks and a byte
// costs ~1042, so the link keeps up easily. set TICKDIV to full speed and the
// fabric outruns 115200 baud and results get dropped. thats expected, and its
// why STEP exists.

`timescale 1ns / 1ps
`default_nettype none

module morphcpu_top #(
    parameter CLK_HZ = 16_000_000,
    parameter BAUD   = 115_200,
    parameter DATA_W = 8,
    parameter ROWS   = 4,
    parameter COLS   = 4,
    // 0 = LED anode on the FPGA pin, cathode to GND via a resistor (pin
    //     sources current, a high lights it).
    // 1 = cathode on the pin, anode to 3V3 via a resistor (pin sinks).
    // The schematic decides this; flipping it here is cheaper than a respin.
    parameter LED_ACTIVE_LOW = 0
) (
    input  wire        clk,          // 16 MHz oscillator (XO module)
    input  wire        rst_n,        // reset button, active low
    input  wire        uart_rx_i,    // from FT231X TXD
    output wire        uart_tx_o,    // to   FT231X RXD
    output wire [15:0] led           // 4x4 status grid
);

    // Power-on reset + button. iCE40 flip-flops come out of configuration
    // zeroed, so the counter starts at 0 and holds reset until it saturates.
    reg [7:0] por_cnt = 8'd0;
    wire      por_done = &por_cnt;

    always @(posedge clk) begin
        if (!por_done)
            por_cnt <= por_cnt + 8'd1;
    end

    reg btn_m, btn_s;
    always @(posedge clk) begin
        btn_m <= rst_n;
        btn_s <= btn_m;
    end

    wire rst = !por_done || !btn_s;

    // UART
    wire [7:0] rx_data;
    wire       rx_valid;
    wire       rx_frame_err;

    uart_rx #(
        .CLK_HZ   (CLK_HZ),
        .BAUD     (BAUD)
    ) u_rx (
        .clk      (clk),
        .rst      (rst),
        .rx       (uart_rx_i),
        .data     (rx_data),
        .valid    (rx_valid),
        .frame_err(rx_frame_err)
    );

    reg  [7:0] tx_byte;
    reg        tx_send;
    wire       tx_busy;

    uart_tx #(
        .CLK_HZ (CLK_HZ),
        .BAUD   (BAUD)
    ) u_tx (
        .clk    (clk),
        .rst    (rst),
        .data   (tx_byte),
        .send   (tx_send),
        .tx     (uart_tx_o),
        .busy   (tx_busy)
    );

    // Command decode / configuration
    wire                   cfg_shift;
    wire                   cfg_bit;
    wire                   tick;
    wire                   clr;
    wire [ROWS*DATA_W-1:0] west_in_data;
    wire [ROWS-1:0]        west_in_val;
    wire                   loading;

    config_loader #(
        .DATA_W      (DATA_W),
        .ROWS        (ROWS)
    ) u_cfg (
        .clk         (clk),
        .rst         (rst),
        .rx_data     (rx_data),
        .rx_valid    (rx_valid),
        .cfg_shift   (cfg_shift),
        .cfg_bit     (cfg_bit),
        .tick        (tick),
        .clr         (clr),
        .west_in_data(west_in_data),
        .west_in_val (west_in_val),
        .loading     (loading)
    );

    // The fabric
    wire [ROWS*DATA_W-1:0] east_out_data;
    wire [ROWS-1:0]        east_out_val;
    wire [ROWS*COLS-1:0]   cell_active;

    grid #(
        .DATA_W       (DATA_W),
        .ROWS         (ROWS),
        .COLS         (COLS)
    ) u_grid (
        .clk          (clk),
        .rst          (rst),
        .clr          (clr),
        .cfg_shift    (cfg_shift),
        .cfg_in       (cfg_bit),
        .cfg_out      (),
        .tick         (tick),
        .west_in_data (west_in_data),
        .west_in_val  (west_in_val),
        .east_out_data(east_out_data),
        .east_out_val (east_out_val),
        .active       (cell_active)
    );

    // East-edge results -> UART, one row at a time, lowest row first
    reg [ROWS-1:0]        pend;
    reg [ROWS*DATA_W-1:0] pend_data;

    // The fabric registers update on the tick edge, so east_out_* only shows
    // the post-tick state on the following cycle. Sampling on tick itself
    // captures the previous hop's result, one tick stale, every time.
    reg tick_d;
    always @(posedge clk) begin
        if (rst || clr) tick_d <= 1'b0;
        else            tick_d <= tick;
    end

    wire [1:0] nxt_row = pend[0] ? 2'd0 :
                         pend[1] ? 2'd1 :
                         pend[2] ? 2'd2 : 2'd3;

    always @(posedge clk) begin
        if (rst || clr) begin
            pend      <= {ROWS{1'b0}};
            pend_data <= {ROWS*DATA_W{1'b0}};
            tx_send   <= 1'b0;
            tx_byte   <= 8'd0;
        end else begin
            tx_send <= 1'b0;
            if (tick_d) begin
                pend      <= east_out_val;
                pend_data <= east_out_data;
            end else if (|pend && !tx_busy && !tx_send) begin
                tx_byte     <= pend_data[nxt_row*DATA_W +: DATA_W];
                tx_send     <= 1'b1;
                pend[nxt_row] <= 1'b0;
            end
        end
    end

    // LED pulse stretch. A shared ~5 ms strobe decrements a 4-bit counter per
    // cell; a cell going active reloads its counter to full. 16 x 4 bits of
    // state instead of 16 wide counters.
    localparam integer STRETCH_DIV = CLK_HZ / 200;   // ~5 ms

    reg [16:0] str_cnt = 17'd0;
    wire       str_tick = (str_cnt == STRETCH_DIV[16:0] - 1);

    always @(posedge clk) begin
        if (str_tick)
            str_cnt <= 17'd0;
        else
            str_cnt <= str_cnt + 17'd1;
    end

    genvar gi;
    generate
        for (gi = 0; gi < ROWS*COLS; gi = gi + 1) begin : glow
            reg [3:0] hold = 4'd0;
            always @(posedge clk) begin
                if (rst || clr)
                    hold <= 4'd0;
                else if (cell_active[gi])
                    hold <= 4'hF;
                else if (str_tick && hold != 4'd0)
                    hold <= hold - 4'd1;
            end
            assign led[gi] = LED_ACTIVE_LOW ? ~(hold != 4'd0) : (hold != 4'd0);
        end
    endgenerate

endmodule

`default_nettype wire
