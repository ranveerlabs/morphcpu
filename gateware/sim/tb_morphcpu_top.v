`timescale 1ns / 1ps
`default_nettype none

module tb_morphcpu_top;

    localparam real CLK_HZ  = 16_000_000.0;
    localparam integer BAUD = 115_200;

    localparam real HALF_CLK = 31.25;
    localparam real BIT_NS   = 8680.0;

    localparam [7:0] CMD_CONFIG  = 8'h01,
                     CMD_INJECT  = 8'h02,
                     CMD_TICKDIV = 8'h03,
                     CMD_CLEAR   = 8'h04,
                     CMD_STEP    = 8'h05;

    reg         clk = 1'b0;
    reg         rst_n = 1'b1;
    reg         uart_rx_i = 1'b1;
    wire        uart_tx_o;
    wire [15:0] led;

    integer errors = 0;
    integer checks = 0;

    always #HALF_CLK clk = ~clk;

    morphcpu_top dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .uart_rx_i (uart_rx_i),
        .uart_tx_o (uart_tx_o),
        .led       (led)
    );

    task uart_send(input [7:0] b);
        integer i;
        begin
            uart_rx_i = 1'b0;
            #(BIT_NS);
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx_i = b[i];
                #(BIT_NS);
            end
            uart_rx_i = 1'b1;
            #(BIT_NS);
            #(BIT_NS);
        end
    endtask

    task uart_recv(output [7:0] b);
        integer i;
        begin
            @(negedge uart_tx_o);
            #(BIT_NS * 1.5);
            for (i = 0; i < 8; i = i + 1) begin
                b[i] = uart_tx_o;
                #(BIT_NS);
            end
        end
    endtask

    task send_config(input [63:0] cfg);
        integer i;
        begin
            uart_send(CMD_CONFIG);
            for (i = 7; i >= 0; i = i - 1)
                uart_send(cfg[i*8 +: 8]);
        end
    endtask

    task send_inject(input [7:0] row, input [7:0] val);
        begin
            uart_send(CMD_INJECT);
            uart_send(row);
            uart_send(val);
        end
    endtask

    task send_step;
        begin
            uart_send(CMD_STEP);
        end
    endtask

    task send_tickdiv(input [23:0] d);
        begin
            uart_send(CMD_TICKDIV);
            uart_send(d[23:16]);
            uart_send(d[15:8]);
            uart_send(d[7:0]);
        end
    endtask

    task check_byte(input [7:0] got, input [7:0] want, input [511:0] what);
        begin
            checks = checks + 1;
            if (got !== want) begin
                $display("FAIL %0s: got 0x%02x, expected 0x%02x", what, got, want);
                errors = errors + 1;
            end else begin
                $display("  ok  %0s -> 0x%02x", what, got);
            end
        end
    endtask

    reg [7:0] rx;

    initial begin
        $dumpfile("tb_morphcpu_top.vcd");
        $dumpvars(1, tb_morphcpu_top);

        rst_n = 1'b0;
        #2000;
        rst_n = 1'b1;
        #50000;

        send_tickdiv(24'hFFFFFF);

        $display("TEST 1: PASS chain across row 0, driven entirely over UART");

        send_config(64'h1111_0000_0000_0000);

        send_inject(8'd0, 8'hA5);
        send_step;
        send_step;
        send_step;
        fork
            begin
                uart_recv(rx);
                check_byte(rx, 8'hA5, "PASS chain result over UART");
            end
            begin
                send_step;
            end
        join

        $display("TEST 2: INV in the chain");

        send_config(64'h1511_0000_0000_0000);
        send_inject(8'd0, 8'hA5);
        send_step;
        send_step;
        send_step;
        fork
            begin
                uart_recv(rx);
                check_byte(rx, 8'h5A, "INV chain result over UART");
            end
            begin
                send_step;
            end
        join

        $display("TEST 3: ADD convergence across two rows");

        send_config(64'h2000_9111_0000_0000);

        send_inject(8'd0, 8'd200);
        send_step;
        send_inject(8'd1, 8'd100);
        send_step;
        send_step;
        send_step;
        fork
            begin
                uart_recv(rx);

                check_byte(rx, 8'd44, "ADD convergence result over UART");
            end
            begin
                send_step;
            end
        join

        $display("TEST 4: LEDs track fabric activity");
        send_config(64'h1111_0000_0000_0000);
        uart_send(CMD_CLEAR);
        #100000;
        checks = checks + 1;
        if (led !== 16'd0) begin
            $display("FAIL: LEDs not dark after CLEAR, got %b", led);
            errors = errors + 1;
        end else begin
            $display("  ok  all LEDs dark after CLEAR");
        end

        send_inject(8'd0, 8'h77);
        send_step;
        #1000;
        checks = checks + 1;
        if (led[0] !== 1'b1) begin
            $display("FAIL: led[0] not lit after value entered cell 0, got %b", led);
            errors = errors + 1;
        end else begin
            $display("  ok  led[0] lit while cell 0 holds the value");
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
        #40_000_000;
        $display("FAIL: timeout");
        $fatal(1);
    end

endmodule

`default_nettype wire
