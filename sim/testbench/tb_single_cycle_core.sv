`timescale 1ns/1ps

module tb_single_cycle_core;

    logic clk;
    logic reset_n;

    logic [31:0] debug_pc;
    logic [31:0] debug_instruction;
    logic [31:0] debug_alu_result;
    logic [6:0]  debug_opcode;
    logic        debug_alu_zero;
    logic        debug_illegal_instruction;

    integer failures;

    single_cycle_core #(
        .IMEM_WORDS      (256),
        .IMEM_INIT_FILE  ("sim/tests/single_cycle_smoke.hex"),
        .IMEM_INIT_WORDS (18),
        .DMEM_WORDS      (256),
        .RESET_VECTOR    (32'h0000_0000)
    ) dut (
        .clk                       (clk),
        .reset_n                   (reset_n),
        .debug_pc                  (debug_pc),
        .debug_instruction         (debug_instruction),
        .debug_alu_result          (debug_alu_result),
        .debug_opcode              (debug_opcode),
        .debug_alu_zero            (debug_alu_zero),
        .debug_illegal_instruction (debug_illegal_instruction)
    );

    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end

    task automatic check_register (
        input integer      register_number,
        input logic [31:0] expected_value,
        input string       test_name
    );
        logic [31:0] actual_value;

        begin
            actual_value =
                dut.register_file_inst.registers[register_number];

            if (actual_value !== expected_value) begin
                $display(
                    "[FAIL] %s | x%0d=%h expected=%h",
                    test_name,
                    register_number,
                    actual_value,
                    expected_value
                );

                failures = failures + 1;
            end
            else begin
                $display(
                    "[PASS] %s | x%0d=%h",
                    test_name,
                    register_number,
                    actual_value
                );
            end
        end
    endtask

    task automatic check_memory (
        input integer      word_number,
        input logic [31:0] expected_value,
        input string       test_name
    );
        logic [31:0] actual_value;

        begin
            actual_value =
                dut.data_memory_inst.memory[word_number];

            if (actual_value !== expected_value) begin
                $display(
                    "[FAIL] %s | memory[%0d]=%h expected=%h",
                    test_name,
                    word_number,
                    actual_value,
                    expected_value
                );

                failures = failures + 1;
            end
            else begin
                $display(
                    "[PASS] %s | memory[%0d]=%h",
                    test_name,
                    word_number,
                    actual_value
                );
            end
        end
    endtask

    task automatic check_debug_value (
        input logic [31:0] actual_value,
        input logic [31:0] expected_value,
        input string       test_name
    );
        begin
            if (actual_value !== expected_value) begin
                $display(
                    "[FAIL] %s | actual=%h expected=%h",
                    test_name,
                    actual_value,
                    expected_value
                );

                failures = failures + 1;
            end
            else begin
                $display(
                    "[PASS] %s | value=%h",
                    test_name,
                    actual_value
                );
            end
        end
    endtask

    initial begin
        failures = 0;
        reset_n  = 1'b0;

        /*
         * Hold synchronous reset for two rising clock edges.
         */
        repeat (2) begin
            @(posedge clk);
        end

        @(negedge clk);
        reset_n = 1'b1;

        /*
         * Run enough cycles to execute the program and enter
         * the final JAL x0, 0 loop.
         */
        repeat (22) begin
            @(posedge clk);
        end

        #1;

        check_register(1,  32'd5,          "ADDI wrote x1");
        check_register(2,  32'd7,          "ADDI wrote x2");
        check_register(3,  32'd12,         "ADD produced twelve");
        check_register(4,  32'd12,         "LW loaded stored value");

        /*
         * x5 must be 1 because the branch skipped the instruction
         * that attempted to write 99.
         */
        check_register(5,  32'd1,          "BEQ skipped instruction");

        /*
         * JAL at address 0x20 writes PC+4 = 0x24 into x6.
         */
        check_register(6,  32'h0000_0024,  "JAL wrote return address");

        /*
         * x7 must be 2 because JAL skipped the write of 99.
         */
        check_register(7,  32'd2,          "JAL skipped instruction");

        check_register(8,  32'h1234_5000,  "LUI wrote upper immediate");
        check_register(9,  32'h0000_0030,  "AUIPC added current PC");

        check_register(10, 32'd60,         "ADDI prepared JALR target");

        /*
         * JALR at address 0x38 writes PC+4 = 0x3C into x11.
         */
        check_register(11, 32'h0000_003C,  "JALR wrote return address");

        check_register(12, 32'd3,          "JALR reached target");

        check_memory(0, 32'd12, "SW stored result at address zero");
        check_memory(1, 32'd12, "SW stored result at address four");

        check_debug_value(
            debug_pc,
            32'h0000_0044,
            "processor reached final loop"
        );

        check_debug_value(
            debug_instruction,
            32'h0000_006F,
            "final instruction is JAL x0 zero"
        );

        if (debug_illegal_instruction !== 1'b0) begin
            $display(
                "[FAIL] final instruction marked illegal"
            );

            failures = failures + 1;
        end
        else begin
            $display(
                "[PASS] final instruction is legal"
            );
        end

        if (failures == 0) begin
            $display("");
            $display("========================================");
            $display("ALL SINGLE-CYCLE CPU TESTS PASSED");
            $display("========================================");
            $finish;
        end
        else begin
            $fatal(
                1,
                "%0d single-cycle CPU test(s) failed",
                failures
            );
        end
    end

endmodule
