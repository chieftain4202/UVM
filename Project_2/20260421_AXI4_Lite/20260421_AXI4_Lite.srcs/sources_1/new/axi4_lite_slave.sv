`timescale 1ns / 1ps


module axi4_lite_slave(
    input  logic        ACLK,
    input  logic        ARESETn,
    // AW channeL
    output logic [31:0] AWADDR,
    output logic        AWVALID,
    input  logic        AWREADY,
    // W channeL
    output logic [31:0] WDATA,
    output logic        WVALID,
    input  logic        WREADY,
    // B channeL
    input  logic [ 1:0] BRESP,
    input  logic        BVALID,
    output logic        BREADY,
    // AR channeL
    output logic [31:0] ARADDR,
    output logic        ARVALID,
    input  logic        ARREADY,
    // R channeL
    input  logic [31:0] RDATA,
    input  logic        RVALID,
    output logic        RREADY,
    input  logic [ 1:0] RRESP,
    // Internal Siganls
    input  logic        transfer,
    output logic        ready,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    input  logic        write,
    output logic [31:0] rdata
    );
endmodule
