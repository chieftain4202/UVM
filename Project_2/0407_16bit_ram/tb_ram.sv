`include "uvm_macros.svh"
import uvm_pkg::*;


interface ram_if (
    input logic clk
);

    logic        we;
    logic [ 7:0] addr;
    logic [15:0] wdata;
    logic [15:0] rdata;

endinterface


class ram_seq_item extends uvm_sequence_item;
    rand bit        we;
    rand bit [15:0] wdata;
    rand bit [ 7:0] addr;
    int             cycles;
    bit      [15:0] rdata;

    //constraint c_cycles {cycles inside {[1 : 20]};}

    `uvm_object_utils_begin(ram_seq_item)
        `uvm_field_int(we, UVM_ALL_ON)
        `uvm_field_int(wdata, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "ram_seq_item");
        super.new(name);
    endfunction  //new()

    function string convert2string;
        return $sformatf("we = %0d wdata = %0d addr = %0d", we, wdata, addr);
    endfunction
endclass  //ram_seq_item


class ram_read_seq extends uvm_sequence #(ram_seq_item);
    `uvm_object_utils(ram_read_seq)

    bit [7:0] addr_q[$];
    int num_transactions;

    function new(string name = "ram_read_seq");
        super.new(name);
    endfunction  //new()

    virtual task body();
        ram_seq_item item;
        for (int i = 0; i < num_transactions; i++) begin
            item = ram_seq_item::type_id::create($sformatf("item_%0d", i));
            start_item(item);
            item.we = 0;
            item.addr = addr_q[i];
            item.wdata = 0;
            item.cycles = 1;
            finish_item(item);
            //`uvm_info(get_type_name(), $sformatf("[%0d/%0d] %s", i + 1, num_transactions, item.convert2string()), UVM_HIGH)

        end
    endtask
endclass  //ram_read_seq



