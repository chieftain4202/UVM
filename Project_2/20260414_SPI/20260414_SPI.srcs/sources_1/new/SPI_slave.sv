`timescale 1ns / 1ps


module SPI_slave (
    input  logic       clk,
    input  logic       sclk,
    input  logic       rst,
    input  logic       mosi,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       miso,
    output logic       cs_n
);

    logic edge_d;
    logic e_rise, e_fall;
    logic [7:0] tx_shift_reg, rx_shift_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_d <= 0;
        end else begin
            edge_d <= sclk;
        end
    end

    assign e_rise  = ~edge_d & sclk;
    assign e_fall  = ~sclk & edge_d;

    assign tx_data = tx_shift_reg;
    assign rx_data = rx_shift_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (cs_n == 1'b0) begin
            if (e_rise) begin
                miso         <= rx_shift_reg[7];
                rx_shift_reg <= {rx_shift_reg[6:0], 1'b0};
            end else begin
                if (e_fall) begin
                    tx_shift_reg <= {tx_shift_reg[6:0], mosi};
                end
            end
        end

    end

endmodule
