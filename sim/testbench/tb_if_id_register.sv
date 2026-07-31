`timescale 1ns/1ps

module tb_if_id_register;

    logic        clk;
    logic        reset_n;
    logic        write_enable;
    logic        flush;

    logic [31:0] fetch_pc;
    logic [31:0] fetch_instruction;

    logic [31:0] decode_pc;
    logic [31:0] decode_instruction;
    logic        decode_valid;

    integer failures;

    localparam logic [31:0] NOP_INSTRUCTION = 32'h0000_0013;

    if_id_register dut (
        .clk                (clk),
        .reset_n            (reset_n),
        .write_enable       (write_enable),
        .flush              (flush),
        .fetch_pc           (fetch_pc),
        .fetch_instruction  (fetch_instruction),
        .decode_pc          (decode_pc),
        .decode_instruction (decode_instruction),
        .decode_valid       (decode_valid)
    );

    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end

    task automatic check_state (
        input logic [31:0] expected_pc,
        input logic [31:0] expected_instruction,
        input logic        expected_valid,
        input string       test_name
    );
        begin
            #1;

            if (
                (decode_pc          !== expected_pc)          ||
                (decode_instruction !== expected_instruction) ||
                (decode_valid       !== expected_valid)
            ) begin
                $display("[FAIL] %s", test_name);
                $display(
                    "  PC:          actual=%h expected=%h",
                    decode_pc,
                    expected_pc
                );
                $display(
                    "  instruction: actual=%h expected=%h",
                    decode_instruction,
                    expected_instruction
                );
                $display(
                    "  valid:       actual=%b expected=%b",
                    decode_valid,
                    expected_valid
                );

                failures = failures + 1;
            end
            else begin
                $display(
                    "[PASS] %s | PC=%h instruction=%h valid=%b",
                    test_name,
                    decode_pc,
                    decode_instruction,
                    decode_valid
                );
            end
        end
    endtask

    initial begin
        failures = 0;

        reset_n          = 1'b0;
        write_enable     = 1'b0;
        flush            = 1'b0;
        fetch_pc         = 32'hXXXX_XXXX;
        fetch_instruction = 32'hXXXX_XXXX;

        /*
         * Reset should insert an invalid NOP.
         */
        @(posedge clk);

        check_state(
            32'h0000_0000,
            NOP_INSTRUCTION,
            1'b0,
            "reset clears IF/ID register"
        );

        /*
         * Capture the first fetched instruction.
         *
         * 0x00500093 = ADDI x1, x0, 5
         */
        @(negedge clk);

        reset_n           = 1'b1;
        write_enable      = 1'b1;
        flush             = 1'b0;
        fetch_pc          = 32'h0000_0000;
        fetch_instruction = 32'h0050_0093;

        @(posedge clk);

        check_state(
            32'h0000_0000,
            32'h0050_0093,
            1'b1,
            "capture first instruction"
        );

        /*
         * Capture the next sequential instruction.
         *
         * 0x00700113 = ADDI x2, x0, 7
         */
        @(negedge clk);

        fetch_pc          = 32'h0000_0004;
        fetch_instruction = 32'h0070_0113;

        @(posedge clk);

        check_state(
            32'h0000_0004,
            32'h0070_0113,
            1'b1,
            "capture second instruction"
        );

        /*
         * Stall the pipeline. New Fetch values must not enter
         * the Decode stage.
         */
        @(negedge clk);

        write_enable      = 1'b0;
        fetch_pc          = 32'h0000_0008;
        fetch_instruction = 32'h0020_81B3;

        @(posedge clk);

        check_state(
            32'h0000_0004,
            32'h0070_0113,
            1'b1,
            "stall holds previous instruction"
        );

        /*
         * Flush must discard the held instruction even while
         * write_enable is zero.
         */
        @(negedge clk);

        flush = 1'b1;

        @(posedge clk);

        check_state(
            32'h0000_0000,
            NOP_INSTRUCTION,
            1'b0,
            "flush inserts invalid bubble"
        );

        /*
         * Resume normal instruction flow.
         */
        @(negedge clk);

        flush             = 1'b0;
        write_enable      = 1'b1;
        fetch_pc          = 32'h0000_0040;
        fetch_instruction = 32'h0030_2023;

        @(posedge clk);

        check_state(
            32'h0000_0040,
            32'h0030_2023,
            1'b1,
            "pipeline resumes after flush"
        );

        /*
         * Reset must have priority over flush and write enable.
         */
        @(negedge clk);

        reset_n           = 1'b0;
        flush             = 1'b1;
        write_enable      = 1'b1;
        fetch_pc          = 32'hFFFF_FFFF;
        fetch_instruction = 32'hFFFF_FFFF;

        @(posedge clk);

        check_state(
            32'h0000_0000,
            NOP_INSTRUCTION,
            1'b0,
            "reset has highest priority"
        );

        if (failures == 0) begin
            $display("");
            $display("========================================");
            $display("ALL IF/ID REGISTER TESTS PASSED");
            $display("========================================");
            $finish;
        end
        else begin
            $fatal(
                1,
                "%0d IF/ID register test(s) failed",
                failures
            );
        end
    end

endmodule
