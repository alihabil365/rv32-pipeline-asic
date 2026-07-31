`timescale 1ns/1ps

module instruction_memory #(
    parameter integer WORDS = 256,
    parameter         INIT_FILE = "",
    parameter integer INIT_WORDS = 0
) (
    input  logic [31:0] address,
    output logic [31:0] instruction
);

    localparam integer INDEX_WIDTH = $clog2(WORDS);
    localparam logic [31:0] NOP_INSTRUCTION = 32'h0000_0013;

    logic [31:0] memory [0:WORDS-1];

    logic [INDEX_WIDTH-1:0] word_index;
    logic                   address_in_range;
    logic                   address_aligned;

    integer i;

    initial begin
        for (i = 0; i < WORDS; i = i + 1) begin
            memory[i] = NOP_INSTRUCTION;
        end

        if (INIT_FILE != "") begin
            if (INIT_WORDS > 0) begin
                $readmemh(
                    INIT_FILE,
                    memory,
                    0,
                    INIT_WORDS - 1
                );
            end
            else begin
                $readmemh(INIT_FILE, memory);
            end
        end
    end

    /*
     * Divide the byte address by four to obtain the word index.
     */
    assign word_index =
        address[INDEX_WIDTH+1:2];

    /*
     * For 256 words, valid addresses range from:
     * 0x00000000 through 0x000003FF.
     */
    assign address_in_range =
        (address[31:INDEX_WIDTH+2] == '0);

    /*
     * RV32I instructions must be fetched from aligned addresses
     * in this non-compressed implementation.
     */
    assign address_aligned =
        (address[1:0] == 2'b00);

    always_comb begin
        if (address_in_range && address_aligned) begin
            instruction = memory[word_index];
        end
        else begin
            instruction = NOP_INSTRUCTION;
        end
    end

endmodule
