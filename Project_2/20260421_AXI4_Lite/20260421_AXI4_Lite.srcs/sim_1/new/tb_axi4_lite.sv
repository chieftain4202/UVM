`timescale 1ns / 1ps

module tb_axi4_lite ();

    // Global Signals
    logic        ACLK;
    logic        ARESETn;

    logic [31:0] AWADDR;
    logic        AWVALID;
    logic        AWREADY;

    logic [31:0] WDATA;
    logic        WVALID;
    logic        WREADY;

    logic [ 1:0] BRESP;
    logic        BVALID;
    logic        BREADY;

    logic [31:0] ARADDR;
    logic        ARVALID;
    logic        ARREADY;

    logic [31:0] RDATA;
    logic        RVALID;
    logic        RREADY;
    logic [ 1:0] RRESP;

    logic        transfer;
    logic        ready;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic        write;
    logic [31:0] rdata;

    // SLAVE AXI=Lite simulator
    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;
    bit [31:0] slave_addr;
    bit slv_addr_flag;

    axi4_lite_master dut (.*);

    always #5 ACLK = ~ACLK;

    task automatic axi_slave_write_aw();
        // AW channeL
        forever begin
            @(posedge ACLK);
            if (AWVALID & !AWREADY) begin
                slave_addr = AWADDR;
                AWREADY = 1'b1;
                slv_addr_flag = 1;
                $display("[%0t] SLAVE WRITE ADDR %0h", $time, slave_addr);
            end else if (AWVALID & AWREADY) begin
                AWREADY = 1'b0;
            end else begin
                AWREADY = 1'b0;
                slv_addr_flag = 0;
            end
        end
    endtask

    task automatic axi_slave_write_w();
        // W channeL
        forever begin
            @(posedge ACLK);
            if (WVALID & !WREADY) begin
                wait (slv_addr_flag);
                case (slave_addr[3:2])
                    2'h0: slv_reg0 = WDATA;
                    2'h1: slv_reg1 = WDATA;
                    2'h2: slv_reg2 = WDATA;
                    2'h3: slv_reg3 = WDATA;
                endcase
                WREADY = 1'b1;
                $display("[%0t] SLAVE WRITE ADDR %0h, WDATA = %0h", $time,
                         slave_addr, WDATA);
            end else if (WVALID & WREADY) begin
                WREADY = 1'b0;
            end else begin
                WREADY = 1'b0;
            end
        end
    endtask


    task automatic axi_slave_write_b();
        // B channeL
        forever begin
            @(posedge ACLK);
            if (WVALID) begin
                BRESP  = 2'b00;  // OK
                BVALID = 1'b1;
                $display("[%0t] SLAVE WRITE BRESP = %0h", $time, BRESP);
            end else if (BVALID & BREADY) begin
                BVALID = 1'b0;
            end else begin
                BVALID = 1'b0;
            end
        end
    endtask

    task automatic axi_slave_read_ar();
        // AR channeL
        forever begin
            @(posedge ACLK);
            if (ARVALID & !ARREADY) begin
                slave_addr = ARADDR;
                ARREADY = 1'b1;
                
                $display("[%0t] SLAVE READ ADDR %0h", $time, slave_addr);
            end else if (ARVALID & ARREADY) begin
                ARREADY = 1'b0;
                slv_addr_flag = 1;
            end else begin
                ARREADY = 1'b0;
                slv_addr_flag = 0;
            end
        end
    endtask

    task automatic axi_slave_read_r();
        // R channeL
        forever begin
            @(posedge ACLK);
            if (!RVALID & RREADY) begin
                wait (slv_addr_flag);
                case (slave_addr[3:2])
                    2'h0: RDATA = slv_reg0;
                    2'h1: RDATA = slv_reg1;
                    2'h2: RDATA = slv_reg2;
                    2'h3: RDATA = slv_reg3;
                endcase
                RVALID = 1'b1;
                RRESP  = 2'b00;
                $display("[%0t] SLAVE READ ADDR %0h, RDATA = %0h", $time,
                         slave_addr, RDATA);
            end else if (RVALID & RREADY) begin
                RVALID = 1'b0;
            end else begin
                RVALID = 1'b0;
            end
        end
    endtask





    task automatic axi_write(logic [31:0] address, logic [31:0] data);
        addr <= address;
        wdata <= data;
        write <= 1'b1;
        transfer <= 1'b1;
        @(posedge ACLK);
        transfer <= 1'b0;
        do @(posedge ACLK); while (!ready);
        $display("[%0t] CPU WRITE ADDR %0h, WDATA = %0h", $time, addr,
                 wdata);
    endtask

    task automatic axi_read(logic [31:0] address);
        addr <= address;
        write <= 1'b0;
        transfer <= 1'b1;
        @(posedge ACLK);
        transfer <= 1'b0;
        do @(posedge ACLK); while (!ready);
        $display("[%0t] CPU READ ADDR %0h , RDATA = %0h", $time, addr, rdata);
    endtask


    initial begin
        ACLK = 0;
        ARESETn = 0;
        repeat (3) @(posedge ACLK);
        ARESETn = 1;
        repeat (3) @(posedge ACLK);

        fork
            axi_slave_write_aw();
            axi_slave_write_w();
            axi_slave_write_b();
            axi_slave_read_ar();
            axi_slave_read_r();
        join_none

        @(posedge ACLK);
        @(posedge ACLK);
        repeat (3) @(posedge ACLK);
        axi_write(32'h00000000, 32'h11111111);
        @(posedge ACLK);
        axi_write(32'h00000004, 32'h22222222);
        @(posedge ACLK);
        axi_write(32'h00000008, 32'h33333333);
        @(posedge ACLK);
        axi_write(32'h0000000C, 32'h44444444);
        @(posedge ACLK);
        axi_read(32'h00000000);
        @(posedge ACLK);
        axi_read(32'h00000004);
        @(posedge ACLK);
        axi_read(32'h00000008);
        @(posedge ACLK);
        axi_read(32'h0000000C);

        repeat (10) @(posedge ACLK);
        $finish;
    end
endmodule
