`timescale 1ns / 1ps


module tb_axi4_slave ();


    parameter integer C_S_AXI_DATA_WIDTH = 32;
    parameter integer C_S_AXI_ADDR_WIDTH = 4;

    logic                                S_AXI_ACLK;
    logic                                S_AXI_ARESETN;
    logic [    C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR;
    logic [                       2 : 0] S_AXI_AWPROT;
    logic                                S_AXI_AWVALID;
    logic                                S_AXI_AWREADY;
    logic [    C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA;
    logic [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB;
    logic                                S_AXI_WVALID;
    logic                                S_AXI_WREADY;
    logic [                       1 : 0] S_AXI_BRESP;
    logic                                S_AXI_BVALID;
    logic                                S_AXI_BREADY;
    logic [    C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR;
    logic [                       2 : 0] S_AXI_ARPROT;
    logic                                S_AXI_ARVALID;
    logic                                S_AXI_ARREADY;
    logic [    C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA;
    logic [                       1 : 0] S_AXI_RRESP;
    logic                                S_AXI_RVALID;
    logic                                S_AXI_RREADY;

    myip_v1_0_S00_AXI #(

        .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
    ) dut (
        .*
    );

    task axi_write(logic [31:0] addr, logic [31:0] data);
        @(posedge S_AXI_ACLK);
        S_AXI_AWADDR  <= addr;
        S_AXI_AWVALID <= 1'b1;
        S_AXI_WDATA   <= data;
        S_AXI_WVALID  <= 1'b1;
        S_AXI_WSTRB   <= 4'b1111;
        S_AXI_BREADY  <= 1'b1;

        wait (S_AXI_AWREADY & S_AXI_WREADY);
        @(posedge S_AXI_ACLK);
        S_AXI_AWVALID <= 1'b0;
        S_AXI_WVALID  <= 1'b0;

        wait (S_AXI_BVALID);
        @(posedge S_AXI_ACLK);
        S_AXI_BREADY <= 1'b0;
        $display("[%t] WRITE: ADDR = 0x%0h, DATA = 0x%0h", $time, addr, data);
        @(posedge S_AXI_ACLK);

    endtask  //axi_write

    task axi_read(logic [31:0] addr);
        @(posedge S_AXI_ACLK);
        S_AXI_ARADDR  <= addr;
        S_AXI_ARVALID <= 1'b1;
        S_AXI_RREADY  <= 1'b1;

        wait (S_AXI_ARREADY);
        @(posedge S_AXI_ACLK);
        S_AXI_ARVALID <= 1'b0;

        wait (S_AXI_RVALID);
        @(posedge S_AXI_ACLK);
        S_AXI_RREADY <= 1'b0;
        $display("[%t] READ: ADDR = 0x%0h, DATA = 0x%0h", $time, addr,
                 S_AXI_RDATA);
        @(posedge S_AXI_ACLK);




    endtask  //axi_read


    always #5 S_AXI_ACLK = ~S_AXI_ACLK;

    initial begin
        S_AXI_ACLK    = 0;
        S_AXI_ARESETN = 0;
        S_AXI_AWADDR  = 0;
        S_AXI_AWPROT  = 0;
        S_AXI_AWVALID = 0;
        S_AXI_WDATA   = 0;
        S_AXI_WSTRB   = 4'h0;
        S_AXI_AWVALID = 0;
        S_AXI_BREADY  = 0;
        S_AXI_ARADDR  = 0;
        S_AXI_ARPROT  = 0;
        S_AXI_ARVALID = 0;
        S_AXI_RREADY  = 0;
        repeat (3) @(posedge S_AXI_ACLK);
        S_AXI_ARESETN = 1;

        repeat (3) @(posedge S_AXI_ACLK);
        axi_write(4'h0, 32'hDEADBEEF);
        axi_write(4'h4, 32'hCAFEBABE);
        axi_write(4'h8, 32'H12345678);
        axi_write(4'hc, 32'hAAAABBBB);

        repeat (3) @(posedge S_AXI_ACLK);
        axi_read(4'h0);
        axi_read(4'h4);
        axi_read(4'h8);
        axi_read(4'hc);

        repeat (3) @(posedge S_AXI_ACLK);
        $finish;

    end

endmodule
