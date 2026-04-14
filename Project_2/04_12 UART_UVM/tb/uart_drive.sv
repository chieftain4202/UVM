`ifndef DRIVER_SV
`define DRIVER_SV


`include "uvm_macros.svh"
import uvm_pkg::*;
`include "uart_seq_item.sv"

class uart_driver extends uvm_driver #(uart_seq_item);
    `uvm_component_utils(uart_driver)
    uvm_analysis_port #(uart_seq_item) ap_drv;
    virtual uart_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()


    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_drv = new("ap_drv", this);

        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "driver에서 uvm_config_db 에러 발생.");
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        uart_init();
        wait (vif.rst == 0);
        `uvm_info(get_type_name(), "리셋 해제 확인. 트랜잭션 대기 중...", UVM_MEDIUM)

        forever begin
            uart_seq_item tx;
            seq_item_port.get_next_item(tx);
            drive_uart(tx);
            seq_item_port.item_done();
        end
    endtask


    task wait_baud_ticks(int n);
        repeat (n) begin
            do begin
                @(vif.drv_cb);
            end while (!vif.drv_cb.baud_tick);
        end
    endtask

    task wait_uart_ready();
    do begin
        @(vif.drv_cb);
    end while (vif.drv_cb.busy_tx);
endtask

    task uart_init();
        vif.drv_cb.uart_rx <= 1'b1;
    endtask  //apb_bus_init

    task drive_uart(uart_seq_item tx);
    wait_uart_ready();

    ap_drv.write(tx); // expected data 전달


    // start bit
    vif.drv_cb.uart_rx <= 1'b0;
    wait_baud_ticks(16);

    // data bit, LSB first
    for (int i = 0; i < 8; i++) begin
        vif.drv_cb.uart_rx <= tx.uart_rx_data[i];
        wait_baud_ticks(16);
    end

    // stop bit
    vif.drv_cb.uart_rx <= 1'b1;
    wait_baud_ticks(16);

        `uvm_info(get_type_name(), $sformatf("drv 구동 완료: %s", tx.convert2string()), UVM_MEDIUM);
    endtask  //drive_apb

endclass  //component 


`endif
