`timescale 1ns / 1ps

module tb_i2c_master ();
    logic       clk;
    logic       rst;
    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;
    logic [7:0] M_tx_data;
    logic [7:0] S_tx_data;
    logic       ack_in;
    logic [7:0] M_rx_data;
    logic [7:0] S_rx_data;
    logic       done;
    logic       ack_out;
    logic       busy;
    logic       scl;
    wire        sda;



    localparam SLA = 8'h12;
    /*
    I2C_Master dut (
        .*,
        .scl(scl),
        .sda(sda)
    );
*/

    top_I2c_MS dut (.*);

    always #5 clk = ~clk;
    assign S_tx_data = 8'b11101110;
    // pullup
    assign scl = 1'b1;
    // assign sda = 1'b1;

    task i2c_start();
        // start
        cmd_start = 1'b1;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        cmd_start = 1'b0;
        wait (done);
        @(posedge clk);
    endtask

    task i2c_addr(byte addr);
        // tx_data = address(8'h12) + rw
        M_tx_data = addr;
        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);
        @(posedge clk);
    endtask

    task i2c_write(byte data);
        M_tx_data = data;
        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);
        @(posedge clk);
    endtask

    task i2c_read();
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b1;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);
        @(posedge clk);
    endtask

    task i2c_stop();
        // stop
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b1;
        @(posedge clk);
        wait (done);
        @(posedge clk);
    endtask

    initial begin
        clk = 0;
        rst = 1;
        S_rx_data = 0;
        repeat (3) @(posedge clk);
        rst = 0;
        @(posedge clk);
        S_tx_data = 8'b11101110;
        i2c_start();
        i2c_addr(7'b1110001);
        i2c_write(8'h55);
        i2c_write(8'haa);
        i2c_read();
        i2c_read();
        i2c_write(8'h03);
        i2c_write(8'h04);
        i2c_write(8'h05);
        i2c_write(8'hff);
        i2c_stop();

        #100;
        $finish;

    end

endmodule
