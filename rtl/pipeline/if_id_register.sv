`timescale 1ns/1ps

module if_id_register (
    input  logic        clk,
    input  logic        reset_n,

    // Pipeline controls
    input  logic        write_enable,
    input  logic        flush,

    // Values produced by the Fetch stage
    input  logic [31:0] fetch_pc,
    input  logic [31:0] fetch_instruction,

    // Values delivered to the Decode stage
    output logic [31:0] decode_pc,
    output logic [31:0] decode_instruction,
    output logic        decode_valid
);

    /*
     * ADDI x0, x0, 0
     *
     * This instruction changes no architectural state and is
     * conventionally used as a RISC-V NOP.
     */
    localparam logic [31:0] NOP_INSTRUCTION = 32'h0000_0013;

    always_ff @(posedge clk) begin

        /*
         * Reset empties the pipeline stage.
         */
        if (!reset_n) begin
            decode_pc          <= 32'b0;
            decode_instruction <= NOP_INSTRUCTION;
            decode_valid       <= 1'b0;
        end

        /*
         * Flush discards the instruction currently entering Decode.
         */
        else if (flush) begin
            decode_pc          <= 32'b0;
            decode_instruction <= NOP_INSTRUCTION;
            decode_valid       <= 1'b0;
        end

        /*
         * Normal pipeline advance.
         */
        else if (write_enable) begin
            decode_pc          <= fetch_pc;
            decode_instruction <= fetch_instruction;
            decode_valid       <= 1'b1;
        end

        /*
         * When write_enable is zero, all outputs retain their
         * previous values. This creates a pipeline stall.
         */
    end

endmodule
