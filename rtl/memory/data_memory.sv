`timescale 1ns/1ps

module data_memory #(
    parameter integer WORDS = 256
) (
    input  logic        clk,

    input  logic        mem_read,
    input  logic        mem_write,

    input  logic [31:0] address,
    input  logic [31:0] write_data,

    output logic [31:0] read_data
);

    localparam integer INDEX_WIDTH = $clog2(WORDS);

    logic [31:0] memory [0:WORDS-1];

    logic [INDEX_WIDTH-1:0] word_index;
    logic                   address_in_range;
    logic                   address_aligned;

    integer i;

    initial begin
        for (i = 0; i < WORDS; i = i + 1) begin
            memory[i] = 32'b0;
        end
    end

    /*
     * Convert a byte address into a word index.
     *
     * address 0x00 -> memory[0]
     * address 0x04 -> memory[1]
     * address 0x08 -> memory[2]
     */
    assign word_index =
        address[INDEX_WIDTH+1:2];

    /*
     * Upper address bits must be zero for the address to fit
     * inside this small memory.
     */
    assign address_in_range =
        (address[31:INDEX_WIDTH+2] == '0);

    /*
     * This memory currently supports aligned 32-bit words only.
     */
    assign address_aligned =
        (address[1:0] == 2'b00);

    /*
     * Combinational read.
     */
    always_comb begin
        if (mem_read && address_in_range && address_aligned) begin
            read_data = memory[word_index];
        end
        else begin
            read_data = 32'b0;
        end
    end

    /*
     * Clocked write.
     */
    always_ff @(posedge clk) begin
        if (mem_write && address_in_range && address_aligned) begin
            memory[word_index] <= write_data;
        end
    end

endmodule
