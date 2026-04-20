`timescale 1ns / 1ps

module i2c_demo_top (
    input  logic        clk,
    input  logic        rst,
    input  logic [15:0] sw,
    output logic        scl,
    inout  wire         sda

);

    typedef enum logic [3:0] {
        IDLE,
        START_CMD,
        START_WAIT,
        ADDR_CMD,
        ADDR_WAIT,
        WRITE_CMD,
        WRITE_WAIT,
        STOP_CMD,
        STOP_WAIT
    } i2c_state_e;

    localparam logic [7:0] SLA_W = {7'h12, 1'b0};
    localparam int START_DEBOUNCE_MAX = 2_000_000;

    i2c_state_e state;

    logic [7:0] sw_tx_data;
    logic [15:0] sw_meta;
    logic [15:0] sw_sync;
    logic        start_db;
    logic        start_db_prev;
    logic       start_rise;
    logic [$clog2(START_DEBOUNCE_MAX)-1:0] start_cnt;

    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;
    logic [7:0] m_tx_data;
    logic       ack_in;
    logic [7:0] m_rx_data;
    logic       done;
    logic       ack_out;
    logic       busy;

    logic [7:0] s_tx_data;
    logic [7:0] s_rx_data;
    logic       s_done;
    logic       rx_valid;
    logic       tx_started;
    logic       tx_finished;
    logic [13:0] fnd_in_data;

    assign ack_in      = 1'b1;
    assign s_tx_data   = 8'h00;
    assign start_rise  = start_db & ~start_db_prev;
    assign fnd_in_data = rx_valid    ? {6'd0, s_rx_data} :
                         tx_finished ? {6'd0, sw_tx_data} :
                         tx_started  ? (14'd8000 + {6'd0, sw_tx_data}) :
                                       14'd0;

    pullup (sda);

    I2C_Master_top U_I2C_MASTER_TOP (
        .clk      (clk),
        .rst      (rst),
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read (cmd_read),
        .cmd_stop (cmd_stop),
        .tx_data  (m_tx_data),
        .ack_in   (ack_in),
        .rx_data  (m_rx_data),
        .done     (done),
        .ack_out  (ack_out),
        .busy     (busy),
        .scl      (scl),
        .sda      (sda)
    );


    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state      <= IDLE;
            sw_tx_data <= 8'h00;
            sw_meta    <= 16'h0000;
            sw_sync    <= 16'h0000;
            start_db   <= 1'b0;
            start_db_prev <= 1'b0;
            start_cnt  <= '0;
            rx_valid   <= 1'b0;
            tx_started <= 1'b0;
            tx_finished<= 1'b0;
            cmd_start  <= 1'b0;
            cmd_write  <= 1'b0;
            cmd_read   <= 1'b0;
            cmd_stop   <= 1'b0;
            m_tx_data  <= 8'h00;
        end else begin
            sw_meta <= sw;
            sw_sync <= sw_meta;
            start_db_prev <= start_db;

            if (sw_sync[15] == start_db) begin
                start_cnt <= '0;
            end else if (start_cnt == START_DEBOUNCE_MAX - 1) begin
                start_db  <= sw_sync[15];
                start_cnt <= '0;
            end else begin
                start_cnt <= start_cnt + 1'b1;
            end

            cmd_start <= 1'b0;
            cmd_write <= 1'b0;
            cmd_read  <= 1'b0;
            cmd_stop  <= 1'b0;

            if (s_done) begin
                rx_valid <= 1'b1;
            end

            case (state)
                IDLE: begin
                    if (start_rise) begin
                        sw_tx_data <= sw_sync[7:0];
                        rx_valid   <= 1'b0;
                        tx_started <= 1'b1;
                        tx_finished<= 1'b0;
                        state      <= START_CMD;
                    end
                end

                START_CMD: begin
                    cmd_start <= 1'b1;
                    state     <= START_WAIT;
                end

                START_WAIT: begin
                    if (done) begin
                        state <= ADDR_CMD;
                    end
                end

                ADDR_CMD: begin
                    cmd_write <= 1'b1;
                    m_tx_data <= SLA_W;
                    state     <= ADDR_WAIT;
                end

                ADDR_WAIT: begin
                    if (done) begin
                        state <= WRITE_CMD;
                    end
                end

                WRITE_CMD: begin
                    cmd_write <= 1'b1;
                    m_tx_data <= sw_tx_data;
                    state     <= WRITE_WAIT;
                end

                WRITE_WAIT: begin
                    if (done) begin
                        state <= STOP_CMD;
                    end
                end

                STOP_CMD: begin
                    cmd_stop <= 1'b1;
                    state    <= STOP_WAIT;
                end

                STOP_WAIT: begin
                    if (done) begin
                        state       <= IDLE;
                        tx_finished <= 1'b1;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
