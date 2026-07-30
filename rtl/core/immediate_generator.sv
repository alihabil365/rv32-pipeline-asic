`timescale 1ns/1ps

module immediate_generator (
    input  logic [31:0] instruction,
    output logic [31:0] immediate
);

    logic [6:0] opcode;

    // The opcode is always stored in instruction bits [6:0].
    assign opcode = instruction[6:0];

    // RV32I opcodes that use immediate values.
    localparam logic [6:0] OPCODE_LOAD    = 7'b0000011;
    localparam logic [6:0] OPCODE_OP_IMM  = 7'b0010011;
    localparam logic [6:0] OPCODE_AUIPC   = 7'b0010111;
    localparam logic [6:0] OPCODE_STORE   = 7'b0100011;
    localparam logic [6:0] OPCODE_LUI     = 7'b0110111;
    localparam logic [6:0] OPCODE_BRANCH  = 7'b1100011;
    localparam logic [6:0] OPCODE_JALR    = 7'b1100111;
    localparam logic [6:0] OPCODE_JAL     = 7'b1101111;

    always_comb begin
        // Instructions without immediates produce zero.
        immediate = 32'b0;

        case (opcode)

            /*
             * I-type immediate:
             *   ADDI and other immediate arithmetic instructions
             *   Loads such as LW
             *   JALR
             *
             * instruction[31] is repeated to sign-extend the
             * 12-bit value to 32 bits.
             */
            OPCODE_LOAD,
            OPCODE_OP_IMM,
            OPCODE_JALR: begin
                immediate = {
                    {20{instruction[31]}},
                    instruction[31:20]
                };
            end

            /*
             * S-type immediate:
             *   Store instructions such as SW
             *
             * The immediate is split across two instruction fields.
             */
            OPCODE_STORE: begin
                immediate = {
                    {20{instruction[31]}},
                    instruction[31:25],
                    instruction[11:7]
                };
            end

            /*
             * B-type immediate:
             *   Conditional branches such as BEQ
             *
             * Bit zero is always zero.
             */
            OPCODE_BRANCH: begin
                immediate = {
                    {19{instruction[31]}},
                    instruction[31],
                    instruction[7],
                    instruction[30:25],
                    instruction[11:8],
                    1'b0
                };
            end

            /*
             * U-type immediate:
             *   LUI and AUIPC
             *
             * The upper twenty bits come directly from the
             * instruction. The lower twelve bits become zero.
             */
            OPCODE_LUI,
            OPCODE_AUIPC: begin
                immediate = {
                    instruction[31:12],
                    12'b0
                };
            end

            /*
             * J-type immediate:
             *   JAL
             *
             * Bit zero is always zero.
             */
            OPCODE_JAL: begin
                immediate = {
                    {11{instruction[31]}},
                    instruction[31],
                    instruction[19:12],
                    instruction[20],
                    instruction[30:21],
                    1'b0
                };
            end

            default: begin
                immediate = 32'b0;
            end
        endcase
    end

endmodule
