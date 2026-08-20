// ---------------------------------------------------------------------------
// uart_tx.v - 8N1 UART transmitter
//
// Results leaving the fabric's east edge go out through here to the host.
// busy is held for the whole frame; a send asserted while busy is ignored,
// so the caller must check busy (morphcpu_top queues east-edge results in a
// small FIFO for exactly this reason).
// ---------------------------------------------------------------------------

`timescale 1ns / 1ps
`default_nettype none

module uart_tx #(
    parameter CLK_HZ = 16_000_000,
    parameter BAUD   = 115_200
) (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] data,
    input  wire       send,     // 1-clock strobe
    output reg        tx,       // idles high
    output wire       busy
);

    localparam integer CLKS_PER = CLK_HZ / BAUD;

    reg [15:0] cnt;
    reg [3:0]  bitn;
    reg [9:0]  sh;      // {stop, data[7:0], start}
    reg        active;

    assign busy = active;

    always @(posedge clk) begin
        if (rst) begin
            tx     <= 1'b1;
            cnt    <= 16'd0;
            bitn   <= 4'd0;
            sh     <= 10'h3FF;
            active <= 1'b0;
        end else if (!active) begin
            tx <= 1'b1;
            if (send) begin
                sh     <= {1'b1, data, 1'b0};
                active <= 1'b1;
                cnt    <= 16'd0;
                bitn   <= 4'd0;
                tx     <= 1'b0;          // start bit goes out immediately
            end
        end else begin
            if (cnt == CLKS_PER[15:0] - 1) begin
                cnt  <= 16'd0;
                if (bitn == 4'd9) begin
                    active <= 1'b0;
                    tx     <= 1'b1;
                end else begin
                    bitn <= bitn + 4'd1;
                    tx   <= sh[bitn + 4'd1];
                end
            end else begin
                cnt <= cnt + 16'd1;
            end
        end
    end

endmodule

`default_nettype wire
