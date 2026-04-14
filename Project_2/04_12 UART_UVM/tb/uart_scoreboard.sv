`ifndef SCOREBOARD_SV
`define SCOREBOARD_SV


`include "uvm_macros.svh"
import uvm_pkg::*;
`include "uart_seq_item.sv"
`uvm_analysis_imp_decl(_exp)

class uart_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(uart_scoreboard)

    uvm_analysis_imp #(uart_seq_item, uart_scoreboard) ap_imp;
    uvm_analysis_imp_exp #(uart_seq_item, uart_scoreboard) exp_imp;

    logic [7:0] expected;
    logic [7:0] expected_q;

    int success;
    int error;
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_imp = new("ap_imp", this);
        exp_imp = new("exp_imp", this);
    endfunction

    function void write_exp(uart_seq_item tx);
        expected = tx.uart_rx_data;
        `uvm_info(get_type_name(), $sformatf("Expected set: 0x%02h", expected), UVM_MEDIUM)
    endfunction

    function void write(uart_seq_item tx);

        if (expected !== tx.data) begin
            error++;
            `uvm_info(get_type_name(), $sformatf ("FAIL!!! UART Tx : 0x%02h, Expected : 0x%02h", tx.data, expected), UVM_LOW);
        end else begin
            success ++;
            `uvm_info(get_type_name(), $sformatf ("PASS!!! UART Tx : 0x%02h, Expected : 0x%02h", tx.data, expected), UVM_LOW);
        end

    endfunction

    virtual function void report_phase(uvm_phase phase);
        string result = (error == 0) ? "** PASS **" : "** FAIL **";
        `uvm_info(get_type_name(), "******** summary report *********", UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("Read num : %s", success), UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("Errors num : %s", error), UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("*****************************"), UVM_MEDIUM)
    endfunction
endclass  //component 



`endif
