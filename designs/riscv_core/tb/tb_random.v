`timescale 1ns / 1ps
`ifndef NUM_INSTR
`define NUM_INSTR 100
`endif
`define SB_FINAL_TIME (12 + 10*`NUM_INSTR + 40)

module tb_random;

    reg clk;
    reg reset;
    wire [31:0] debug_pc;
    wire [31:0] debug_instruction;
    wire [31:0] debug_alu_result;
    wire [31:0] debug_write_data;

    integer g_seed, g_i;

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

    `include "scoreboard.vh"

    function [31:0] rnd(input [31:0] n);
        begin
            rnd = {$random(g_seed)} % n;
        end
    endfunction

    // Build a random program: only instructions your core supports.
    // lw/sw use x0 as base with word offsets 0..60 (safe addresses).
    // beq/jal only jump forward 8-16 bytes (no loops).
    task gen_program;
        integer idx, sel;
        reg [31:0] w;
        reg [4:0]  rd, rs1, rs2;
        reg [11:0] imm12;
        reg [19:0] imm20;
        reg [12:0] off;
        reg [20:0] offj;
        reg [2:0]  f3;
        reg [6:0]  f7;
        begin
            for (idx = 0; idx < `NUM_INSTR; idx = idx + 1) begin
                rd  = rnd(16);
                rs1 = rnd(16);
                rs2 = rnd(16);
                imm12 = rnd(4096);
                imm20 = rnd(1048576);
                sel = rnd(100);
                if (idx < 8) sel = (idx % 2 == 0) ? 40 : 57;  // start with addi/lui

                if (sel < 35) begin                           // R-type
                    case (rnd(6))
                        0: begin f3 = 3'b000; f7 = 7'b0000000; end // add
                        1: begin f3 = 3'b000; f7 = 7'b0100000; end // sub
                        2: begin f3 = 3'b111; f7 = 7'b0000000; end // and
                        3: begin f3 = 3'b110; f7 = 7'b0000000; end // or
                        4: begin f3 = 3'b100; f7 = 7'b0000000; end // xor
                        default: begin f3 = 3'b010; f7 = 7'b0000000; end // slt
                    endcase
                    w = {f7, rs2, rs1, f3, rd, 7'b0110011};
                end else if (sel < 55) begin                  // addi
                    w = {imm12, rs1, 3'b000, rd, 7'b0010011};
                end else if (sel < 60) begin                  // lui
                    w = {imm20, rd, 7'b0110111};
                end else if (sel < 70) begin                  // lw x, k(x0)
                    imm12 = rnd(16) * 4;
                    w = {imm12, 5'd0, 3'b010, rd, 7'b0000011};
                end else if (sel < 80) begin                  // sw x, k(x0)
                    imm12 = rnd(16) * 4;
                    w = {imm12[11:5], rs2, 5'd0, 3'b010, imm12[4:0], 7'b0100011};
                end else if (sel < 90) begin                  // beq forward
                    if (rnd(2) == 0) rs2 = rs1;               // half are always taken
                    off = (rnd(3) + 2) * 4;
                    w = {off[12], off[10:5], rs2, rs1, 3'b000, off[4:1], off[11], 7'b1100011};
                end else begin                                // jal forward
                    offj = (rnd(3) + 2) * 4;
                    w = {offj[20], offj[10:1], offj[11], offj[19:12], rd, 7'b1101111};
                end

                u_dut.u_imem.memory[idx] = w;
            end
        end
    endtask

    initial begin
        if (!$value$plusargs("seed=%d", g_seed)) g_seed = 1;
        $display("RANDOM TEST seed=%0d, %0d instructions", g_seed, `NUM_INSTR);
        for (g_i = 0; g_i < 16; g_i = g_i + 1) u_dut.u_dmem.memory[g_i] = 32'b0;
        reset = 0;
        gen_program;
        #12;
        reset = 1;
        #(`SB_FINAL_TIME + 10);
        $finish;
    end

endmodule
