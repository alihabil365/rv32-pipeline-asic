`timescale 1ns/1ps

module tb_data_memory;

    logic        clk;
    logic        mem_read;
    logic        mem_write;
    logic [31:0] address;
    logic [31:0] write_data;
    logic [31:0] read_data;

    integer failures;

    data_memory #(
        .WORDS(8)
    ) dut (
        .clk        (clk),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .address    (address),
        .write_data (write_data),
        .read_data  (read_data)
    );

    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end

    task automatic write_word (
        input logic [31:0] test_address,
        input logic [31:0] test_data,
        input logic        enable_write
    );
        begin
            @(negedge clk);

            address    = test_address;
            write_data = test_data;
            mem_write  = enable_write;
            mem_read   = 1'b0;

            @(posedge clk);
            #1;

            mem_write = 1'b0;
        end
    endtask

    task automatic check_read (
        input logic [31:0] test_address,
        input logic [31:0] expected_data,
        input string       test_name
    );
        begin
            address  = test_address;
            mem_read = 1'b1;

            #1;

            if (read_data !== expected_data) begin
                $display(
                    "[FAIL] %s | address=%h data=%h expected=%h",
                    test_name,
                    address,
                    read_data,
                    expected_data
                );

                failures = failures + 1;
            end
            else begin
                $display(
                    "[PASS] %s | address=%h data=%h",
                    test_name,
                    address,
                    read_data
                );
            end

            mem_read = 1'b0;
        end
    endtask

    initial begin
        failures   = 0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        address    = 32'b0;
        write_data = 32'b0;

        #1;

        check_read(
            32'h0000_0000,
            32'h0000_0000,
            "memory initially zero"
        );

        write_word(
            32'h0000_0000,
            32'hDEAD_BEEF,
            1'b1
        );

        check_read(
            32'h0000_0000,
            32'hDEAD_BEEF,
            "write and read word zero"
        );

        write_word(
            32'h0000_0004,
            32'h1234_5678,
            1'b1
        );

        check_read(
            32'h0000_0004,
            32'h1234_5678,
            "write and read word one"
        );

        /*
         * A disabled write must not change memory.
         */
        write_word(
            32'h0000_0000,
            32'hCAFE_BABE,
            1'b0
        );

        check_read(
            32'h0000_0000,
            32'hDEAD_BEEF,
            "disabled write preserves data"
        );

        /*
         * Address 0x20 is outside an eight-word memory.
         */
        check_read(
            32'h0000_0020,
            32'h0000_0000,
            "out-of-range read returns zero"
        );

        /*
         * Address 0x2 is not aligned to a four-byte word boundary.
         * The write must be ignored.
         */
        write_word(
            32'h0000_0002,
            32'hAAAA_BBBB,
            1'b1
        );

        check_read(
            32'h0000_0000,
            32'hDEAD_BEEF,
            "misaligned write is ignored"
        );

        check_read(
            32'h0000_0002,
            32'h0000_0000,
            "misaligned read returns zero"
        );

        if (failures == 0) begin
            $display("");
            $display("================================");
            $display("ALL DATA MEMORY TESTS PASSED");
            $display("================================");
            $finish;
        end
        else begin
            $fatal(
                1,
                "%0d data-memory test(s) failed",
                failures
            );
        end
    end

endmodule
