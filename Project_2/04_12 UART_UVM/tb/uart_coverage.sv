`ifndef COVERAGE_SV
`define COVERAGE_SV


`include "uvm_macros.svh"
import uvm_pkg::*;
`include "uart_seq_item.sv"

class uart_coverage extends uvm_subscriber #(uart_seq_item);
    `uvm_component_utils(uart_coverage)
    uart_seq_item tx;

    covergroup uart_cg;

        cp_data: coverpoint tx.data{
            bins addr_low       = {[8'h00 : 8'h3C]};
            bins addr_mid_low   = {[8'h40 : 8'h7C]};
            bins addr_mid_high = {[8'h80 : 8'hBC]};
            bins addr_high = {[8'hC0 : 8'hFC]};

        }
/*
        cp_rw: coverpoint tx.pwrite{
            bins write_op = {1'b1};
            bins read_op = {1'b0};
        }

        cp_wdata: coverpoint tx.pwdata{
            bins all_zero = {32'h0000_0000};
            bins all_ones = {32'hffff_ffff};
            bins all_a   = {32'haaaa_aaaa};
            bins all_5   = {32'h5555_5555};
            bins other   = default;
        }
        cp_rdata: coverpoint tx.prdata{
            bins all_zero = {32'h0000_0000};
            bins all_ones = {32'hffff_ffff};
            bins all_a   = {32'haaaa_aaaa};
            bins all_5   = {32'h5555_5555};
            bins other   = default;
        }

        cx_addr_rw: cross cp_addr, cp_rw;
*/
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        uart_cg = new();
    endfunction  //new()

    function void write (uart_seq_item t);
        tx = t;
        uart_cg.sample();
    endfunction


    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "\n\n===== Coverage Summay =====", UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("  Overall: %.1f%%", uart_cg.get_coverage()), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("  wdata: %.1f%%", uart_cg.cp_data.get_coverage()), UVM_LOW);
        `uvm_info(get_type_name(), "===== Coverage Summay =====\n\n", UVM_LOW);

    endfunction
endclass  //component 



`endif
