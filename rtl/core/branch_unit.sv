`timescale 1ns/1ps

module branch_unit (
    input  logic        branch,
    input  logic [2:0]  funct3,
    input  logic [31:0] rs1_data,
    input  logic [31:0] rs2_data,

    output logic        branch_taken
);

    always_comb begin
        branch_taken = 1'b0;

        if (branch) begin
            case (funct3)

                // BEQ
                3'b000: begin
                    branch_taken = (rs1_data == rs2_data);
                end

                // BNE
                3'b001: begin
                    branch_taken = (rs1_data != rs2_data);
                end

                // BLT: signed comparison
                3'b100: begin
                    branch_taken =
                        ($signed(rs1_data) < $signed(rs2_data));
                end

                // BGE: signed comparison
                3'b101: begin
                    branch_taken =
                        ($signed(rs1_data) >= $signed(rs2_data));
                end

                // BLTU: unsigned comparison
                3'b110: begin
                    branch_taken = (rs1_data < rs2_data);
                end

                // BGEU: unsigned comparison
                3'b111: begin
                    branch_taken = (rs1_data >= rs2_data);
                end

                default: begin
                    branch_taken = 1'b0;
                end
            endcase
        end
    end

endmodule
