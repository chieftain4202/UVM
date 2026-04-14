`timescale 1ns / 1ps


module SPI_slave(
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] clk_div,
    input  logic [7:0] tx_data,
    input  logic       start,
    input  logic       miso,
    output logic [7:0] rx_data,
    output logic       done,
    output logic       busy,
    output logic       sclk,
    output logic       mosi,
    output logic       cs_n
    );


endmodule
