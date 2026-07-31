`timescale 1ns/1ps

module tb_program_counter;

    logic        clk;
    logic        reset_n;
    logic        pc_write_enable;
    logic [31:0] next_pc;
    logic [31:0] current_pc;

    integer failures;

    localparam logic [31:0] TEST_RESET_VECTOR = 32'h0000_0000;

    program_counter #(
        .RESET_VECTOR(TEST_RESET_VECTOR)
    ) dut (
        .clk             (clk),
        .reset_n         (reset_n),
        .pc_write_enable (pc_write_enable),
        .next_pc         (next_pc),
        .current_pc      (current_pc)
    );

    // Generate a clock with a period of 10 ns.
    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end

    task automatic check_pc (
        input logic [31:0] expected_pc,
        input string       test_name
    );
        begin
            #1;

            if (current_pc !== expected_pc) begin
                $display(
                    "[FAIL] %s | current_pc=%h expected=%h",
                    test_name,
                    current_pc,
                    expected_pc
                );

                failures = failures + 1;
            end
            else begin
                $display(
                    "[PASS] %s | current_pc=%h",
                    test_name,
                    current_pc
                );
            end
        end
    endtask

    task automatic clock_and_check (
        input logic [31:0] expected_pc,
        input string       test_name
    );
        begin
            @(posedge clk);
            check_pc(expected_pc, test_name);
        end
    endtask

    initial begin
        failures = 0;

        reset_n         = 1'b0;
        pc_write_enable = 1'b0;
        next_pc         = 32'hXXXX_XXXX;

        /*
         * Synchronous reset:
         *
         * The PC takes the reset value at the rising edge.
         */
        clock_and_check(
            TEST_RESET_VECTOR,
            "reset loads reset vector"
        );

        /*
         * Release reset and load PC + 4.
         */
        @(negedge clk);
        reset_n         = 1'b1;
        pc_write_enable = 1'b1;
        next_pc         = 32'h0000_0004;

        clock_and_check(
            32'h0000_0004,
            "load first sequential PC"
        );

        /*
         * Load another sequential address.
         */
        @(negedge clk);
        next_pc = 32'h0000_0008;

        clock_and_check(
            32'h0000_0008,
            "load second sequential PC"
        );

        /*
         * Disable writes. The PC must hold 0x8 even though
         * next_pc changes.
         */
        @(negedge clk);
        pc_write_enable = 1'b0;
        next_pc         = 32'h1234_5678;

        clock_and_check(
            32'h0000_0008,
            "disabled write holds PC"
        );

        /*
         * Re-enable PC writing and load a nonsequential target.
         * This represents behavior needed later for a branch or jump.
         */
        @(negedge clk);
        pc_write_enable = 1'b1;
        next_pc         = 32'h0000_0040;

        clock_and_check(
            32'h0000_0040,
            "load branch or jump target"
        );

        /*
         * Assert reset again. Reset must have priority over
         * pc_write_enable and next_pc.
         */
        @(negedge clk);
        reset_n         = 1'b0;
        pc_write_enable = 1'b1;
        next_pc         = 32'hFFFF_FFFF;

        clock_and_check(
            TEST_RESET_VECTOR,
            "reset has priority"
        );

        if (failures == 0) begin
            $display("");
            $display("========================================");
            $display("ALL PROGRAM COUNTER TESTS PASSED");
            $display("========================================");
            $finish;
        end
        else begin
            $fatal(
                1,
                "%0d program-counter test(s) failed",
                failures
            );
        end
    end

endmodule
