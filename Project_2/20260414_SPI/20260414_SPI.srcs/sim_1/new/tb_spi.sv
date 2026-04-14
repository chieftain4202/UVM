`timescale 1ns / 1ps

module tb_spi_master ();

    logic       clk;
    logic       rst;
    logic [7:0] clk_div;
    logic [7:0] tx_data;
    logic       start;
    logic       miso;
    logic [7:0] rx_data;
    logic       done;
    logic       busy;
    logic       sclk;
    logic       mosi;
    logic       cs_n;

    always #5 clk = ~clk;

    assign miso = mosi;

    SPI_master dut (
        .clk    (clk),
        .rst    (rst),
        .clk_div(clk_div),
        .tx_data(tx_data),
        .start  (start),
        .miso   (miso),
        .rx_data(rx_data),
        .done   (done),
        .busy   (busy),
        .sclk   (sclk),
        .mosi   (mosi),
        .cs_n   (cs_n)
    );



    initial begin
        clk = 0;
        rst = 1;
        repeat (3) @(posedge clk);
        rst = 0;
        @(posedge clk);
        clk_div = 4;
        //miso    = 1'b0;
        @(posedge clk);
        tx_data = 8'haa;
        start   = 1'b1;
        @(posedge clk);
        start = 1'b0;
        @(posedge clk);
        wait (done);
        @(posedge clk);
        #20;
        $finish;
    end
endmodule
