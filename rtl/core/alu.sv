module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  alu_control,

    output logic [31:0] result,
    output logic        zero
);

    // ALU control values
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

    always_comb begin
        // Safe default prevents unintended latch inference.
        result = 32'b0;

        case (alu_control)
            ALU_ADD: begin
                result = a + b;
            end

            ALU_SUB: begin
                result = a - b;
            end

            ALU_AND: begin
                result = a & b;
            end

            ALU_OR: begin
                result = a | b;
            end

            ALU_XOR: begin
                result = a ^ b;
            end

            ALU_SLL: begin
                result = a << b[4:0];
            end

            ALU_SRL: begin
                result = a >> b[4:0];
            end

            ALU_SRA: begin
                result = $signed(a) >>> b[4:0];
            end

            ALU_SLT: begin
                result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            end

            ALU_SLTU: begin
                result = (a < b) ? 32'd1 : 32'd0;
            end

            default: begin
                result = 32'b0;
            end
        endcase
    end

    // Used later for equality checks and branches.
    assign zero = (result == 32'b0);

endmodule
