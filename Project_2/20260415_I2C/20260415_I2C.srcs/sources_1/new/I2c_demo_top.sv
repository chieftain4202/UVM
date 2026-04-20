`timescale 1ns / 1ps

module I2c_demo_top (
    input logic clk,
    input logic rst,
    input logic sw

);

    typedef enum logic [2:0] {
        IDLE  = 0,
        START,
        ADDR,
        WRITE,
        STOP

    } i2c_state_e;

    localparam SLA_W = {7'h12, 1'b0};
    i2c_state_e       state;

    logic       [7:0] counter;
    logic             cmd_start;
    logic             cmd_write;
    logic             cmd_read;
    logic             cmd_stop;
    logic       [7:0] M_tx_data;
    logic       [7:0] S_tx_data;
    logic             ack_in;  //master가 받는 것
    logic       [7:0] M_rx_data;
    logic       [7:0] S_rx_data;
    logic             done;
    logic             ack_out;  //master가 주는 것 
    logic             busy;
    logic             scl;
    wire              sda;


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

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            counter   <= 0;
            state     <= IDLE;
            cmd_start <= 0;
            cmd_write <= 0;
            cmd_read  <= 0;
            cmd_stop  <= 0;
            M_tx_data   <= 0;
        end else begin
            case (state)
                IDLE: begin
                    cmd_start <= 0;
                    cmd_write <= 0;
                    cmd_read  <= 0;
                    cmd_stop  <= 0;
                    if (sw) begin
                        state <= START;
                    end
                end

                START: begin
                    cmd_start <= 1;
                    cmd_write <= 0;
                    cmd_read  <= 0;
                    cmd_stop  <= 0;
                    if (done) begin
                        state <= ADDR;
                    end
                end

                ADDR: begin
                    cmd_start <= 0;
                    cmd_write <= 1;
                    cmd_read  <= 0;
                    cmd_stop  <= 0;
                    M_tx_data   <= SLA_W;
                    if (done) begin
                        state <= WRITE;
                    end
                end

                WRITE: begin
                    cmd_start <= 0;
                    cmd_write <= 1;
                    cmd_read  <= 0;
                    cmd_stop  <= 0;
                    M_tx_data   <= counter;
                    if (done) begin
                        state <= STOP;
                    end
                end

                STOP: begin
                    cmd_start <= 0;
                    cmd_write <= 0;
                    cmd_read  <= 0;
                    cmd_stop  <= 1;
                    if (done) begin
                        state   <= IDLE;
                        counter <= counter + 1;
                    end
                end

            endcase
        end
    end
endmodule
