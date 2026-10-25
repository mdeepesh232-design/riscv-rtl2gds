module alu (
    input  [31:0] A,
    input  [31:0] B,
    input  [2:0]  alu_control,
    output reg [31:0] result
);
    always @(*) begin
        case (alu_control)
            3'b000: result = A + B;                                       // ADD
            3'b001: result = A - B;                                       // SUB
            3'b010: result = A & B;                                       // AND
            3'b011: result = A | B;                                       // OR
            3'b100: result = A ^ B;                                       // XOR
            3'b101: result = ($signed(A) < $signed(B)) ? 32'b1 : 32'b0;   // SLT
            3'b110: result = B;                                           // LUI (pass-through)
            default: result = 32'b0;
        endcase
    end
endmodule