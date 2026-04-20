`timescale 1ns / 1ps

module tb_spi_master ();

    logic       clk;
    logic       rst;
    logic [7:0] clk_div;
    logic [7:0] tx_data;
    logic       cpol;
    logic       cpha;
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
        .cpol   (cpol),
        .cpha   (cpha),
        .start  (start),
        .miso   (miso),
        .rx_data(rx_data),
        .done   (done),
        .busy   (busy),
        .sclk   (sclk),
        .mosi   (mosi),
        .cs_n   (cs_n)
    );

    task spi_set_mode(logic [1:0] mode);
        {cpol, cpha} = mode;
        @(posedge clk);
        
    endtask //spi_set_od

    task spi_send_data(logic [7:0] data);
        tx_data = data;
        start   = 1'b1;
        @(posedge clk);
        start = 1'b0;
        @(posedge clk);
        wait (done);
        @(posedge clk);
    endtask  //spi_send_data(logic [7:0] data)




    initial begin
        clk = 0;
        rst = 1;
        repeat (3) @(posedge clk);
        rst = 0;
        @(posedge clk);
        clk_div = 4;  // SCLK = 10Mhz : (100mhz / 10mhz * 2) - 1
        //miso    = 1'b0;
        @(posedge clk);

        spi_set_mode(0);
        spi_send_data(8'haa);

        spi_set_mode(1);
        spi_send_data(8'hbb);

        spi_set_mode(2);
        spi_send_data(8'hcc);

        spi_set_mode(3);
        spi_send_data(8'hdd);



        @(posedge clk);
        #20;
        $finish;
    end
endmodule
