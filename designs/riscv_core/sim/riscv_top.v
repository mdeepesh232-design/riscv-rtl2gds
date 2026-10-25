module riscv_top (
    input         clk,
    input         reset,
    output [31:0] debug_pc,
    output [31:0] debug_instruction,
    output [31:0] debug_alu_result,
    output [31:0] debug_write_data
);
    wire [31:0] imem_addr, imem_data;
    wire [31:0] dmem_addr, dmem_wdata, dmem_rdata;
    wire        dmem_read, dmem_write;

    riscv_core u_core (
        .clk(clk),
        .reset(reset),
        .imem_addr(imem_addr),
        .imem_data(imem_data),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_read(dmem_read),
        .dmem_write(dmem_write),
        .dmem_rdata(dmem_rdata),
        .debug_pc(debug_pc),
        .debug_instruction(debug_instruction),
        .debug_alu_result(debug_alu_result),
        .debug_write_data(debug_write_data)
    );

    instruction_memory u_imem (
        .address(imem_addr),
        .instruction(imem_data)
    );

    data_memory u_dmem (
        .clk(clk),
        .mem_read(dmem_read),
        .mem_write(dmem_write),
        .address(dmem_addr),
        .write_data(dmem_wdata),
        .read_data(dmem_rdata)
    );
endmodule
