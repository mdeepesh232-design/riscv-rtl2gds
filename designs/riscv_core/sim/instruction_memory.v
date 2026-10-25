module instruction_memory (
    input  [31:0] address,
    output [31:0] instruction
);
    reg [31:0] memory [0:255];
    assign instruction = memory[address[9:2]];
    initial begin
        // Program will be loaded here during testing.
        // Example:
        // memory[0] = 32'h00A00093;
    end
endmodule
