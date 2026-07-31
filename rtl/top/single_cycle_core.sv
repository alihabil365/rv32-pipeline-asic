`timescale 1ns/1ps

module single_cycle_core #(
    parameter integer IMEM_WORDS = 256,
    parameter         IMEM_INIT_FILE = "",
    parameter integer IMEM_INIT_WORDS = 0,

    parameter integer DMEM_WORDS = 256,

    parameter logic [31:0] RESET_VECTOR = 32'h0000_0000
) (
    input logic clk,
    input logic reset_n,

    output logic [31:0] debug_pc,
    output logic [31:0] debug_instruction,
    output logic [31:0] debug_alu_result,
    output logic [6:0]  debug_opcode,
    output logic        debug_alu_zero,
    output logic        debug_illegal_instruction
);

    logic [31:0] current_pc;
    logic [31:0] next_pc;
    logic [31:0] pc_plus_4;

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

    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] immediate;

    logic [31:0] alu_operand_a;
    logic [31:0] alu_operand_b;
    logic [31:0] alu_result;
    logic        alu_zero;

    logic        branch_taken;

    logic [31:0] branch_target;
    logic [31:0] jump_reg_target;

    logic [31:0] memory_read_data;
    logic [31:0] writeback_data;

    logic reg_write_enabled;
    logic mem_write_enabled;

    localparam logic [1:0] WB_ALU       = 2'b00;
    localparam logic [1:0] WB_MEMORY    = 2'b01;
    localparam logic [1:0] WB_PC_PLUS_4 = 2'b10;
    localparam logic [1:0] WB_IMMEDIATE = 2'b11;

    /*
     * Prevent state changes while reset is active.
     */
    assign reg_write_enabled =
        reg_write && reset_n;

    assign mem_write_enabled =
        mem_write && reset_n;

    /*
     * Program counter.
     */
    program_counter #(
        .RESET_VECTOR(RESET_VECTOR)
    ) program_counter_inst (
        .clk             (clk),
        .reset_n         (reset_n),
        .pc_write_enable (1'b1),
        .next_pc         (next_pc),
        .current_pc      (current_pc)
    );

    /*
     * Program memory.
     */
    instruction_memory #(
        .WORDS      (IMEM_WORDS),
        .INIT_FILE  (IMEM_INIT_FILE),
        .INIT_WORDS (IMEM_INIT_WORDS)
    ) instruction_memory_inst (
        .address     (current_pc),
        .instruction (instruction)
    );

    /*
     * Decode the current instruction.
     */
    control_unit control_unit_inst (
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
     * CPU integer registers.
     */
    register_file register_file_inst (
        .clk          (clk),

        .write_enable (reg_write_enabled),
        .write_addr   (rd_addr),
        .write_data   (writeback_data),

        .read_addr_a  (rs1_addr),
        .read_addr_b  (rs2_addr),
        .read_data_a  (rs1_data),
        .read_data_b  (rs2_data)
    );

    /*
     * Decode and extend the instruction immediate.
     */
    immediate_generator immediate_generator_inst (
        .instruction (instruction),
        .immediate   (immediate)
    );

    /*
     * Select ALU operands.
     */
    assign alu_operand_a =
        alu_src_pc ? current_pc : rs1_data;

    assign alu_operand_b =
        alu_src_imm ? immediate : rs2_data;

    /*
     * Execute arithmetic, address calculations, and comparisons.
     */
    alu alu_inst (
        .a           (alu_operand_a),
        .b           (alu_operand_b),
        .alu_control (alu_control),
        .result      (alu_result),
        .zero        (alu_zero)
    );

    /*
     * Conditional branch decision.
     */
    branch_unit branch_unit_inst (
        .branch       (branch),
        .funct3       (funct3),
        .rs1_data     (rs1_data),
        .rs2_data     (rs2_data),
        .branch_taken (branch_taken)
    );

    /*
     * Data memory.
     */
    data_memory #(
        .WORDS(DMEM_WORDS)
    ) data_memory_inst (
        .clk        (clk),
        .mem_read   (mem_read),
        .mem_write  (mem_write_enabled),
        .address    (alu_result),
        .write_data (rs2_data),
        .read_data  (memory_read_data)
    );

    /*
     * Register writeback selection.
     */
    always_comb begin
        case (wb_select)
            WB_ALU: begin
                writeback_data = alu_result;
            end

            WB_MEMORY: begin
                writeback_data = memory_read_data;
            end

            WB_PC_PLUS_4: begin
                writeback_data = pc_plus_4;
            end

            WB_IMMEDIATE: begin
                writeback_data = immediate;
            end

            default: begin
                writeback_data = 32'b0;
            end
        endcase
    end

    /*
     * Next-PC calculation.
     */
    assign pc_plus_4 =
        current_pc + 32'd4;

    assign branch_target =
        current_pc + immediate;

    /*
     * JALR requires bit zero of the target to be cleared.
     */
    assign jump_reg_target =
        alu_result & 32'hFFFF_FFFE;

    always_comb begin
        next_pc = pc_plus_4;

        if (jump) begin
            if (jump_reg) begin
                next_pc = jump_reg_target;
            end
            else begin
                next_pc = branch_target;
            end
        end
        else if (branch && branch_taken) begin
            next_pc = branch_target;
        end
    end

    /*
     * Debug outputs for simulation.
     */
    assign debug_pc                  = current_pc;
    assign debug_instruction         = instruction;
    assign debug_alu_result          = alu_result;
    assign debug_opcode              = opcode;
    assign debug_alu_zero            = alu_zero;
    assign debug_illegal_instruction = illegal_instruction;

endmodule
