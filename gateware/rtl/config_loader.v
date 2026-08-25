// config_loader.v - host command decoder + fabric configuration shifter
// wire protocol, 8N1 UART, one command byte then a fixed argument count:
//   0x01 CONFIG  + 8 bytes  load the whole 4x4 topology. bytes are shifted
//                           into the grid 64-bit chain MSB first, so:
//                             byte i upper nibble -> cell (2i)
//                             byte i lower nibble -> cell (2i + 1)
//                           and each nibble is {op[1:0], dir[1:0]}.
//                             op : 0=PASS 1=INV 2=ADD 3=XOR
//                             dir: 0=N    1=E   2=S   3=W
//   0x02 INJECT  + 2 bytes  [row, value] - present the value at the west edge
//                           of row (0-3) til the next tick consumes it.
//   0x03 TICKDIV + 3 bytes  24-bit big-endian clock divider for the fabric
//                           tick. a value <= 1 means run at full clock rate.
//                           default is slow on purpose, see morphcpu_top.
//   0x04 CLEAR   + 0 bytes  drop all in-flight data. config survives.
//   0x05 STEP    + 0 bytes  advance the fabric exactly one tick, so a value
//                           can be hand-walked across the grid for a demo.
// unknown command bytes are ignored, which makes resyncing from a half-sent
// command cheap. send 0x04 and carry on.

`timescale 1ns / 1ps
`default_nettype none

module config_loader #(
    parameter DATA_W          = 8,
    parameter ROWS            = 4,
    parameter DEFAULT_TICKDIV = 24'd4000000   // 16 MHz / 4e6 = 4 ticks/sec
) (
    input  wire                   clk,
    input  wire                   rst,

    // from uart_rx
    input  wire [7:0]             rx_data,
    input  wire                   rx_valid,

    // to the grid configuration chain
    output wire                   cfg_shift,
    output wire                   cfg_bit,

    // fabric control
    output wire                   tick,
    output reg                    clr,

    // west edge injection
    output reg  [ROWS*DATA_W-1:0] west_in_data,
    output reg  [ROWS-1:0]        west_in_val,

    // status
    output wire                   loading
);

    localparam [7:0] CMD_CONFIG  = 8'h01,
                     CMD_INJECT  = 8'h02,
                     CMD_TICKDIV = 8'h03,
                     CMD_CLEAR   = 8'h04,
                     CMD_STEP    = 8'h05;

    localparam [1:0] S_IDLE  = 2'd0,
                     S_ARG   = 2'd1,
                     S_SHIFT = 2'd2;

    reg [1:0]  state;
    reg [7:0]  cmd;
    reg [3:0]  arg_need;
    reg [3:0]  arg_cnt;
    reg [63:0] argbuf;

    reg [63:0] cfg_sr;
    reg [6:0]  shift_cnt;

    reg [23:0] tickdiv;
    reg [23:0] tickcnt;
    reg        tick_auto;
    reg        tick_step;

    assign cfg_shift = (state == S_SHIFT);
    assign cfg_bit   = cfg_sr[63];
    assign loading = (state == S_SHIFT);
    assign tick    = tick_auto | tick_step;

    // Command FSM
    always @(posedge clk) begin
        if (rst) begin
            state        <= S_IDLE;
            cmd          <= 8'd0;
            arg_need     <= 4'd0;
            arg_cnt      <= 4'd0;
            argbuf       <= 64'd0;
            cfg_sr       <= 64'd0;
            shift_cnt    <= 7'd0;
            clr          <= 1'b0;
            tick_step    <= 1'b0;
            tickdiv      <= DEFAULT_TICKDIV;
            west_in_data <= {ROWS*DATA_W{1'b0}};
            west_in_val  <= {ROWS{1'b0}};
        end else begin
            clr       <= 1'b0;
            tick_step <= 1'b0;

            // An injected value stays presented until a tick consumes it.
            if (tick)
                west_in_val <= {ROWS{1'b0}};

            case (state)
                S_IDLE: begin
                    if (rx_valid) begin
                        cmd     <= rx_data;
                        arg_cnt <= 4'd0;
                        case (rx_data)
                            CMD_CONFIG:  begin arg_need <= 4'd8; state <= S_ARG; end
                            CMD_INJECT:  begin arg_need <= 4'd2; state <= S_ARG; end
                            CMD_TICKDIV: begin arg_need <= 4'd3; state <= S_ARG; end
                            CMD_CLEAR:   clr       <= 1'b1;
                            CMD_STEP:    tick_step <= 1'b1;
                            default:     ;
                        endcase
                    end
                end

                S_ARG: begin
                    if (rx_valid) begin
                        argbuf <= {argbuf[55:0], rx_data};
                        if (arg_cnt == arg_need - 4'd1) begin
                            state <= S_IDLE;
                            case (cmd)
                                CMD_CONFIG: begin
                                    cfg_sr    <= {argbuf[55:0], rx_data};
                                    shift_cnt <= 7'd64;
                                    state     <= S_SHIFT;
                                end
                                CMD_INJECT: begin
                                    west_in_data[argbuf[1:0]*DATA_W +: DATA_W] <= rx_data;
                                    west_in_val[argbuf[1:0]] <= 1'b1;
                                end
                                CMD_TICKDIV: begin
                                    tickdiv <= {argbuf[15:0], rx_data};
                                end
                                default: ;
                            endcase
                        end else begin
                            arg_cnt <= arg_cnt + 4'd1;
                        end
                    end
                end

                S_SHIFT: begin
                    cfg_sr    <= {cfg_sr[62:0], 1'b0};
                    shift_cnt <= shift_cnt - 7'd1;
                    if (shift_cnt == 7'd1)
                        state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    // Fabric tick generator. Paused while configuration is shifting in, so a
    // half-loaded topology never gets to move data around.
    always @(posedge clk) begin
        if (rst) begin
            tickcnt   <= 24'd0;
            tick_auto <= 1'b0;
        end else begin
            tick_auto <= 1'b0;
            if (state == S_SHIFT) begin
                tickcnt <= 24'd0;
            end else if (tickdiv <= 24'd1) begin
                tick_auto <= 1'b1;
            end else if (tickcnt >= tickdiv - 24'd1) begin
                tickcnt   <= 24'd0;
                tick_auto <= 1'b1;
            end else begin
                tickcnt <= tickcnt + 24'd1;
            end
        end
    end

endmodule

`default_nettype wire
