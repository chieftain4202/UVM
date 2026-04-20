`timescale 1ns / 1ps

module demo_master (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] sw,
    input  logic       btn_start,
    input  logic       btn_stop,
    input  logic       btn_addr,
    input  logic       btn_write,
    output logic       mscl,
    inout  wire        msda
);

    typedef enum logic [2:0] {
        IDLE,
        START_CMD,
        WAIT_ADDR_BTN,
        ADDR_CMD,
        WAIT_WRITE_BTN,
        WRITE_CMD,
        WAIT_STOP_BTN,
        STOP_CMD
    } demo_master_state_e;

    localparam logic [7:0] SLAVE_ADDR_WRITE = 8'b0111_0000;

    logic start;
    logic stop;
    logic addr;
    logic write;
    logic cmd_start;
    logic cmd_write;
    logic cmd_read;
    logic cmd_stop;
    logic [7:0] tx_data;
    logic [7:0] sw_tx_data;
    logic [7:0] rx_data;
    logic       ack_in;
    logic       ack_out;
    logic       done;
    logic       busy;

    demo_master_state_e state;

    assign ack_in = 1'b1;

    dm_sw_data u_sw_data (
        .sw      (sw),
        .hex_data(sw_tx_data)
    );

    dm_btn_debounce u_btn_debounce_start (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_start),
        .o_btn(start)
    );

    dm_btn_debounce u_btn_debounce_stop (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_stop),
        .o_btn(stop)
    );

    dm_btn_debounce u_btn_debounce_addr (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_addr),
        .o_btn(addr)
    );

    dm_btn_debounce u_btn_debounce_write (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_write),
        .o_btn(write)
    );

    dm_I2C_Master u_i2c_master (
        .clk      (clk),
        .rst      (rst),
        .cmd_start(start),
        .cmd_write(write),
        .cmd_read (read),
        .cmd_stop (stop),
        .M_tx_data(sw_tx_data),
        .ack_in   (ack_in),
        .M_rx_data(rx_data),
        .done     (done),
        .ack_out  (ack_out),
        .busy     (busy),
        .scl      (mscl),
        .sda      (msda)
    );

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            cmd_start <= 1'b0;
            cmd_write <= 1'b0;
            cmd_read  <= 1'b0;
            cmd_stop  <= 1'b0;
            tx_data   <= 8'h00;
        end else begin
            cmd_start <= 1'b0;
            cmd_write <= 1'b0;
            cmd_read  <= 1'b0;
            cmd_stop  <= 1'b0;

            case (state)
                IDLE: begin
                    if (start) begin
                        state <= START_CMD;
                    end
                end

                START_CMD: begin
                    cmd_start <= 1'b1;
                    if (done) begin
                        state <= WAIT_ADDR_BTN;
                    end
                end

                WAIT_ADDR_BTN: begin
                    if (addr) begin
                        tx_data <= SLAVE_ADDR_WRITE;
                        state   <= ADDR_CMD;
                    end
                end

                ADDR_CMD: begin
                    cmd_write <= 1'b1;
                    if (done) begin
                        state <= WAIT_WRITE_BTN;
                    end
                end

                WAIT_WRITE_BTN: begin
                    if (write) begin
                        tx_data <= sw_tx_data;
                        state   <= WRITE_CMD;
                    end
                end

                WRITE_CMD: begin
                    cmd_write <= 1'b1;
                    if (done) begin
                        state <= WAIT_STOP_BTN;
                    end
                end

                WAIT_STOP_BTN: begin
                    if (stop) begin
                        state <= STOP_CMD;
                    end
                end

                STOP_CMD: begin
                    cmd_stop <= 1'b1;
                    if (done) begin
                        state <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

module dm_I2C_Master (
    input  logic       clk,
    input  logic       rst,
    input  logic       cmd_start,
    input  logic       cmd_write,
    input  logic       cmd_read,
    input  logic       cmd_stop,
    input  logic [7:0] M_tx_data,
    input  logic       ack_in,
    output logic [7:0] M_rx_data,
    output logic       done,
    output logic       ack_out,
    output logic       busy,
    output logic       scl,
    inout  wire        sda
);
    logic sda_o;
    logic sda_i;

    assign sda_i = sda;
    assign sda   = sda_o ? 1'bz : 1'b0;

    dm_i2c_master u_i2c_master (
        .clk      (clk),
        .rst      (rst),
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read (cmd_read),
        .cmd_stop (cmd_stop),
        .M_tx_data(M_tx_data),
        .ack_in   (ack_in),
        .M_rx_data(M_rx_data),
        .done     (done),
        .ack_out  (ack_out),
        .busy     (busy),
        .scl      (scl),
        .sda_o    (sda_o),
        .sda_i    (sda_i)
    );
endmodule

module dm_i2c_master (
    input  logic       clk,
    input  logic       rst,
    input  logic       cmd_start,
    input  logic       cmd_write,
    input  logic       cmd_read,
    input  logic       cmd_stop,
    input  logic [7:0] M_tx_data,
    input  logic       ack_in,
    output logic [7:0] M_rx_data,
    output logic       done,
    output logic       ack_out,
    output logic       busy,
    output logic       scl,
    output logic       sda_o,
    input  logic       sda_i
);

    typedef enum logic [2:0] {
        IDLE,
        START,
        WAIT_CMD,
        DATA,
        DATA_ACK,
        STOP
    } i2c_state_e;

    i2c_state_e state;

    logic [7:0] div_cnt;
    logic       qtr_tick;
    logic       scl_r;
    logic       sda_r;
    logic [1:0] step;
    logic [7:0] tx_shift_reg;
    logic [7:0] rx_shift_reg;
    logic [2:0] bit_cnt;
    logic       is_read;
    logic       ack_in_r;

    assign scl   = scl_r;
    assign sda_o = sda_r;
    assign busy  = (state != IDLE);

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            div_cnt  <= 8'd0;
            qtr_tick <= 1'b0;
        end else begin
            if (div_cnt == 8'd249) begin
                div_cnt  <= 8'd0;
                qtr_tick <= 1'b1;
            end else begin
                div_cnt  <= div_cnt + 8'd1;
                qtr_tick <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            scl_r        <= 1'b1;
            sda_r        <= 1'b1;
            step         <= 2'd0;
            done         <= 1'b0;
            ack_out      <= 1'b1;
            M_rx_data    <= 8'd0;
            tx_shift_reg <= 8'd0;
            rx_shift_reg <= 8'd0;
            is_read      <= 1'b0;
            bit_cnt      <= 3'd0;
            ack_in_r     <= 1'b1;
        end else begin
            done <= 1'b0;

            case (state)
                IDLE: begin
                    scl_r <= 1'b1;
                    sda_r <= 1'b1;
                    if (cmd_start) begin
                        state <= START;
                        step  <= 2'd0;
                    end
                end

                START: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                sda_r <= 1'b1;
                                scl_r <= 1'b1;
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                sda_r <= 1'b0;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                step <= 2'd3;
                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                step  <= 2'd0;
                                done  <= 1'b1;
                                state <= WAIT_CMD;
                            end
                        endcase
                    end
                end

                WAIT_CMD: begin
                    step <= 2'd0;
                    if (cmd_write) begin
                        tx_shift_reg <= M_tx_data;
                        bit_cnt      <= 3'd0;
                        is_read      <= 1'b0;
                        state        <= DATA;
                    end else if (cmd_read) begin
                        rx_shift_reg <= 8'd0;
                        bit_cnt      <= 3'd0;
                        is_read      <= 1'b1;
                        state        <= DATA;
                    end else if (cmd_stop) begin
                        state <= STOP;
                    end else if (cmd_start) begin
                        state <= START;
                    end
                end

                DATA: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                scl_r <= 1'b0;
                                sda_r <= is_read ? 1'b1 : tx_shift_reg[7];
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                scl_r <= 1'b1;
                                if (is_read) begin
                                    rx_shift_reg <= {rx_shift_reg[6:0], sda_i};
                                end
                                step <= 2'd3;
                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                if (!is_read) begin
                                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                                end
                                step <= 2'd0;
                                if (bit_cnt == 3'd7) begin
                                    state <= DATA_ACK;
                                end else begin
                                    bit_cnt <= bit_cnt + 3'd1;
                                end
                            end
                        endcase
                    end
                end

                DATA_ACK: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                scl_r <= 1'b0;
                                sda_r <= is_read ? ack_in_r : 1'b1;
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                scl_r <= 1'b1;
                                if (!is_read) begin
                                    ack_out <= sda_i;
                                end else begin
                                    M_rx_data <= rx_shift_reg;
                                end
                                step <= 2'd3;
                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                done  <= 1'b1;
                                step  <= 2'd0;
                                state <= WAIT_CMD;
                            end
                        endcase
                    end
                end

                STOP: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                sda_r <= 1'b0;
                                scl_r <= 1'b0;
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                sda_r <= 1'b1;
                                step  <= 2'd3;
                            end
                            2'd3: begin
                                step  <= 2'd0;
                                done  <= 1'b1;
                                state <= IDLE;
                            end
                        endcase
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule

module dm_btn_debounce (
    input  logic clk,
    input  logic reset,
    input  logic i_btn,
    output logic o_btn
);
    parameter CLK_DIV = 1000_000;
    parameter F_COUNT = 100_000_000 / CLK_DIV;

    logic [$clog2(F_COUNT)-1:0] counter_reg;
    logic clk_100khz_reg;
    logic [7:0] q_reg;
    logic [7:0] q_next;
    logic debounce;
    logic edge_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg    <= '0;
            clk_100khz_reg <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1'b1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg    <= '0;
                clk_100khz_reg <= 1'b1;
            end else begin
                clk_100khz_reg <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk_100khz_reg, posedge reset) begin
        if (reset) begin
            q_reg <= 8'd0;
        end else begin
            q_reg <= q_next;
        end
    end

    always_comb begin
        q_next = {i_btn, q_reg[7:1]};
    end

    assign debounce = &q_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debounce;
        end
    end

    assign o_btn = debounce & ~edge_reg;
endmodule

module dm_sw_data (
    input  logic [7:0] sw,
    output logic [7:0] hex_data
);
    always_comb begin
        hex_data = sw;
    end
endmodule

