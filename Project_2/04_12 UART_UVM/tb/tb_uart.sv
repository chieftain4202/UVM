`include "uvm_macros.svh"
import uvm_pkg::*;

`include "uart_interface.sv"
`include "uart_seq_item.sv"
`include "uart_sequencer.sv"
`include "uart_drive.sv"
`include "uart_monitor.sv"
`include "uart_agent.sv"
`include "uart_scoreboard.sv"
`include "uart_coverage.sv"
`include "uart_env.sv"
`include "uart_test.sv"

module tb_uart ();
    logic clk;
    logic rst;

    always #5 clk = ~clk;

    uart_if vif (
        clk,
        rst
    );

    uart_top dut (
        .clk         (clk),
        .rst         (rst),
        .uart_rx     (vif.uart_rx),
        .baud_tick   (vif.baud_tick),
        .uart_tx     (vif.uart_tx),
        .uart_rx_data(vif.uart_rx_data),
        .uart_rx_done(vif.uart_rx_done),
        .done_tx     (vif.done_tx),
        .busy_tx     (vif.busy_tx)
    );

    initial begin
        clk = 0;
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
    end

    initial begin
        uvm_config_db#(virtual uart_if)::set(null, "*", "vif", vif);
        run_test();
    end

    initial begin
        $fsdbDumpfile("novas.fsdb");
        $fsdbDumpvars(0, tb_uart, "+all");
    end

endmodule
