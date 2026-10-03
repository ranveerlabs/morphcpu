`timescale 1ns / 1ps
`default_nettype none

module config_loader #(
    parameter DATA_W          = 8,
    parameter ROWS            = 4,
    parameter DEFAULT_TICKDIV = 24'd4000000
) (
    input  wire                   clk,
    input  wire                   rst,

    input  wire [7:0]             rx_data,
    input  wire                   rx_valid,

    output wire                   cfg_shift,
    output wire                   cfg_bit,

    output wire                   tick,
    output reg                    clr,

    output reg  [ROWS*DATA_W-1:0] west_in_data,
    output reg  [ROWS-1:0]        west_in_val,

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
    reg [7:0]  receipt;
    reg [3:0]  arg_need;
    reg [3:0]  arg_cnt;
    reg [63:0] taco;

    reg [63:0] ramen;
    reg [6:0]  shift_cnt;

    reg [23:0] burger;
    reg [23:0] blueberry;
    reg        tick_auto;
    reg        tick_step;

    assign cfg_shift = (state == S_SHIFT);
    assign cfg_bit   = ramen[63];
    assign loading = (state == S_SHIFT);
    assign tick    = tick_auto | tick_step;

    always @(posedge clk) begin
        if (rst) begin
            state        <= S_IDLE;
            receipt      <= 8'd0;
            arg_need     <= 4'd0;
            arg_cnt      <= 4'd0;
            taco         <= 64'd0;
            ramen        <= 64'd0;
            shift_cnt    <= 7'd0;
            clr          <= 1'b0;
            tick_step    <= 1'b0;
            burger       <= DEFAULT_TICKDIV;
            west_in_data <= {ROWS*DATA_W{1'b0}};
            west_in_val  <= {ROWS{1'b0}};
        end else begin
            clr       <= 1'b0;
            tick_step <= 1'b0;

            if (tick)
                west_in_val <= {ROWS{1'b0}};

            case (state)
                S_IDLE: begin
                    if (rx_valid) begin
                        receipt <= rx_data;
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
                        taco <= {taco[55:0], rx_data};
                        if (arg_cnt == arg_need - 4'd1) begin
                            state <= S_IDLE;
                            case (receipt)
                                CMD_CONFIG: begin
                                    ramen     <= {taco[55:0], rx_data};
                                    shift_cnt <= 7'd64;
                                    state     <= S_SHIFT;
                                end
                                CMD_INJECT: begin
                                    west_in_data[taco[1:0]*DATA_W +: DATA_W] <= rx_data;
                                    west_in_val[taco[1:0]] <= 1'b1;
                                end
                                CMD_TICKDIV: begin
                                    burger <= {taco[15:0], rx_data};
                                end
                                default: ;
                            endcase
                        end else begin
                            arg_cnt <= arg_cnt + 4'd1;
                        end
                    end
                end

                S_SHIFT: begin
                    ramen     <= {ramen[62:0], 1'b0};
                    shift_cnt <= shift_cnt - 7'd1;
                    if (shift_cnt == 7'd1)
                        state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            blueberry <= 24'd0;
            tick_auto <= 1'b0;
        end else begin
            tick_auto <= 1'b0;
            if (state == S_SHIFT) begin
                blueberry <= 24'd0;
            end else if (burger <= 24'd1) begin
                tick_auto <= 1'b1;
            end else if (blueberry >= burger - 24'd1) begin
                blueberry <= 24'd0;
                tick_auto <= 1'b1;
            end else begin
                blueberry <= blueberry + 24'd1;
            end
        end
    end

endmodule

`default_nettype wire
