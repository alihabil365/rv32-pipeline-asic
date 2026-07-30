`timescale 1ns/1ps

module tb_register_file;

    logic        clk;

    logic        write_enable;
    logic [4:0]  write_addr;
    logic [31:0] write_data;

    logic [4:0]  read_addr_a;
    logic [4:0]  read_addr_b;
    logic [31:0] read_data_a;
    logic [31:0] read_data_b;

    integer failures;

    register_file dut (
        .clk          (clk),
        .write_enable (write_enable),
        .write_addr   (write_addr),
        .write_data   (write_data),
        .read_addr_a  (read_addr_a),
        .read_addr_b  (read_addr_b),
        .read_data_a  (read_data_a),
        .read_data_b  (read_data_b)
    );

    // Generate a clock with a 10 ns period.
    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end

    /*
     * Perform one synchronous register write.
     *
     * Inputs are established on the falling edge so they are
     * stable before the following rising edge.
     */
    task automatic write_register (
        input logic        test_write_enable,
        input logic [4:0]  test_write_addr,
        input logic [31:0] test_write_data
    );
        begin
            @(negedge clk);

            write_enable = test_write_enable;
            write_addr   = test_write_addr;
            write_data   = test_write_data;

            @(posedge clk);
            #1;

            write_enable = 1'b0;
        end
    endtask

    /*
     * Select two registers and check both read ports.
     */
    task automatic check_reads (
        input logic [4:0]  test_addr_a,
        input logic [31:0] expected_data_a,
        input logic [4:0]  test_addr_b,
        input logic [31:0] expected_data_b,
        input string       test_name
    );
        begin
            read_addr_a = test_addr_a;
            read_addr_b = test_addr_b;

            #1;

            if (
                (read_data_a !== expected_data_a) ||
                (read_data_b !== expected_data_b)
            ) begin
                $display(
                    "[FAIL] %s | A: x%0d=%h expected=%h | B: x%0d=%h expected=%h",
                    test_name,
                    read_addr_a,
                    read_data_a,
                    expected_data_a,
                    read_addr_b,
                    read_data_b,
                    expected_data_b
                );

                failures = failures + 1;
            end
            else begin
                $display(
                    "[PASS] %s | A: x%0d=%h | B: x%0d=%h",
                    test_name,
                    read_addr_a,
                    read_data_a,
                    read_addr_b,
                    read_data_b
                );
            end
        end
    endtask

    initial begin
        failures = 0;

        write_enable = 1'b0;
        write_addr   = 5'd0;
        write_data   = 32'b0;
        read_addr_a  = 5'd0;
        read_addr_b  = 5'd0;

        // x0 must always read as zero.
        check_reads(
            5'd0, 32'h0000_0000,
            5'd0, 32'h0000_0000,
            "x0 initially reads zero"
        );

        // Write and read x5.
        write_register(1'b1, 5'd5, 32'hDEAD_BEEF);

        check_reads(
            5'd5, 32'hDEAD_BEEF,
            5'd0, 32'h0000_0000,
            "write x5 and read x0"
        );

        // Write a second register and read both simultaneously.
        write_register(1'b1, 5'd10, 32'h1234_5678);

        check_reads(
            5'd5,  32'hDEAD_BEEF,
            5'd10, 32'h1234_5678,
            "dual read ports"
        );

        // Overwrite an existing register.
        write_register(1'b1, 5'd5, 32'hCAFE_BABE);

        check_reads(
            5'd5,  32'hCAFE_BABE,
            5'd10, 32'h1234_5678,
            "overwrite x5"
        );

        // Confirm that write_enable=0 prevents a write.
        write_register(1'b1, 5'd7, 32'h1111_1111);
        write_register(1'b0, 5'd7, 32'h2222_2222);

        check_reads(
            5'd7, 32'h1111_1111,
            5'd7, 32'h1111_1111,
            "disabled write preserves x7"
        );

        // Attempt to overwrite x0.
        write_register(1'b1, 5'd0, 32'hFFFF_FFFF);

        check_reads(
            5'd0, 32'h0000_0000,
            5'd0, 32'h0000_0000,
            "writes to x0 are blocked"
        );

        if (failures == 0) begin
            $display("");
            $display("========================================");
            $display("ALL REGISTER FILE TESTS PASSED");
            $display("========================================");
            $finish;
        end
        else begin
            $fatal(
                1,
                "%0d register-file test(s) failed",
                failures
            );
        end
    end

endmodule