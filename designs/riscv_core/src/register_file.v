module register_file (
    input         clk,
    input         reset,
    input  [4:0]  rs1,
    input  [4:0]  rs2,
    input  [4:0]  rd,
    input  [31:0] write_data,
    input         reg_write,
    output [31:0] read_data1,
    output [31:0] read_data2
);
    reg [31:0] registers [0:31];
    integer i;
    assign read_data1 = (rs1 == 5'd0) ? 32'b0 : registers[rs1];
    assign read_data2 = (rs2 == 5'd0) ? 32'b0 : registers[rs2];
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end
        else begin
            if (reg_write && (rd != 5'd0))
                registers[rd] <= write_data;
            registers[0] <= 32'b0;
        end
    end
endmodule
