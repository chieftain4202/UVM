`ifndef MONITOR_SV
`define MONITOR_SV


`include "uvm_macros.svh"
import uvm_pkg::*;
`include "uart_seq_item.sv"

class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)

    uvm_analysis_port #(uart_seq_item) ap;
    virtual uart_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "monitor에서 uvm_config_db 에러 발생.");
        end
    endfunction



    virtual task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(), " 모니터링 시작 ...", UVM_MEDIUM)
        forever begin
            decode_transaction();
        end
    endtask

    task wait_baud_ticks(int n);
        repeat (n) begin
            do begin
                @(vif.mon_cb);
            end while (!vif.mon_cb.baud_tick);
        end
    endtask

    task decode_transaction();
        uart_seq_item tx;
        bit [7:0] data_buf;

        data_buf = 0;

        do begin
            @(vif.mon_cb);
        end while (vif.mon_cb.uart_tx !== 1'b1);

        do begin
            @(vif.mon_cb);
        end while (vif.mon_cb.uart_tx !== 1'b0);

        // start bit 중앙
        wait_baud_ticks(8);

        for (int i = 0; i < 8; i++) begin
            wait_baud_ticks(16);
            data_buf[i] = vif.mon_cb.uart_tx;
        end

        tx              = uart_seq_item::type_id::create("mon_tx");
        tx.data         = data_buf;
        tx.uart_rx_data = vif.mon_cb.uart_rx_data;

        `uvm_info(get_type_name(), $sformatf("mon tx: 0x%02h", $sformatf(data_buf[7:0])), UVM_MEDIUM)
        ap.write(tx);

    endtask  //conllect_transaction

endclass  //component 


`endif
