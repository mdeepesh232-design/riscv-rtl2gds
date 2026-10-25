`ifndef SB_FINAL_TIME
`define SB_FINAL_TIME 268
`endif
// Monitor + reference model + scoreboard (included inside tb_riscv_core)
reg [31:0] m_regs [0:31];
reg [31:0] m_mem  [0:1023];
reg [31:0] m_pc;
reg        sb_done;
integer    sb_checks, sb_errors, sb_cycle, sb_i;

reg [31:0] i_w, imm_i, imm_s, imm_b, imm_j, imm_u;
reg [6:0]  op, f7;
reg [4:0]  rd_w, rs1_w, rs2_w;
reg [2:0]  f3;
reg [31:0] a_w, b_w, res_w, next_pc, exp_maddr, exp_mdata;
reg        exp_rw, exp_mw, sup;

initial begin
    for (sb_i = 0; sb_i < 32;   sb_i = sb_i + 1) m_regs[sb_i] = 32'b0;
    for (sb_i = 0; sb_i < 1024; sb_i = sb_i + 1) m_mem[sb_i]  = 32'b0;
    m_pc = 0; sb_done = 0; sb_checks = 0; sb_errors = 0; sb_cycle = 0;
end

task sb_cmp(input [8*18-1:0] name, input [31:0] actual, input [31:0] expected);
    begin
        sb_checks = sb_checks + 1;
        if (actual !== expected) begin
            sb_errors = sb_errors + 1;
            if (sb_errors <= 10)
                $display("SB MISMATCH cycle %0d pc=%0h %0s: dut=%0h model=%0h",
                         sb_cycle, m_pc, name, actual, expected);
        end
    end
endtask

// Sample 1 ns before every rising edge (edges are at 5, 15, 25 ...)
always @(negedge clk) begin
    #4;
    if (reset === 1'b1 && !sb_done) begin
        sb_cycle = sb_cycle + 1;
        i_w = u_dut.u_imem.memory[m_pc[31:2]];

        if ((^i_w === 1'bx) || i_w === 32'b0) begin
            sb_done = 1;            // end of program
        end else begin
            op = i_w[6:0];   rd_w = i_w[11:7];  f3 = i_w[14:12];
            rs1_w = i_w[19:15]; rs2_w = i_w[24:20]; f7 = i_w[31:25];
            imm_i = {{20{i_w[31]}}, i_w[31:20]};
            imm_s = {{20{i_w[31]}}, i_w[31:25], i_w[11:7]};
            imm_b = {{19{i_w[31]}}, i_w[31], i_w[7], i_w[30:25], i_w[11:8], 1'b0};
            imm_j = {{11{i_w[31]}}, i_w[31], i_w[19:12], i_w[20], i_w[30:21], 1'b0};
            imm_u = {i_w[31:12], 12'b0};
            a_w = m_regs[rs1_w];  b_w = m_regs[rs2_w];

            exp_rw = 0; exp_mw = 0; sup = 1; res_w = 0; next_pc = m_pc + 4;
            exp_maddr = 0; exp_mdata = 0;

            case (op)
                7'b0110011: begin   // R-type
                    exp_rw = 1;
                    case (f3)
                        3'b000: res_w = (f7 == 7'b0100000) ? (a_w - b_w) : (a_w + b_w);
                        3'b111: res_w = a_w & b_w;
                        3'b110: res_w = a_w | b_w;
                        3'b100: res_w = a_w ^ b_w;
                        3'b010: res_w = ($signed(a_w) < $signed(b_w)) ? 32'd1 : 32'd0;
                        default: sup = 0;
                    endcase
                end
                7'b0010011: begin   // ADDI only
                    exp_rw = 1;
                    if (f3 == 3'b000) res_w = a_w + imm_i; else sup = 0;
                end
                7'b0000011: begin   // LW
                    exp_rw = 1;
                    if (f3 == 3'b010) res_w = m_mem[(a_w + imm_i) >> 2]; else sup = 0;
                end
                7'b0100011: begin   // SW
                    exp_mw = 1;
                    exp_maddr = a_w + imm_s;
                    exp_mdata = b_w;
                    if (f3 != 3'b010) sup = 0;
                end
                7'b1100011: begin   // BEQ
                    if (f3 == 3'b000) begin
                        if (a_w == b_w) next_pc = m_pc + imm_b;
                    end else sup = 0;
                end
                7'b1101111: begin   // JAL
                    exp_rw = 1;
                    res_w = m_pc + 4;
                    next_pc = m_pc + imm_j;
                end
                7'b0110111: begin   // LUI
                    exp_rw = 1;
                    res_w = imm_u;
                end
                default: sup = 0;
            endcase

            if (!sup) begin
                $display("SB WARNING cycle %0d: unsupported instruction %h, skipped", sb_cycle, i_w);
                sb_done = 1;
            end else begin
                // ---- scoreboard compares ----
                sb_cmp("pc", debug_pc, m_pc);
                if (exp_rw && rd_w != 0) begin
                    sb_cmp("reg_write en", {31'b0, u_dut.u_core.reg_write}, 32'd1);
                    sb_cmp("rd",           {27'b0, u_dut.u_core.rd},        {27'b0, rd_w});
                    sb_cmp("write data",   debug_write_data,                res_w);
                end else if (!exp_rw) begin
                    sb_cmp("reg_write idle", {31'b0, u_dut.u_core.reg_write}, 32'd0);
                end
                sb_cmp("mem_write en", {31'b0, u_dut.u_core.dmem_write}, {31'b0, exp_mw});
                if (exp_mw) begin
                    sb_cmp("mem addr",  u_dut.u_core.dmem_addr,  exp_maddr);
                    sb_cmp("mem wdata", u_dut.u_core.dmem_wdata, exp_mdata);
                end

                // ---- update the model ----
                if (exp_rw && rd_w != 0) m_regs[rd_w] = res_w;
                if (exp_mw) m_mem[exp_maddr >> 2] = exp_mdata;
                m_pc = next_pc;
            end
        end
    end
end

// Final compare of the whole register file and mem[0], then summary
initial begin
    #(`SB_FINAL_TIME);
    for (sb_i = 1; sb_i < 32; sb_i = sb_i + 1) begin
        sb_checks = sb_checks + 1;
        if (u_dut.u_core.u_regfile.registers[sb_i] !== m_regs[sb_i]) begin
            sb_errors = sb_errors + 1;
            $display("SB FINAL x%0d: dut=%0h model=%0h", sb_i,
                     u_dut.u_core.u_regfile.registers[sb_i], m_regs[sb_i]);
        end
    end
    sb_checks = sb_checks + 1;
    if (u_dut.u_dmem.memory[0] !== m_mem[0]) begin
        sb_errors = sb_errors + 1;
        $display("SB FINAL mem[0]: dut=%0h model=%0h", u_dut.u_dmem.memory[0], m_mem[0]);
    end
    $display("SCOREBOARD: %0d checks, %0d mismatches", sb_checks, sb_errors);
end
