`timescale 1ns/1ps

module register_file (
    input  logic        clk,

    // One synchronous write port
    input  logic        write_enable,
    input  logic [4:0]  write_addr,
    input  logic [31:0] write_data,

    // Two asynchronous read ports
    input  logic [4:0]  read_addr_a,
    input  logic [4:0]  read_addr_b,
    output logic [31:0] read_data_a,
    output logic [31:0] read_data_b
);

    // Thirty-two registers, each thirty-two bits wide.
    logic [31:0] registers [0:31];

    /*
     * Synchronous write:
     *
     * A stored register changes only on the rising clock edge.
     * Writes to x0 are blocked because RISC-V requires x0 to
     * remain permanently equal to zero.
     */
    always_ff @(posedge clk) begin
        if (write_enable && (write_addr != 5'd0)) begin
            registers[write_addr] <= write_data;
        end
    end

    /*
     * Asynchronous reads:
     *
     * Changing a read address immediately selects a register.
     * Reading x0 always returns zero, regardless of the contents
     * of registers[0].
     */
    always_comb begin
        if (read_addr_a == 5'd0) begin
            read_data_a = 32'b0;
        end
        else begin
            read_data_a = registers[read_addr_a];
        end

        if (read_addr_b == 5'd0) begin
            read_data_b = 32'b0;
        end
        else begin
            read_data_b = registers[read_addr_b];
        end
    end

endmodule
