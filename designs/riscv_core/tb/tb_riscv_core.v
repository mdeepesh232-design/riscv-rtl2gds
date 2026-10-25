`timescale 1ns / 1ps

module tb_riscv_core;

    reg clk;
    reg reset;
    wire [31:0] debug_pc;
    wire [31:0] debug_instruction;
    wire [31:0] debug_alu_result;
    wire [31:0] debug_write_data;

    integer errors;
    integer checks;
`include "scoreboard.vh"

    riscv_top u_dut (
        .clk(clk),
        .reset(reset),
        .debug_pc(debug_pc),
        .debug_instruction(debug_instruction),
        .debug_alu_result(debug_alu_result),
        .debug_write_data(debug_write_data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task check(input [8*16-1:0] name,
               input [31:0] actual,
               input [31:0] expected);
        begin
            checks = checks + 1;
            if (actual === expected)
                $display("PASS  %0s = %0d", name, actual);
            else begin
                $display("FAIL  %0s = %0d (expected %0d)", name, actual, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        checks = 0;
        reset  = 0;

        // ---- Program 1 (original) ----
        u_dut.u_imem.memory[0]  = 32'h00500093; // addi x1, x0, 5
        u_dut.u_imem.memory[1]  = 32'h00A00113; // addi x2, x0, 10
        u_dut.u_imem.memory[2]  = 32'h002081B3; // add  x3, x1, x2
        u_dut.u_imem.memory[3]  = 32'h40110233; // sub  x4, x2, x1
        u_dut.u_imem.memory[4]  = 32'h00302023; // sw   x3, 0(x0)
        u_dut.u_imem.memory[5]  = 32'h00002283; // lw   x5, 0(x0)
        u_dut.u_imem.memory[6]  = 32'h00108463; // beq  x1, x1, 8
        u_dut.u_imem.memory[7]  = 32'h06300313; // addi x6, x0, 99 (skipped)
        u_dut.u_imem.memory[8]  = 32'h02A00393; // addi x7, x0, 42

        // ---- Program 2 (new coverage) ----
        u_dut.u_imem.memory[9]  = 32'hFFF00413; // addi x8, x0, -1
        u_dut.u_imem.memory[10] = 32'h0033F4B3; // and  x9,  x7, x3
        u_dut.u_imem.memory[11] = 32'h0033E533; // or   x10, x7, x3
        u_dut.u_imem.memory[12] = 32'h0033C5B3; // xor  x11, x7, x3
        u_dut.u_imem.memory[13] = 32'h00142633; // slt  x12, x8, x1  (-1 < 5)
        u_dut.u_imem.memory[14] = 32'h0080A6B3; // slt  x13, x1, x8  (5 < -1)
        u_dut.u_imem.memory[15] = 32'h00500013; // addi x0, x0, 5    (must be ignored)
        u_dut.u_imem.memory[16] = 32'h00300713; // addi x14, x0, 3
        u_dut.u_imem.memory[17] = 32'h00208463; // beq  x1, x2, 8    (not taken)
        u_dut.u_imem.memory[18] = 32'h04D00793; // addi x15, x0, 77  (must run)
        u_dut.u_imem.memory[19] = 32'h05800813; // addi x16, x0, 88
        u_dut.u_imem.memory[20] = 32'h008008EF; // jal  x17, 8       (PC=80, link=84)
        u_dut.u_imem.memory[21] = 32'h06300913; // addi x18, x0, 99  (skipped)
        u_dut.u_imem.memory[22] = 32'h04200993; // addi x19, x0, 66
        u_dut.u_imem.memory[23] = 32'h00001A37; // lui  x20, 1

        #12;
        reset = 1;

        #260;

        $display("---- Self-checking results ----");
        check("x0 (always 0)",    u_dut.u_core.u_regfile.registers[0],  0);
        check("x1 addi",          u_dut.u_core.u_regfile.registers[1],  5);
        check("x2 addi",          u_dut.u_core.u_regfile.registers[2],  10);
        check("x3 add",           u_dut.u_core.u_regfile.registers[3],  15);
        check("x4 sub",           u_dut.u_core.u_regfile.registers[4],  5);
        check("x5 lw",            u_dut.u_core.u_regfile.registers[5],  15);
        check("x6 beq skip",      u_dut.u_core.u_regfile.registers[6],  0);
        check("x7 after beq",     u_dut.u_core.u_regfile.registers[7],  42);
        check("mem[0] sw",        u_dut.u_dmem.memory[0],               15);
        check("x8 addi -1",       u_dut.u_core.u_regfile.registers[8],  32'hFFFFFFFF);
        check("x9 and",           u_dut.u_core.u_regfile.registers[9],  10);
        check("x10 or",           u_dut.u_core.u_regfile.registers[10], 47);
        check("x11 xor",          u_dut.u_core.u_regfile.registers[11], 37);
        check("x12 slt -1<5",     u_dut.u_core.u_regfile.registers[12], 1);
        check("x13 slt 5<-1",     u_dut.u_core.u_regfile.registers[13], 0);
        check("x14 after x0 wr",  u_dut.u_core.u_regfile.registers[14], 3);
        check("x15 beq nottaken", u_dut.u_core.u_regfile.registers[15], 77);
        check("x16 landing",      u_dut.u_core.u_regfile.registers[16], 88);
        check("x17 jal link",     u_dut.u_core.u_regfile.registers[17], 84);
        check("x18 jal skip",     u_dut.u_core.u_regfile.registers[18], 0);
        check("x19 after jal",    u_dut.u_core.u_regfile.registers[19], 66);
        check("x20 lui",          u_dut.u_core.u_regfile.registers[20], 4096);

        $display("--------------------------------");
        if (errors == 0)
            $display("ALL TESTS PASSED (%0d checks)", checks);
        else
            $display("%0d of %0d CHECKS FAILED", errors, checks);

        $finish;
    end

    initial begin
        $dumpfile("riscv_core_tb.vcd");
        $dumpvars(0, tb_riscv_core);
    end

endmodule
