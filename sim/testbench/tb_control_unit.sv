`timescale 1ns/1ps

module tb_control_unit;

    logic [31:0] instruction;

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [4:0] rs1_addr;
    logic [4:0] rs2_addr;
    logic [4:0] rd_addr;

    logic [3:0] alu_control;
    logic       alu_src_imm;
    logic       alu_src_pc;

    logic       reg_write;
    logic       mem_read;
    logic       mem_write;
    logic [1:0] wb_select;

    logic       branch;
    logic       jump;
    logic       jump_reg;
    logic       illegal_instruction;

    integer failures;

    localparam logic [6:0] OPCODE_LOAD   = 7'b0000011;
    localparam logic [6:0] OPCODE_OP_IMM = 7'b0010011;
    localparam logic [6:0] OPCODE_AUIPC  = 7'b0010111;
    localparam logic [6:0] OPCODE_STORE  = 7'b0100011;
    localparam logic [6:0] OPCODE_OP     = 7'b0110011;
    localparam logic [6:0] OPCODE_LUI    = 7'b0110111;
    localparam logic [6:0] OPCODE_BRANCH = 7'b1100011;
    localparam logic [6:0] OPCODE_JALR   = 7'b1100111;
    localparam logic [6:0] OPCODE_JAL    = 7'b1101111;

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

    localparam logic [1:0] WB_ALU       = 2'b00;
    localparam logic [1:0] WB_MEMORY    = 2'b01;
    localparam logic [1:0] WB_PC_PLUS_4 = 2'b10;
    localparam logic [1:0] WB_IMMEDIATE = 2'b11;

    logic [14:0] actual_controls;
    logic [14:0] expected_controls;

    control_unit dut (
        .instruction         (instruction),

        .opcode              (opcode),
        .funct3              (funct3),
        .rs1_addr            (rs1_addr),
        .rs2_addr            (rs2_addr),
        .rd_addr             (rd_addr),

        .alu_control         (alu_control),
        .alu_src_imm         (alu_src_imm),
        .alu_src_pc          (alu_src_pc),

        .reg_write           (reg_write),
        .mem_read            (mem_read),
        .mem_write           (mem_write),
        .wb_select           (wb_select),

        .branch              (branch),
        .jump                (jump),
        .jump_reg            (jump_reg),

        .illegal_instruction (illegal_instruction)
    );

    /*
     * Pack the control signals into one vector to make comparison
     * concise and self-checking.
     */
    always_comb begin
        actual_controls = {
            illegal_instruction,
            jump_reg,
            jump,
            branch,
            wb_select,
            mem_write,
            mem_read,
            reg_write,
            alu_src_pc,
            alu_src_imm,
            alu_control
        };
    end

    function automatic logic [31:0] encode_r (
        input logic [6:0] funct7_value,
        input logic [4:0] rs2_value,
        input logic [4:0] rs1_value,
        input logic [2:0] funct3_value,
        input logic [4:0] rd_value,
        input logic [6:0] opcode_value
    );
        encode_r = {
            funct7_value,
            rs2_value,
            rs1_value,
            funct3_value,
            rd_value,
            opcode_value
        };
    endfunction

    function automatic logic [31:0] encode_i (
        input logic [11:0] immediate_value,
        input logic [4:0]  rs1_value,
        input logic [2:0]  funct3_value,
        input logic [4:0]  rd_value,
        input logic [6:0]  opcode_value
    );
        encode_i = {
            immediate_value,
            rs1_value,
            funct3_value,
            rd_value,
            opcode_value
        };
    endfunction

    function automatic logic [31:0] encode_s (
        input logic [11:0] immediate_value,
        input logic [4:0]  rs2_value,
        input logic [4:0]  rs1_value,
        input logic [2:0]  funct3_value,
        input logic [6:0]  opcode_value
    );
        encode_s = {
            immediate_value[11:5],
            rs2_value,
            rs1_value,
            funct3_value,
            immediate_value[4:0],
            opcode_value
        };
    endfunction

    function automatic logic [31:0] encode_b (
        input logic [12:0] immediate_value,
        input logic [4:0]  rs2_value,
        input logic [4:0]  rs1_value,
        input logic [2:0]  funct3_value,
        input logic [6:0]  opcode_value
    );
        encode_b = {
            immediate_value[12],
            immediate_value[10:5],
            rs2_value,
            rs1_value,
            funct3_value,
            immediate_value[4:1],
            immediate_value[11],
            opcode_value
        };
    endfunction

    function automatic logic [31:0] encode_u (
        input logic [19:0] immediate_value,
        input logic [4:0]  rd_value,
        input logic [6:0]  opcode_value
    );
        encode_u = {
            immediate_value,
            rd_value,
            opcode_value
        };
    endfunction

    function automatic logic [31:0] encode_j (
        input logic [20:0] immediate_value,
        input logic [4:0]  rd_value,
        input logic [6:0]  opcode_value
    );
        encode_j = {
            immediate_value[20],
            immediate_value[10:1],
            immediate_value[11],
            immediate_value[19:12],
            rd_value,
            opcode_value
        };
    endfunction

    task automatic run_control_test (
        input logic [31:0] test_instruction,

        input logic [3:0] expected_alu_control,
        input logic       expected_alu_src_imm,
        input logic       expected_alu_src_pc,

        input logic       expected_reg_write,
        input logic       expected_mem_read,
        input logic       expected_mem_write,
        input logic [1:0] expected_wb_select,

        input logic       expected_branch,
        input logic       expected_jump,
        input logic       expected_jump_reg,
        input logic       expected_illegal,

        input string      test_name
    );
        begin
            instruction = test_instruction;

            expected_controls = {
                expected_illegal,
                expected_jump_reg,
                expected_jump,
                expected_branch,
                expected_wb_select,
                expected_mem_write,
                expected_mem_read,
                expected_reg_write,
                expected_alu_src_pc,
                expected_alu_src_imm,
                expected_alu_control
            };

            #1;

            if (actual_controls !== expected_controls) begin
                $display("[FAIL] %s", test_name);
                $display("  instruction = %h", instruction);
                $display("  actual      = %b", actual_controls);
                $display("  expected    = %b", expected_controls);
                $display(
                    "  ALU=%b imm=%b pc=%b regW=%b memR=%b memW=%b wb=%b branch=%b jump=%b jumpReg=%b illegal=%b",
                    alu_control,
                    alu_src_imm,
                    alu_src_pc,
                    reg_write,
                    mem_read,
                    mem_write,
                    wb_select,
                    branch,
                    jump,
                    jump_reg,
                    illegal_instruction
                );

                failures = failures + 1;
            end
            else begin
                $display(
                    "[PASS] %s | ALU=%b regW=%b memR=%b memW=%b branch=%b jump=%b illegal=%b",
                    test_name,
                    alu_control,
                    reg_write,
                    mem_read,
                    mem_write,
                    branch,
                    jump,
                    illegal_instruction
                );
            end
        end
    endtask

    initial begin
        failures = 0;
        instruction = 32'b0;
        expected_controls = 15'b0;

        /*
         * Check direct extraction of rs1, rs2, and rd.
         */
        instruction = encode_r(
            7'b0000000,
            5'd2,
            5'd1,
            3'b000,
            5'd5,
            OPCODE_OP
        );

        #1;

        if (
            (rs1_addr !== 5'd1) ||
            (rs2_addr !== 5'd2) ||
            (rd_addr  !== 5'd5)
        ) begin
            $display(
                "[FAIL] Register field extraction | rs1=%0d rs2=%0d rd=%0d",
                rs1_addr,
                rs2_addr,
                rd_addr
            );

            failures = failures + 1;
        end
        else begin
            $display(
                "[PASS] Register field extraction | rs1=x%0d rs2=x%0d rd=x%0d",
                rs1_addr,
                rs2_addr,
                rd_addr
            );
        end

        // ADD
        run_control_test(
            encode_r(
                7'b0000000,
                5'd2,
                5'd1,
                3'b000,
                5'd5,
                OPCODE_OP
            ),
            ALU_ADD,
            1'b0,
            1'b0,
            1'b1,
            1'b0,
            1'b0,
            WB_ALU,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            "ADD"
        );

        // SUB
        run_control_test(
            encode_r(
                7'b0100000,
                5'd2,
                5'd1,
                3'b000,
                5'd5,
                OPCODE_OP
            ),
            ALU_SUB,
            1'b0,
            1'b0,
            1'b1,
            1'b0,
            1'b0,
            WB_ALU,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            "SUB"
        );

        // SRA
        run_control_test(
            encode_r(
                7'b0100000,
                5'd2,
                5'd1,
                3'b101,
                5'd5,
                OPCODE_OP
            ),
            ALU_SRA,
            1'b0,
            1'b0,
            1'b1,
            1'b0,
            1'b0,
            WB_ALU,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            "SRA"
        );

        // SLTU
        run_control_test(
            encode_r(
                7'b0000000,
                5'd2,
                5'd1,
                3'b011,
                5'd5,
                OPCODE_OP
            ),
            ALU_SLTU,
            1'b0,
            1'b0,
            1'b1,
            1'b0,
            1'b0,
            WB_ALU,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            "SLTU"
        );

        // ADDI
        run_control_test(
            encode_i(
                12'd10,
                5'd1,
                3'b000,
                5'd5,
                OPCODE_OP_IMM
            ),
            ALU_ADD,
            1'b1,
            1'b0,
            1'b1,
            1'b0,
            1'b0,
            WB_ALU,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            "ADDI"
        );

        // ANDI
        run_control_test(
            encode_i(
                12'h0FF,
                5'd1,
                3'b111,
                5'd5,
                OPCODE_OP_IMM
            ),
            ALU_AND,
            1'b1,
            1'b0,
            1'b1,
            1'b0,
            1'b0,
            WB_ALU,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            "ANDI"
        );

        // SRAI with shift amount 4.
        run_control_test(
            encode_i(
                {7'b0100000, 5'd4},
                5'd1,
                3'b101,
                5'd5,
                OPCODE_OP_IMM
            ),
            ALU_SRA,
            1'b1,
            1'b0,
            1'b1,
            1'b0,
            1'b0,
            WB_ALU,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            "SRAI"
        );

        // LW
        run_control_test(
            encode_i(
                12'd8,
                5'd1,
                3'b010,
                5'd5,
                OPCODE_LOAD
            ),
            ALU_ADD,
            1'b1,
            1'b0,
            1'b1,
            1'b1,
            1'b0,
            WB_MEMORY,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            "LW"
        );

        // SW
        run_control_test(
            encode_s(
                12'd12,
                5'd5,
                5'd1,
                3'b010,
                OPCODE_STORE
            ),
            ALU_ADD,
            1'b1,
            1'b0,
            1'b0,
            1'b0,
            1'b1,
            WB_ALU,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            "SW"
        );

        // BEQ
        run_control_test(
            encode_b(
                13'd16,
                5'd2,
                5'd1,
                3'b000,
                OPCODE_BRANCH
            ),
            ALU_SUB,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            WB_ALU,
            1'b1,
            1'b0,
            1'b0,
            1'b0,
            "BEQ"
        );

        // BLTU
        run_control_test(
            encode_b(
                13'd16,
                5'd2,
                5'd1,
                3'b110,
                OPCODE_BRANCH
            ),
            ALU_SLTU,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            WB_ALU,
            1'b1,
            1'b0,
            1'b0,
            1'b0,
            "BLTU"
        );

        // LUI
        run_control_test(
            encode_u(
                20'h12345,
                5'd5,
                OPCODE_LUI
            ),
            ALU_ADD,
            1'b0,
            1'b0,
            1'b1,
            1'b0,
            1'b0,
            WB_IMMEDIATE,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            "LUI"
        );

        // AUIPC
        run_control_test(
            encode_u(
                20'h12345,
                5'd5,
                OPCODE_AUIPC
            ),
            ALU_ADD,
            1'b1,
            1'b1,
            1'b1,
            1'b0,
            1'b0,
            WB_ALU,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            "AUIPC"
        );

        // JAL
        run_control_test(
            encode_j(
                21'd32,
                5'd1,
                OPCODE_JAL
            ),
            ALU_ADD,
            1'b1,
            1'b1,
            1'b1,
            1'b0,
            1'b0,
            WB_PC_PLUS_4,
            1'b0,
            1'b1,
            1'b0,
            1'b0,
            "JAL"
        );

        // JALR
        run_control_test(
            encode_i(
                12'd4,
                5'd5,
                3'b000,
                5'd1,
                OPCODE_JALR
            ),
            ALU_ADD,
            1'b1,
            1'b0,
            1'b1,
            1'b0,
            1'b0,
            WB_PC_PLUS_4,
            1'b0,
            1'b1,
            1'b1,
            1'b0,
            "JALR"
        );

        /*
         * Invalid R-type funct7. It must not enable any write.
         */
        run_control_test(
            encode_r(
                7'b1111111,
                5'd2,
                5'd1,
                3'b000,
                5'd5,
                OPCODE_OP
            ),
            ALU_ADD,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            WB_ALU,
            1'b0,
            1'b0,
            1'b0,
            1'b1,
            "Invalid R-type funct7"
        );

        /*
         * Completely unsupported opcode.
         */
        run_control_test(
            32'hFFFF_FFFF,
            ALU_ADD,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            WB_ALU,
            1'b0,
            1'b0,
            1'b0,
            1'b1,
            "Unsupported opcode"
        );

        if (failures == 0) begin
            $display("");
            $display("========================================");
            $display("ALL CONTROL UNIT TESTS PASSED");
            $display("========================================");
            $finish;
        end
        else begin
            $fatal(
                1,
                "%0d control-unit test(s) failed",
                failures
            );
        end
    end

endmodule
