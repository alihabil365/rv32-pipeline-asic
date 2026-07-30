`timescale 1ns/1ps

module tb_immediate_generator;

    logic [31:0] instruction;
    logic [31:0] immediate;

    integer failures;

    localparam logic [6:0] OPCODE_LOAD    = 7'b0000011;
    localparam logic [6:0] OPCODE_OP_IMM  = 7'b0010011;
    localparam logic [6:0] OPCODE_AUIPC   = 7'b0010111;
    localparam logic [6:0] OPCODE_STORE   = 7'b0100011;
    localparam logic [6:0] OPCODE_OP      = 7'b0110011;
    localparam logic [6:0] OPCODE_LUI     = 7'b0110111;
    localparam logic [6:0] OPCODE_BRANCH  = 7'b1100011;
    localparam logic [6:0] OPCODE_JALR    = 7'b1100111;
    localparam logic [6:0] OPCODE_JAL     = 7'b1101111;

    immediate_generator dut (
        .instruction (instruction),
        .immediate   (immediate)
    );

    /*
     * These helper functions construct properly formatted
     * 32-bit RISC-V instructions for the tests.
     */

    function automatic logic [31:0] encode_i (
        input logic signed [31:0] imm,
        input logic        [4:0]  rs1,
        input logic        [2:0]  funct3,
        input logic        [4:0]  rd,
        input logic        [6:0]  opcode
    );
        encode_i = {
            imm[11:0],
            rs1,
            funct3,
            rd,
            opcode
        };
    endfunction

    function automatic logic [31:0] encode_s (
        input logic signed [31:0] imm,
        input logic        [4:0]  rs2,
        input logic        [4:0]  rs1,
        input logic        [2:0]  funct3,
        input logic        [6:0]  opcode
    );
        encode_s = {
            imm[11:5],
            rs2,
            rs1,
            funct3,
            imm[4:0],
            opcode
        };
    endfunction

    function automatic logic [31:0] encode_b (
        input logic signed [31:0] imm,
        input logic        [4:0]  rs2,
        input logic        [4:0]  rs1,
        input logic        [2:0]  funct3,
        input logic        [6:0]  opcode
    );
        encode_b = {
            imm[12],
            imm[10:5],
            rs2,
            rs1,
            funct3,
            imm[4:1],
            imm[11],
            opcode
        };
    endfunction

    function automatic logic [31:0] encode_u (
        input logic [31:0] imm,
        input logic [4:0]  rd,
        input logic [6:0]  opcode
    );
        encode_u = {
            imm[31:12],
            rd,
            opcode
        };
    endfunction

    function automatic logic [31:0] encode_j (
        input logic signed [31:0] imm,
        input logic        [4:0]  rd,
        input logic        [6:0]  opcode
    );
        encode_j = {
            imm[20],
            imm[10:1],
            imm[11],
            imm[19:12],
            rd,
            opcode
        };
    endfunction

    task automatic run_test (
        input logic [31:0] test_instruction,
        input logic [31:0] expected_immediate,
        input string       test_name
    );
        begin
            instruction = test_instruction;

            #1;

            if (immediate !== expected_immediate) begin
                $display(
                    "[FAIL] %s | instruction=%h immediate=%h expected=%h",
                    test_name,
                    instruction,
                    immediate,
                    expected_immediate
                );

                failures = failures + 1;
            end
            else begin
                $display(
                    "[PASS] %s | immediate=%h",
                    test_name,
                    immediate
                );
            end
        end
    endtask

    initial begin
        failures = 0;
        instruction = 32'b0;

        // I-type positive immediate: ADDI with immediate 25.
        run_test(
            encode_i(
                32'sd25,
                5'd2,
                3'b000,
                5'd1,
                OPCODE_OP_IMM
            ),
            32'd25,
            "I-type positive ADDI immediate"
        );

        // I-type negative immediate: ADDI with immediate -16.
        run_test(
            encode_i(
                -32'sd16,
                5'd2,
                3'b000,
                5'd1,
                OPCODE_OP_IMM
            ),
            32'hFFFF_FFF0,
            "I-type negative ADDI immediate"
        );

        // Load offset uses the I-type layout.
        run_test(
            encode_i(
                -32'sd4,
                5'd3,
                3'b010,
                5'd4,
                OPCODE_LOAD
            ),
            32'hFFFF_FFFC,
            "I-type negative load offset"
        );

        // S-type positive store offset.
        run_test(
            encode_s(
                32'sd12,
                5'd5,
                5'd1,
                3'b010,
                OPCODE_STORE
            ),
            32'd12,
            "S-type positive store offset"
        );

        // S-type negative store offset.
        run_test(
            encode_s(
                -32'sd20,
                5'd5,
                5'd1,
                3'b010,
                OPCODE_STORE
            ),
            32'hFFFF_FFEC,
            "S-type negative store offset"
        );

        // B-type forward branch offset.
        run_test(
            encode_b(
                32'sd16,
                5'd2,
                5'd1,
                3'b000,
                OPCODE_BRANCH
            ),
            32'd16,
            "B-type forward branch offset"
        );

        // B-type backward branch offset.
        run_test(
            encode_b(
                -32'sd8,
                5'd2,
                5'd1,
                3'b000,
                OPCODE_BRANCH
            ),
            32'hFFFF_FFF8,
            "B-type backward branch offset"
        );

        // U-type upper immediate.
        run_test(
            encode_u(
                32'h1234_5000,
                5'd5,
                OPCODE_LUI
            ),
            32'h1234_5000,
            "U-type LUI immediate"
        );

        // J-type forward jump.
        run_test(
            encode_j(
                32'sd2048,
                5'd1,
                OPCODE_JAL
            ),
            32'd2048,
            "J-type forward jump offset"
        );

        // J-type backward jump.
        run_test(
            encode_j(
                -32'sd4,
                5'd1,
                OPCODE_JAL
            ),
            32'hFFFF_FFFC,
            "J-type backward jump offset"
        );

        // R-type instructions do not use an immediate.
        run_test(
            {
                7'b0000000,
                5'd2,
                5'd1,
                3'b000,
                5'd5,
                OPCODE_OP
            },
            32'b0,
            "R-type produces zero immediate"
        );

        if (failures == 0) begin
            $display("");
            $display("========================================");
            $display("ALL IMMEDIATE GENERATOR TESTS PASSED");
            $display("========================================");
            $finish;
        end
        else begin
            $fatal(
                1,
                "%0d immediate-generator test(s) failed",
                failures
            );
        end
    end

endmodule