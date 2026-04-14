

module ram_16bit (
    input  logic        clk,
    input  logic        we,
    input  logic [ 7:0] addr,
    input  logic [15:0] wdata,
    output logic [15:0] rdata
);

    logic [15:0] register[0:255];

    always_ff @(posedge clk) begin
        if (we) begin
            register[addr] <= wdata;
        end else begin
            rdata <= register[addr];
        end
    end

endmodule
