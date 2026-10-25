module prog_count (
    input         clk,
    input         reset,
    input         branch_taken,
    input         jump,
    input  [31:0] target_address,
    output reg [31:0] pc
);
    always @(posedge clk or negedge reset) begin
        if (!reset)
            pc <= 32'b0;
        else if (branch_taken || jump)
            pc <= target_address;
        else
            pc <= pc + 32'd4;
    end
endmodule