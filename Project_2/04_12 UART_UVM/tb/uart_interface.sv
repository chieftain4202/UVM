interface uart_if (
    input logic clk,
    input logic rst
);

    logic       uart_rx;
    logic       baud_tick;
    logic       uart_tx;
    logic [7:0] uart_rx_data;
    logic       uart_rx_done;
    logic       done_tx;
    logic       busy_tx;


    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        input  baud_tick;
        input  done_tx;
        input  busy_tx;
        output uart_rx;

    endclocking


    clocking mon_cb @(posedge clk);
        default input #1step output #0;
        input baud_tick;
        input uart_rx_data;
        input uart_rx_done;
        input uart_tx;
        input done_tx;
        input busy_tx;

    endclocking


    modport mod_drv(clocking drv_cb, input clk, input rst);
    modport mod_mon(clocking mon_cb, input clk, input rst);
endinterface  //
