`timescale 1ns/1ps

module control_unit (
    input  logic [31:0] instruction,

    // Decoded instruction fields
    output logic [6:0]  opcode,
    output logic [2:0]  funct3,
    output logic [4:0]  rs1_addr,
    output logic [4:0]  rs2_addr,
    output logic [4:0]  rd_addr,

    // ALU controls
    output logic [3:0]  alu_control,
    output logic        alu_src_imm,
    output logic        alu_src_pc,

    // Register-file and memory controls
    output logic        reg_write,
    output logic        mem_read,
    output logic        mem_write,
    output logic [1:0]  wb_select,

    // Control-flow signals
    output logic        branch,
    output logic        jump,
    output logic        jump_reg,

    // Indicates an unsupported or invalid encoding
    output logic        illegal_instruction
);

    logic [6:0] funct7;

    /*
     * Instruction fields always occupy the same positions.
     *
     * Some instruction formats do not use every field, but it is
     * safe to extract them unconditionally.
     */
    assign opcode   = instruction[6:0];
    assign rd_addr  = instruction[11:7];
    assign funct3   = instruction[14:12];
    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];
    assign funct7   = instruction[31:25];

    // Opcodes
    localparam logic [6:0] OPCODE_LOAD   = 7'b0000011;
    localparam logic [6:0] OPCODE_OP_IMM = 7'b0010011;
    localparam logic [6:0] OPCODE_AUIPC  = 7'b0010111;
    localparam logic [6:0] OPCODE_STORE  = 7'b0100011;
    localparam logic [6:0] OPCODE_OP     = 7'b0110011;
    localparam logic [6:0] OPCODE_LUI    = 7'b0110111;
    localparam logic [6:0] OPCODE_BRANCH = 7'b1100011;
    localparam logic [6:0] OPCODE_JALR   = 7'b1100111;
    localparam logic [6:0] OPCODE_JAL    = 7'b1101111;

    // ALU control values; these match rtl/core/alu.sv.
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

    // Register writeback-source selection.
    localparam logic [1:0] WB_ALU       = 2'b00;
    localparam logic [1:0] WB_MEMORY    = 2'b01;
    localparam logic [1:0] WB_PC_PLUS_4 = 2'b10;
    localparam logic [1:0] WB_IMMEDIATE = 2'b11;

    always_comb begin
        /*
         * Safe defaults:
         *
         * No register writes, no memory writes, and no control-flow
         * changes occur unless the instruction is recognized.
         */
        alu_control        = ALU_ADD;
        alu_src_imm        = 1'b0;
        alu_src_pc         = 1'b0;

        reg_write          = 1'b0;
        mem_read           = 1'b0;
        mem_write          = 1'b0;
        wb_select          = WB_ALU;

        branch             = 1'b0;
        jump               = 1'b0;
        jump_reg           = 1'b0;

        illegal_instruction = 1'b1;

        case (opcode)

            /*
             * R-type register-register ALU instructions.
             */
            OPCODE_OP: begin
                case (funct3)

                    // ADD and SUB
                    3'b000: begin
                        case (funct7)
                            7'b0000000: begin
                                alu_control         = ALU_ADD;
                                reg_write           = 1'b1;
                                wb_select           = WB_ALU;
                                illegal_instruction = 1'b0;
                            end

                            7'b0100000: begin
                                alu_control         = ALU_SUB;
                                reg_write           = 1'b1;
                                wb_select           = WB_ALU;
                                illegal_instruction = 1'b0;
                            end

                            default: begin
                                // Keep safe defaults.
                            end
                        endcase
                    end

                    // SLL
                    3'b001: begin
                        if (funct7 == 7'b0000000) begin
                            alu_control         = ALU_SLL;
                            reg_write           = 1'b1;
                            wb_select           = WB_ALU;
                            illegal_instruction = 1'b0;
                        end
                    end

                    // SLT
                    3'b010: begin
                        if (funct7 == 7'b0000000) begin
                            alu_control         = ALU_SLT;
                            reg_write           = 1'b1;
                            wb_select           = WB_ALU;
                            illegal_instruction = 1'b0;
                        end
                    end

                    // SLTU
                    3'b011: begin
                        if (funct7 == 7'b0000000) begin
                            alu_control         = ALU_SLTU;
                            reg_write           = 1'b1;
                            wb_select           = WB_ALU;
                            illegal_instruction = 1'b0;
                        end
                    end

                    // XOR
                    3'b100: begin
                        if (funct7 == 7'b0000000) begin
                            alu_control         = ALU_XOR;
                            reg_write           = 1'b1;
                            wb_select           = WB_ALU;
                            illegal_instruction = 1'b0;
                        end
                    end

                    // SRL and SRA
                    3'b101: begin
                        case (funct7)
                            7'b0000000: begin
                                alu_control         = ALU_SRL;
                                reg_write           = 1'b1;
                                wb_select           = WB_ALU;
                                illegal_instruction = 1'b0;
                            end

                            7'b0100000: begin
                                alu_control         = ALU_SRA;
                                reg_write           = 1'b1;
                                wb_select           = WB_ALU;
                                illegal_instruction = 1'b0;
                            end

                            default: begin
                                // Keep safe defaults.
                            end
                        endcase
                    end

                    // OR
                    3'b110: begin
                        if (funct7 == 7'b0000000) begin
                            alu_control         = ALU_OR;
                            reg_write           = 1'b1;
                            wb_select           = WB_ALU;
                            illegal_instruction = 1'b0;
                        end
                    end

                    // AND
                    3'b111: begin
                        if (funct7 == 7'b0000000) begin
                            alu_control         = ALU_AND;
                            reg_write           = 1'b1;
                            wb_select           = WB_ALU;
                            illegal_instruction = 1'b0;
                        end
                    end

                    default: begin
                        // Keep safe defaults.
                    end
                endcase
            end

            /*
             * I-type immediate ALU instructions.
             */
            OPCODE_OP_IMM: begin
                alu_src_imm = 1'b1;

                case (funct3)

                    // ADDI
                    3'b000: begin
                        alu_control         = ALU_ADD;
                        reg_write           = 1'b1;
                        wb_select           = WB_ALU;
                        illegal_instruction = 1'b0;
                    end

                    // SLLI
                    3'b001: begin
                        if (funct7 == 7'b0000000) begin
                            alu_control         = ALU_SLL;
                            reg_write           = 1'b1;
                            wb_select           = WB_ALU;
                            illegal_instruction = 1'b0;
                        end
                    end

                    // SLTI
                    3'b010: begin
                        alu_control         = ALU_SLT;
                        reg_write           = 1'b1;
                        wb_select           = WB_ALU;
                        illegal_instruction = 1'b0;
                    end

                    // SLTIU
                    3'b011: begin
                        alu_control         = ALU_SLTU;
                        reg_write           = 1'b1;
                        wb_select           = WB_ALU;
                        illegal_instruction = 1'b0;
                    end

                    // XORI
                    3'b100: begin
                        alu_control         = ALU_XOR;
                        reg_write           = 1'b1;
                        wb_select           = WB_ALU;
                        illegal_instruction = 1'b0;
                    end

                    // SRLI and SRAI
                    3'b101: begin
                        case (funct7)
                            7'b0000000: begin
                                alu_control         = ALU_SRL;
                                reg_write           = 1'b1;
                                wb_select           = WB_ALU;
                                illegal_instruction = 1'b0;
                            end

                            7'b0100000: begin
                                alu_control         = ALU_SRA;
                                reg_write           = 1'b1;
                                wb_select           = WB_ALU;
                                illegal_instruction = 1'b0;
                            end

                            default: begin
                                // Keep safe defaults.
                            end
                        endcase
                    end

                    // ORI
                    3'b110: begin
                        alu_control         = ALU_OR;
                        reg_write           = 1'b1;
                        wb_select           = WB_ALU;
                        illegal_instruction = 1'b0;
                    end

                    // ANDI
                    3'b111: begin
                        alu_control         = ALU_AND;
                        reg_write           = 1'b1;
                        wb_select           = WB_ALU;
                        illegal_instruction = 1'b0;
                    end

                    default: begin
                        // Keep safe defaults.
                    end
                endcase
            end

            /*
             * LW: address = rs1 + immediate.
             *
             * We currently support only funct3=010, which is a
             * 32-bit word load.
             */
            OPCODE_LOAD: begin
                if (funct3 == 3'b010) begin
                    alu_control         = ALU_ADD;
                    alu_src_imm         = 1'b1;
                    reg_write           = 1'b1;
                    mem_read            = 1'b1;
                    wb_select           = WB_MEMORY;
                    illegal_instruction = 1'b0;
                end
            end

            /*
             * SW: address = rs1 + immediate.
             *
             * Store data comes from rs2. The instruction does not
             * write a register.
             */
            OPCODE_STORE: begin
                if (funct3 == 3'b010) begin
                    alu_control         = ALU_ADD;
                    alu_src_imm         = 1'b1;
                    mem_write           = 1'b1;
                    illegal_instruction = 1'b0;
                end
            end

            /*
             * Conditional branches.
             *
             * funct3 remains available as an output so a future
             * branch unit can distinguish BEQ, BNE, BLT, etc.
             */
            OPCODE_BRANCH: begin
                case (funct3)
                    // BEQ and BNE use equality comparison.
                    3'b000,
                    3'b001: begin
                        alu_control         = ALU_SUB;
                        branch              = 1'b1;
                        illegal_instruction = 1'b0;
                    end

                    // BLT and BGE use signed comparison.
                    3'b100,
                    3'b101: begin
                        alu_control         = ALU_SLT;
                        branch              = 1'b1;
                        illegal_instruction = 1'b0;
                    end

                    // BLTU and BGEU use unsigned comparison.
                    3'b110,
                    3'b111: begin
                        alu_control         = ALU_SLTU;
                        branch              = 1'b1;
                        illegal_instruction = 1'b0;
                    end

                    default: begin
                        // Unsupported branch encoding.
                    end
                endcase
            end

            /*
             * LUI writes the generated U-type immediate directly
             * into rd.
             */
            OPCODE_LUI: begin
                reg_write           = 1'b1;
                wb_select           = WB_IMMEDIATE;
                illegal_instruction = 1'b0;
            end

            /*
             * AUIPC calculates PC + immediate using the ALU.
             */
            OPCODE_AUIPC: begin
                alu_control         = ALU_ADD;
                alu_src_imm         = 1'b1;
                alu_src_pc          = 1'b1;
                reg_write           = 1'b1;
                wb_select           = WB_ALU;
                illegal_instruction = 1'b0;
            end

            /*
             * JAL jumps to PC + immediate and writes PC + 4 into rd.
             */
            OPCODE_JAL: begin
                alu_control         = ALU_ADD;
                alu_src_imm         = 1'b1;
                alu_src_pc          = 1'b1;
                reg_write           = 1'b1;
                wb_select           = WB_PC_PLUS_4;
                jump                = 1'b1;
                illegal_instruction = 1'b0;
            end

            /*
             * JALR jumps to rs1 + immediate and writes PC + 4 into rd.
             */
            OPCODE_JALR: begin
                if (funct3 == 3'b000) begin
                    alu_control         = ALU_ADD;
                    alu_src_imm         = 1'b1;
                    reg_write           = 1'b1;
                    wb_select           = WB_PC_PLUS_4;
                    jump                = 1'b1;
                    jump_reg            = 1'b1;
                    illegal_instruction = 1'b0;
                end
            end

            default: begin
                // Unsupported opcode: safe defaults remain active.
            end
        endcase
    end

endmodule
