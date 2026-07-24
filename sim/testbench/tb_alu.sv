`timescale 1ns/1ps

module tb_alu;

    logic [31:0] a;
    logic [31:0] b;
    logic [3:0]  alu_control;

    logic [31:0] result;
    logic        zero;

    integer failures;

    localparam logic [3:0] ALU_ADD  = 4'b0000;
    localparam logic [3:0] ALU_SUB  = 4'b0001;
    localparam logic [3:0] ALU_AND  = 4'b0010;
    localparam logic [3:0] ALU_OR   = 4'b0011;
    localparam logic [3:0] ALU_XOR  = 4'b0100;
    localparam logic [3:0] ALU_SLL  = 4'b0101;
    localparam logic [3:0] ALU_SRL  = 4'b0110;
    localparam logic [3:0] ALU_SRA  = 4'b0111;
    localparam logic [3:0] ALU_SLT  = 4'b1000;
    localparam logic [3:0] ALU_SLTU = 4'b1001;

    alu dut (
        .a           (a),
        .b           (b),
        .alu_control (alu_control),
        .result      (result),
        .zero        (zero)
    );

    task automatic run_test (
        input logic [3:0]  test_operation,
        input logic [31:0] test_a,
        input logic [31:0] test_b,
        input logic [31:0] expected_result,
        input logic        expected_zero,
        input string       test_name
    );
        begin
            alu_control = test_operation;
            a           = test_a;
            b           = test_b;

            #1;

            if ((result !== expected_result) || (zero !== expected_zero)) begin
                $display(
                    "[FAIL] %s | a=%h b=%h result=%h expected=%h zero=%b expected_zero=%b",
                    test_name,
                    a,
                    b,
                    result,
                    expected_result,
                    zero,
                    expected_zero
                );

                failures = failures + 1;
            end
            else begin
                $display(
                    "[PASS] %s | result=%h zero=%b",
                    test_name,
                    result,
                    zero
                );
            end
        end
    endtask

    initial begin
        failures = 0;
        a = 32'b0;
        b = 32'b0;
        alu_control = ALU_ADD;

        run_test(ALU_ADD,  32'd10,        32'd20,        32'd30,        1'b0, "ADD");
        run_test(ALU_SUB,  32'd20,        32'd7,         32'd13,        1'b0, "SUB");
        run_test(ALU_SUB,  32'd5,         32'd5,         32'd0,         1'b1, "SUB zero");
        run_test(ALU_AND,  32'hF0F0_AA55, 32'h0FF0_0F0F, 32'h00F0_0A05, 1'b0, "AND");
        run_test(ALU_OR,   32'hF000_0000, 32'h0000_00FF, 32'hF000_00FF, 1'b0, "OR");
        run_test(ALU_XOR,  32'hAAAA_AAAA, 32'hFFFF_0000, 32'h5555_AAAA, 1'b0, "XOR");
        run_test(ALU_SLL,  32'h0000_0001, 32'd4,         32'h0000_0010, 1'b0, "SLL");
        run_test(ALU_SRL,  32'h8000_0000, 32'd4,         32'h0800_0000, 1'b0, "SRL");
        run_test(ALU_SRA,  32'hF000_0000, 32'd4,         32'hFF00_0000, 1'b0, "SRA");
        run_test(ALU_SLT,  32'hFFFF_FFFF, 32'd1,         32'd1,         1'b0, "SLT signed");
        run_test(ALU_SLTU, 32'hFFFF_FFFF, 32'd1,         32'd0,         1'b1, "SLTU unsigned");

        if (failures == 0) begin
            $display("");
            $display("================================");
            $display("ALL ALU TESTS PASSED");
            $display("================================");
            $finish;
        end
        else begin
            $fatal(1, "%0d ALU test(s) failed", failures);
        end
    end

endmodule
