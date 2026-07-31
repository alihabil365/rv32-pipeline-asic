`timescale 1ns/1ps

module tb_instruction_memory;

    logic [31:0] address;
    logic [31:0] instruction;

    integer failures;

    instruction_memory #(
        .WORDS(8)
    ) dut (
        .address     (address),
        .instruction (instruction)
    );

    task automatic check_instruction (
        input logic [31:0] test_address,
        input logic [31:0] expected_instruction,
        input string       test_name
    );
        begin
            address = test_address;

            #1;

            if (instruction !== expected_instruction) begin
                $display(
                    "[FAIL] %s | address=%h instruction=%h expected=%h",
                    test_name,
                    address,
                    instruction,
                    expected_instruction
                );

                failures = failures + 1;
            end
            else begin
                $display(
                    "[PASS] %s | address=%h instruction=%h",
                    test_name,
                    address,
                    instruction
                );
            end
        end
    endtask

    initial begin
        failures = 0;
        address  = 32'b0;

        #1;

        dut.memory[0] = 32'h0050_0093;
        dut.memory[1] = 32'h0070_0113;
        dut.memory[2] = 32'h0020_81B3;

        check_instruction(
            32'h0000_0000,
            32'h0050_0093,
            "read first instruction"
        );

        check_instruction(
            32'h0000_0004,
            32'h0070_0113,
            "read second instruction"
        );

        check_instruction(
            32'h0000_0008,
            32'h0020_81B3,
            "read third instruction"
        );

        check_instruction(
            32'h0000_0001,
            32'h0000_0013,
            "misaligned address returns NOP"
        );

        check_instruction(
            32'h0000_0020,
            32'h0000_0013,
            "out-of-range address returns NOP"
        );

        if (failures == 0) begin
            $display("");
            $display("================================");
            $display("ALL INSTRUCTION MEMORY TESTS PASSED");
            $display("================================");
            $finish;
        end
        else begin
            $fatal(
                1,
                "%0d instruction-memory test(s) failed",
                failures
            );
        end
    end

endmodule
