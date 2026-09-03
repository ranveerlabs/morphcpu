`timescale 1ns / 1ps
`default_nettype none

module uart_rx #(
    parameter CLK_HZ = 16_000_000,
    parameter BAUD   = 115_200
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] data,
    output reg        valid,
    output reg        frame_err
);

    localparam integer CLKS_PER = CLK_HZ / BAUD;
    localparam integer HALF     = CLKS_PER / 2;

    localparam [1:0] S_IDLE = 2'd0,
                     S_START= 2'd1,
                     S_DATA = 2'd2,
                     S_STOP = 2'd3;

    reg [1:0]  state;
    reg [15:0] cnt;
    reg [2:0]  bitn;
    reg [7:0]  sh;

    reg rx_m, rx_s;
    always @(posedge clk) begin
        rx_m <= rx;
        rx_s <= rx_m;
    end

    always @(posedge clk) begin
        if (rst) begin
            state     <= S_IDLE;
            cnt       <= 16'd0;
            bitn      <= 3'd0;
            sh        <= 8'd0;
            data      <= 8'd0;
            valid     <= 1'b0;
            frame_err <= 1'b0;
        end else begin
            valid     <= 1'b0;
            frame_err <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (!rx_s) begin
                        state <= S_START;
                        cnt   <= 16'd0;
                    end
                end

                S_START: begin
                    if (cnt == HALF[15:0] - 1) begin
                        if (!rx_s) begin
                            state <= S_DATA;
                            cnt   <= 16'd0;
                            bitn  <= 3'd0;
                        end else begin
                            state <= S_IDLE;
                        end
                    end else begin
                        cnt <= cnt + 16'd1;
                    end
                end

                S_DATA: begin
                    if (cnt == CLKS_PER[15:0] - 1) begin
                        cnt        <= 16'd0;
                        sh         <= {rx_s, sh[7:1]};
                        if (bitn == 3'd7)
                            state <= S_STOP;
                        else
                            bitn  <= bitn + 3'd1;
                    end else begin
                        cnt <= cnt + 16'd1;
                    end
                end

                S_STOP: begin
                    if (cnt == CLKS_PER[15:0] - 1) begin
                        cnt   <= 16'd0;
                        state <= S_IDLE;
                        if (rx_s) begin
                            data  <= sh;
                            valid <= 1'b1;
                        end else begin
                            frame_err <= 1'b1;
                        end
                    end else begin
                        cnt <= cnt + 16'd1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule

`default_nettype wire