class ram_write_seq extends uvm_sequence #(ram_seq_item);
    `uvm_object_utils(ram_write_seq)

    bit [7:0] written_addr_q[$];

    int num_transactions;

    function new(string name = "ram_write_seq");
        super.new(name);
        num_transactions = 0;
    endfunction  //new()

    virtual task body();
        ram_seq_item item;
        for (int i = 0; i < num_transactions; i++) begin
            item = ram_seq_item::type_id::create($sformatf("item_%0d", i));
            start_item(item);

            if (!item.randomize() with {we == 1;}) `uvm_fatal(get_type_name(), "Randomization failed")
            item.cycles = 1;
            written_addr_q.push_back(item.addr);

            finish_item(item);
            `uvm_info(get_type_name(), $sformatf("[%0d/%0d] %s", i + 1, num_transactions, item.convert2string()), UVM_HIGH)

        end
    endtask
endclass  //ram_write_seq



class ram_master_seq extends uvm_sequence #(ram_seq_item);
    `uvm_object_utils(ram_master_seq)

    function new(string name = "ram_master_seq");
        super.new(name);
    endfunction  //new()

    virtual task body();
        ram_write_seq write_seq;
        ram_read_seq  read_seq;

        `uvm_info(get_type_name(), "==== phase 1: Write ====", UVM_MEDIUM)
        write_seq = ram_write_seq::type_id::create("write_seq");
        write_seq.num_transactions = 10;
        write_seq.start(m_sequencer);

        `uvm_info(get_type_name(), "==== phase 2: Read ====", UVM_MEDIUM)
        read_seq = ram_read_seq::type_id::create("read_seq");
        read_seq.addr_q = write_seq.written_addr_q;
        read_seq.num_transactions = 10;
        read_seq.start(m_sequencer);

        `uvm_info(get_type_name(), "==== Master Sequence done ====", UVM_MEDIUM)

    endtask  //body
endclass  //ram_master_seq


class ram_driver extends uvm_driver #(ram_seq_item);
    `uvm_component_utils(ram_driver)
    virtual ram_if r_if;
    int item_cycles;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    virtual task drive_item(ram_seq_item item);
        item_cycles = item.cycles;
        r_if.addr  <= item.addr;
        r_if.wdata <= item.wdata;
        r_if.we    <= item.we;
        repeat (item_cycles) @(posedge r_if.clk);

        `uvm_info(get_type_name(), $sformatf("drive_cycles : %0d", item.cycles), UVM_HIGH);
    endtask  //drive

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ram_if)::get(this, "", "r_if", r_if)) begin
            `uvm_fatal(get_type_name(), "r_if를 찾을 수 없다!")
            `uvm_info(get_type_name(), "build_phase 실행 완료.", UVM_HIGH);
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        ram_seq_item item;
        forever begin
            seq_item_port.get_next_item(item);
            drive_item(item);
            seq_item_port.item_done();
        end
    endtask

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
    endfunction
endclass  //ram_driver


class ram_monitor extends uvm_monitor;
    `uvm_component_utils(ram_monitor)
    virtual ram_if r_if;
    int readpending;
    logic [15:0] expected_data;
    logic [15:0] data_mem[0:255];

    function new(string name, uvm_component parent);
        super.new(name, parent);
        expected_data = 0;
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ram_if)::get(this, "", "r_if", r_if)) begin
            `uvm_fatal(get_type_name(), "r_if를 찾을 수 없다!")
            `uvm_info(get_type_name(), "build_phase 실행 완료.", UVM_HIGH);
        end
    endfunction

    //Timing 미완성
    virtual task run_phase(uvm_phase phase);

        forever begin
            @(posedge r_if.clk);
            `uvm_info(get_type_name(), "(posedge r_if.clk) 대기 실행", UVM_HIGH);
            if (readpending) begin
                if (r_if.rdata !== expected_data) begin
                    `uvm_error(get_type_name(), $sformatf("불일치! 예상 = %0d, 실제 = %0d", expected_data, r_if.rdata))
                end else begin
                    `uvm_info(get_type_name(), $sformatf("READ 일치! data = %0d", r_if.rdata), UVM_LOW)
                end
                readpending = 0;
            end

            if (r_if.we) begin
                data_mem[r_if.addr] = r_if.wdata;
                expected_data = data_mem[r_if.addr];

                if (r_if.wdata !== expected_data) begin
                    `uvm_error(get_type_name(), $sformatf("불일치! 예상 = %0d, 실제 = %0d", expected_data, r_if.wdata))
                end else begin
                    `uvm_info(get_type_name(), $sformatf("WRITE 일치! data = %0d", r_if.wdata), UVM_LOW)
                end
            end else if (!r_if.we) begin
                expected_data = data_mem[r_if.addr];
                readpending   = 1;
            end
        end
    endtask

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
    endfunction
endclass  //ram_monitor


class ram_agent extends uvm_agent;
    `uvm_component_utils(ram_agent)

    uvm_sequencer #(ram_seq_item) sqr;
    ram_driver drv;
    ram_monitor mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sqr = uvm_sequencer#(ram_seq_item)::type_id::create("sqr", this);
        `uvm_info(get_type_name(), "sqr 생성", UVM_HIGH);
        drv = ram_driver::type_id::create("drv", this);
        `uvm_info(get_type_name(), "drv 생성", UVM_HIGH);
        mon = ram_monitor::type_id::create("mon", this);
        `uvm_info(get_type_name(), "mon 생성", UVM_HIGH);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

endclass  //ram_agent


class ram_environment extends uvm_env;
    `uvm_component_utils(ram_environment)

    ram_agent agt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info(get_type_name(), "new 생성", UVM_HIGH);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = ram_agent::type_id::create("agt", this);
        `uvm_info(get_type_name(), "agt 생성", UVM_HIGH);
    endfunction
endclass


class ram_test extends uvm_test;
    `uvm_component_utils(ram_test)

    ram_environment env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info(get_type_name(), "new 생성", UVM_HIGH);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = ram_environment::type_id::create("env", this);
        `uvm_info(get_type_name(), "env 생성", UVM_HIGH);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
        ram_master_seq seq;
        phase.raise_objection(this);
        seq = ram_master_seq::type_id::create("seq");
        seq.start(env.agt.sqr);
        #100;
        phase.drop_objection(this);
    endtask  //run_phase

    virtual function void report_phase(uvm_phase phase);
        uvm_report_server svr = uvm_report_server::get_server();
        super.report_phase(phase);
        if (svr.get_severity_count(UVM_ERROR) == 0) begin
            `uvm_info(get_type_name(), " ==== TEST PASS ====", UVM_LOW)
        end else begin
            `uvm_info(get_type_name(), " ==== TEST FAIL ====", UVM_LOW)
        end
    endfunction

endclass  //ram_test


module tb_ram ();

    logic clk;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;

    end

    ram_if r_if (clk);

    ram_16bit dut (
        .clk(clk),
        .we(r_if.we),
        .addr(r_if.addr),
        .wdata(r_if.wdata),
        .rdata(r_if.rdata)
    );

    initial begin
        uvm_config_db#(virtual ram_if)::set(null, "*", "r_if", r_if);
        run_test("ram_test");
    end
endmodule
