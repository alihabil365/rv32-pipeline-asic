`timescale 1ns/1ps

module program_counter #(
    parameter logic [31:0] RESET_VECTOR = 32'h0000_0000
) (
    input  logic        clk,
    input  logic        reset_n,
    input  logic        pc_write_enable,
    input  logic [31:0] next_pc,

    output logic [31:0] current_pc
);

    /*
     * The program counter is a 32-bit clocked register.
     *
     * reset_n = 0:
     *   Load the reset vector.
     *
     * reset_n = 1 and pc_write_enable = 1:
     *   Load the next PC value.
     *
     * pc_write_enable = 0:
     *   Retain the current PC value.
     */
    always_ff @(posedge clk) begin
        if (!reset_n) begin
            current_pc <= RESET_VECTOR;
        end
        else if (pc_write_enable) begin
            current_pc <= next_pc;
        end
    end

endmodule
