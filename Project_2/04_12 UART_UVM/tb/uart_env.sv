`ifndef ENVIRONMENT_SV
`define ENVIRONMENT_SV


`include "uvm_macros.svh"
import uvm_pkg::*;
`include "uart_seq_item.sv"

class uart_env extends uvm_env;
    `uvm_component_utils(uart_env)
    uart_agent agt;
    uart_scoreboard scb;
    uart_coverage cov;



    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()


    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = uart_agent::type_id::create("agt", this);
        scb = uart_scoreboard::type_id::create("scb", this);
        cov = uart_coverage::type_id::create("cov", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.ap.connect(scb.ap_imp);
        agt.drv.ap_drv.connect(scb.exp_imp);
        agt.mon.ap.connect(cov.analysis_export);
    endfunction

endclass  





`endif
