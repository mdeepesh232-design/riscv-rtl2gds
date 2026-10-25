module control_unit (
    input  [6:0] opcode,
    input  [2:0] funct3,
    input  [6:0] funct7,
    output reg       reg_write,
    output reg       mem_read,
    output reg       mem_write,
    output reg       alu_src,
    output reg       branch,
    output reg       jump,
    output reg [2:0] alu_control,
    output reg [1:0] result_src   // 00: ALU result, 01: mem data, 10: PC+4
);
    always @(*) begin
        reg_write   = 1'b0;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        alu_src     = 1'b0;
        branch      = 1'b0;
        jump        = 1'b0;
        alu_control = 3'b000;
        result_src  = 2'b00;

        case (opcode)
            // R-type
            7'b0110011: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;
                case (funct3)
                    3'b000: alu_control = (funct7 == 7'b0100000) ? 3'b001 : 3'b000; // SUB : ADD
                    3'b111: alu_control = 3'b010; // AND
                    3'b110: alu_control = 3'b011; // OR
                    3'b100: alu_control = 3'b100; // XOR
                    3'b010: alu_control = 3'b101; // SLT
                    default: alu_control = 3'b000;
                endcase
            end

            // ADDI
            7'b0010011: begin
                reg_write   = 1'b1;
                alu_src     = 1'b1;
                alu_control = 3'b000;
            end

            // LW
            7'b0000011: begin
                reg_write   = 1'b1;
                mem_read    = 1'b1;
                alu_src     = 1'b1;
                alu_control = 3'b000;
                result_src  = 2'b01;
            end

            // SW
            7'b0100011: begin
                mem_write   = 1'b1;
                alu_src     = 1'b1;
                alu_control = 3'b000;
            end

            // BEQ
            7'b1100011: begin
                branch      = 1'b1;
                alu_control = 3'b001; // A - B, compare via zero flag
            end

            // JAL
            7'b1101111: begin
                reg_write  = 1'b1;
                jump       = 1'b1;
                result_src = 2'b10; // PC+4
            end

            // LUI
            7'b0110111: begin
                reg_write   = 1'b1;
                alu_src     = 1'b1;
                alu_control = 3'b110; // pass B through (immediate)
            end

            default: begin
            end
        endcase
    end
endmodule