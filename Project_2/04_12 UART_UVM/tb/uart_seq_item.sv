`ifndef RAM_SEQ_ITEM_SV
`define RAM_SEQ_ITEM_SV


`include "uvm_macros.svh"
import uvm_pkg::*;

class uart_seq_item extends uvm_sequence_item;

    rand logic [7:0] uart_rx_data;
    logic [7:0] data;


    `uvm_object_utils_begin(uart_seq_item)
        `uvm_field_int(uart_rx_data, UVM_ALL_ON)
    `uvm_object_utils_end


    function new(string name = "uart_seq_item");
        super.new(name);
    endfunction  //new()

    function string convert2string();
        return $sformatf("Uart_rx_data = 0x%02h", uart_rx_data);
    endfunction

endclass  //component 



`endif
