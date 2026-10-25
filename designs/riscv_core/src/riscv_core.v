module riscv_core (
    input         clk,
    input         reset,

    // Instruction memory interface
    output [31:0] imem_addr,
    input  [31:0] imem_data,

    // Data memory interface
    output [31:0] dmem_addr,
    output [31:0] dmem_wdata,
    output        dmem_read,
    output        dmem_write,
    input  [31:0] dmem_rdata,

    // Debug / observability
    output [31:0] debug_pc,
    output [31:0] debug_instruction,
    output [31:0] debug_alu_result,
    output [31:0] debug_write_data
);
    // PC signals
    wire [31:0] pc;
    wire [31:0] pc_plus4;
    wire [31:0] pc_target;
    wire        branch_taken;

    // Immediate (declared before use)
    wire [31:0] immediate;

    assign pc_plus4  = pc + 32'd4;
    assign pc_target = pc + immediate;

    // Instruction
    wire [31:0] instruction;
    assign instruction = imem_data;
    assign imem_addr   = pc;

    // Decode
    wire [6:0] opcode;
    wire [4:0] rd, rs1, rs2;
    wire [2:0] funct3;
    wire [6:0] funct7;

    // Control signals
    wire       reg_write, mem_read, mem_write, alu_src, branch, jump;
    wire [2:0] alu_control;
    wire [1:0] result_src;

    // Register file
    wire [31:0] read_data1, read_data2;
    wire [31:0] write_data;

    // ALU
    wire [31:0] alu_result;
    wire [31:0] alu_operand_b;
    wire        zero;

    // Data memory read data
    wire [31:0] mem_read_data;

    // ---------------- Module instantiations ----------------

    prog_count u_pc (
        .clk(clk),
        .reset(reset),
        .branch_taken(branch_taken),
        .jump(jump),
        .target_address(pc_target),
        .pc(pc)
    );

    instruction_decoder u_decoder (
        .instruction(instruction),
        .opcode(opcode),
        .rd(rd),
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7)
    );

    control_unit u_control (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .branch(branch),
        .jump(jump),
        .alu_control(alu_control),
        .result_src(result_src)
    );

    immediate_gen u_immgen (
        .instruction(instruction),
        .immediate(immediate)
    );

    register_file u_regfile (
        .clk(clk),
        .reset(reset),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(write_data),
        .reg_write(reg_write),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    assign alu_operand_b = alu_src ? immediate : read_data2;

    alu u_alu (
        .A(read_data1),
        .B(alu_operand_b),
        .alu_control(alu_control),
        .result(alu_result)
    );

    assign zero = (alu_result == 32'b0);

    branch_unit u_branch (
        .branch(branch),
        .zero(zero),
        .branch_taken(branch_taken)
    );

    // Data memory interface (memory itself lives outside the core)
    assign dmem_addr     = alu_result;
    assign dmem_wdata    = read_data2;
    assign dmem_read     = mem_read;
    assign dmem_write    = mem_write;
    assign mem_read_data = dmem_rdata;

    // Write-back mux: 00 = ALU result, 01 = memory data, 10 = PC+4
    assign write_data = (result_src == 2'b01) ? mem_read_data :
                        (result_src == 2'b10) ? pc_plus4 :
                                                alu_result;

    // Debug outputs
    assign debug_pc          = pc;
    assign debug_instruction = instruction;
    assign debug_alu_result  = alu_result;
    assign debug_write_data  = write_data;

endmodule
