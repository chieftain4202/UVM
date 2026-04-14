`timescale 1ns / 1ps

module SPI_master (
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
    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START,
        DATA,
        STOP
    } spi_state_e;

    spi_state_e state;
    logic [7:0] div_cnt, tx_shift_reg, rx_shift_reg;
    logic [2:0] bit_cnt;
    logic half_tick;


    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            div_cnt   <= 0;
            half_tick <= 1'b0;
        end else begin
            if (div_cnt == clk_div) begin
                div_cnt   <= 0;
                half_tick <= 1'b1;
            end else begin
                div_cnt   <= div_cnt + 1;
                half_tick <= 1'b0;
            end

        end

    end


    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            mosi         <= 1'b1;
            cs_n         <= 1'b1;
            busy         <= 1'b0;
            done         <= 1'b0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            bit_cnt <= 0;

        end else begin

        end

    end



endmodule
