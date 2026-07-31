`timescale 1ns/1ps

module tb_branch_unit;

    logic        branch;
    logic [2:0]  funct3;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic        branch_taken;

    integer failures;

    branch_unit dut (
        .branch       (branch),
        .funct3       (funct3),
        .rs1_data     (rs1_data),
        .rs2_data     (rs2_data),
        .branch_taken (branch_taken)
    );

    task automatic run_test (
        input logic        test_branch,
        input logic [2:0]  test_funct3,
        input logic [31:0] test_rs1,
        input logic [31:0] test_rs2,
        input logic        expected_taken,
        input string       test_name
    );
        begin
            branch   = test_branch;
            funct3   = test_funct3;
            rs1_data = test_rs1;
            rs2_data = test_rs2;

            #1;

            if (branch_taken !== expected_taken) begin
                $display(
                    "[FAIL] %s | taken=%b expected=%b",
                    test_name,
                    branch_taken,
                    expected_taken
                );

                failures = failures + 1;
            end
            else begin
                $display(
                    "[PASS] %s | taken=%b",
                    test_name,
                    branch_taken
                );
            end
        end
    endtask

    initial begin
        failures = 0;

        run_test(1'b0, 3'b000, 32'd5, 32'd5, 1'b0,
                 "branch disabled");

        run_test(1'b1, 3'b000, 32'd5, 32'd5, 1'b1,
                 "BEQ taken");

        run_test(1'b1, 3'b000, 32'd5, 32'd6, 1'b0,
                 "BEQ not taken");

        run_test(1'b1, 3'b001, 32'd5, 32'd6, 1'b1,
                 "BNE taken");

        run_test(1'b1, 3'b100, 32'hFFFF_FFFF, 32'd1, 1'b1,
                 "BLT signed taken");

        run_test(1'b1, 3'b101, 32'd7, 32'd2, 1'b1,
                 "BGE signed taken");

        run_test(1'b1, 3'b110, 32'd1, 32'hFFFF_FFFF, 1'b1,
                 "BLTU unsigned taken");

        run_test(1'b1, 3'b111, 32'hFFFF_FFFF, 32'd1, 1'b1,
                 "BGEU unsigned taken");

        if (failures == 0) begin
            $display("");
            $display("================================");
            $display("ALL BRANCH UNIT TESTS PASSED");
            $display("================================");
            $finish;
        end
        else begin
            $fatal(1, "%0d branch test(s) failed", failures);
        end
    end

endmodule
