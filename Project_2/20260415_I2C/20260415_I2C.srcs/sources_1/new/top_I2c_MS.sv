`timescale 1ns / 1ps


module top_I2c_MS (
    input  logic       clk,
    input  logic       rst,
    input  logic       cmd_start,
    input  logic       cmd_write,
    input  logic       cmd_read,
    input  logic       cmd_stop,
    input  logic [7:0] M_tx_data,
    input  logic [7:0] S_tx_data,
    output logic [7:0] M_rx_data,
    output logic       done
);


    logic [7:0] counter;
    //logic [7:0] S_tx_data;
    logic       ack_in;  //master가 받는 것
    logic [7:0] S_rx_data;
    logic       ack_out;  //master가 주는 것 
    logic       busy;
    logic       scl;
    wire        sda;

    pullup(sda);

    i2c_slave U_I2c_Slave (
        .*,
        .tx_data(S_tx_data),
        .rx_data(S_rx_data)

    );


    I2C_Master U_I2C_Master (
        .clk(clk),
        .rst(rst),
        .*,
        .scl(scl),
        .sda(sda)
    );
endmodule
