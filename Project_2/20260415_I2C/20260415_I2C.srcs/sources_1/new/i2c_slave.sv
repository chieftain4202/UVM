`timescale 1ns / 1ps

module i2c_slave (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       ack_out,
    input  logic       scl,
    inout  logic       sda
);

    logic sda_o, sda_i, sda_r;
    logic edge_scl, edge_sda;
    logic scl_rise, scl_fall, sda_rise, sda_fall;
    logic start_cond, stop_cond;
    logic [2:0] bit_cnt;
    logic [1:0] step;
    logic [7:0] tx_shift_reg, rx_shift_reg;
    logic [6:0] fnd_slave_addr;
    logic       addr_match;
    logic       rw_dir;

    assign sda_i = sda;
    assign sda   = sda_o ? 1'bz : 1'b0;
    assign sda_o = sda_r;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            edge_scl <= 1'b1;
            edge_sda <= 1'b1;
        end else begin
            edge_scl <= scl;
            edge_sda <= sda_i;
        end
    end

    assign scl_rise  = ~edge_scl & scl;
    assign scl_fall  = edge_scl & ~scl;
    assign sda_rise  = ~edge_sda & sda_i;
    assign sda_fall  = edge_sda & ~sda_i;
    assign start_cond = sda_fall & scl;
    assign stop_cond  = sda_rise & scl;

    typedef enum logic [2:0] {
        IDLE = 3'b000,
        ADDR,
        ADDR_ACK,
        RX_DATA,
        RX_ACK,
        TX_DATA,
        TX_ACK
    } i2c_state_e;

    i2c_state_e state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state          <= IDLE;
            sda_r          <= 1'b1;
            tx_shift_reg   <= 8'h00;
            rx_shift_reg   <= 8'h00;
            rx_data        <= 8'h00;
            ack_out        <= 1'b1;
            bit_cnt        <= 3'd0;
            step           <= 2'd0;
            addr_match     <= 1'b0;
            rw_dir         <= 1'b0;
            fnd_slave_addr <= 7'b0111000;
        end else begin
            if (start_cond) begin
                state        <= ADDR;
                sda_r        <= 1'b1;
                tx_shift_reg <= tx_data;
                rx_shift_reg <= 8'h00;
                bit_cnt      <= 3'd0;
                step         <= 2'd0;
                addr_match   <= 1'b0;
            end else if (stop_cond) begin
                state    <= IDLE;
                sda_r    <= 1'b1;
                bit_cnt  <= 3'd0;
                step     <= 2'd0;
                ack_out  <= 1'b1;
            end else begin
                case (state)
                    IDLE: begin
                        sda_r <= 1'b1;
                    end

                    ADDR: begin
                        if (scl_rise) begin
                            rx_shift_reg <= {rx_shift_reg[6:0], sda_i};
                            if (bit_cnt == 3'd7) begin
                                addr_match <= (rx_shift_reg[6:0] == fnd_slave_addr);
                                rw_dir     <= sda_i;
                                bit_cnt    <= 3'd0;
                                step       <= 2'd0;
                                state      <= ADDR_ACK;
                            end else begin
                                bit_cnt <= bit_cnt + 3'd1;
                            end
                        end
                    end

                    ADDR_ACK: begin
                        case (step)
                            2'd0: begin
                                if (scl_fall) begin
                                    if (addr_match) begin
                                        sda_r <= 1'b0;
                                    end
                                    step <= 2'd1;
                                end
                            end
                            2'd1: begin
                                if (scl_fall) begin
                                    sda_r <= 1'b1;
                                    step  <= 2'd0;
                                    if (!addr_match) begin
                                        state <= IDLE;
                                    end else if (rw_dir) begin
                                        tx_shift_reg <= tx_data;
                                        bit_cnt      <= 3'd0;
                                        state        <= TX_DATA;
                                    end else begin
                                        rx_shift_reg <= 8'h00;
                                        bit_cnt      <= 3'd0;
                                        state        <= RX_DATA;
                                    end
                                end
                            end
                            default: begin
                                step <= 2'd0;
                            end
                        endcase
                    end

                    RX_DATA: begin
                        if (scl_rise) begin
                            rx_shift_reg <= {rx_shift_reg[6:0], sda_i};
                            if (bit_cnt == 3'd7) begin
                                rx_data <= {rx_shift_reg[6:0], sda_i};
                                bit_cnt <= 3'd0;
                                step    <= 2'd0;
                                state   <= RX_ACK;
                            end else begin
                                bit_cnt <= bit_cnt + 3'd1;
                            end
                        end
                    end

                    RX_ACK: begin
                        case (step)
                            2'd0: begin
                                if (scl_fall) begin
                                    sda_r <= 1'b0;
                                    step  <= 2'd1;
                                end
                            end
                            2'd1: begin
                                if (scl_fall) begin
                                    sda_r <= 1'b1;
                                    step  <= 2'd0;
                                    state <= RX_DATA;
                                end
                            end
                            default: begin
                                step <= 2'd0;
                            end
                        endcase
                    end

                    TX_DATA: begin
                        if (scl_fall) begin
                            sda_r <= tx_shift_reg[7];
                            if (bit_cnt == 3'd7) begin
                                bit_cnt <= 3'd0;
                                step    <= 2'd0;
                                state   <= TX_ACK;
                            end else begin
                                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                                bit_cnt      <= bit_cnt + 3'd1;
                            end
                        end
                    end

                    TX_ACK: begin
                        case (step)
                            2'd0: begin
                                if (scl_fall) begin
                                    sda_r <= 1'b1;
                                    step  <= 2'd1;
                                end
                            end
                            2'd1: begin
                                if (scl_rise) begin
                                    ack_out <= sda_i;
                                    step    <= 2'd2;
                                end
                            end
                            2'd2: begin
                                if (scl_fall) begin
                                    step <= 2'd0;
                                    if (ack_out == 1'b0) begin
                                        tx_shift_reg <= tx_data;
                                        state        <= TX_DATA;
                                    end else begin
                                        state <= IDLE;
                                    end
                                end
                            end
                            default: begin
                                step <= 2'd0;
                            end
                        endcase
                    end

                    default: begin
                        state <= IDLE;
                        sda_r <= 1'b1;
                    end
                endcase
            end
        end
    end

endmodule
