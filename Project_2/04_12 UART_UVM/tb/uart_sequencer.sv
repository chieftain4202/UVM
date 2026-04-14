`ifndef APB_SEQUENCE_SV
`define APB_SEQUENCE_SV


`include "uvm_macros.svh"
import uvm_pkg::*;
`include "uart_seq_item.sv"



class uart_base_seq extends uvm_sequence #(uart_seq_item);
    `uvm_object_utils(uart_base_seq)
    int num_loop = 0;

    function new(string name = "apb_base_seq");
        super.new(name);
    endfunction  //new()

    task do_write(bit [7:0] data);
        uart_seq_item item;
        item = uart_seq_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
             
            })
            `uvm_fatal(get_type_name(), "do_write() Randomize() fail!")
        finish_item(item);
        `uvm_info(get_type_name(), $sformatf("do write uart 전송 완료: data = 0x%08h", data), UVM_MEDIUM)
    endtask

    virtual task body();
    for (int i = 0; i < num_loop; i++) begin
        do_write($urandom_range(0, 255));
    end
endtask

endclass
`endif 