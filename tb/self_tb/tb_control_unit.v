//=============================================================
// Module      : tb_control_unit
// Description : Self-checking testbench for control_unit.v
//               Applies every RV32I opcode class supported in
//               Phase 1 and checks all 8 control outputs against
//               the expected control table.
// Standard    : Synthesizable/simulatable Verilog-2001
//=============================================================
`timescale 1ns/1ps

module tb_control_unit;

    reg  [6:0] opcode;

    wire       reg_write;
    wire       mem_read;
    wire       mem_write;
    wire       mem_to_reg;
    wire       alu_src;
    wire       branch;
    wire       jump;
    wire [1:0] alu_op;

    integer pass_count;
    integer fail_count;

    // Opcodes (must match control_unit.v)
    localparam OPCODE_R_TYPE = 7'b0110011;
    localparam OPCODE_OP_IMM = 7'b0010011;
    localparam OPCODE_LOAD   = 7'b0000011;
    localparam OPCODE_STORE  = 7'b0100011;
    localparam OPCODE_BRANCH = 7'b1100011;
    localparam OPCODE_LUI    = 7'b0110111;
    localparam OPCODE_AUIPC  = 7'b0010111;
    localparam OPCODE_JAL    = 7'b1101111;
    localparam OPCODE_JALR   = 7'b1100111;
    localparam OPCODE_INVALID= 7'b1111111; // not a valid RV32I opcode

    //---------------------------------------------------------
    // DUT instantiation
    //---------------------------------------------------------
    control_unit dut (
        .opcode     (opcode),
        .reg_write  (reg_write),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .mem_to_reg (mem_to_reg),
        .alu_src    (alu_src),
        .branch     (branch),
        .jump       (jump),
        .alu_op     (alu_op)
    );

    //---------------------------------------------------------
    // Self-checking task
    //---------------------------------------------------------
    task run_test;
        input [319:0] test_name;
        input [6:0]   opcode_in;
        input         exp_reg_write;
        input         exp_mem_read;
        input         exp_mem_write;
        input         exp_mem_to_reg;
        input         exp_alu_src;
        input         exp_branch;
        input         exp_jump;
        input [1:0]   exp_alu_op;
        begin
            opcode = opcode_in;
            #1;
            if ((reg_write  === exp_reg_write)  &&
                (mem_read   === exp_mem_read)   &&
                (mem_write  === exp_mem_write)  &&
                (mem_to_reg === exp_mem_to_reg) &&
                (alu_src    === exp_alu_src)    &&
                (branch     === exp_branch)     &&
                (jump       === exp_jump)       &&
                (alu_op     === exp_alu_op)) begin
                pass_count = pass_count + 1;
                $display("[PASS] %0s : opcode=%b -> RegWrite=%b MemRead=%b MemWrite=%b MemToReg=%b ALUSrc=%b Branch=%b Jump=%b ALUOp=%b",
                          test_name, opcode_in, reg_write, mem_read, mem_write,
                          mem_to_reg, alu_src, branch, jump, alu_op);
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] %0s : opcode=%b", test_name, opcode_in);
                $display("        got      : RegWrite=%b MemRead=%b MemWrite=%b MemToReg=%b ALUSrc=%b Branch=%b Jump=%b ALUOp=%b",
                          reg_write, mem_read, mem_write, mem_to_reg, alu_src, branch, jump, alu_op);
                $display("        expected : RegWrite=%b MemRead=%b MemWrite=%b MemToReg=%b ALUSrc=%b Branch=%b Jump=%b ALUOp=%b",
                          exp_reg_write, exp_mem_read, exp_mem_write, exp_mem_to_reg,
                          exp_alu_src, exp_branch, exp_jump, exp_alu_op);
            end
        end
    endtask

    //---------------------------------------------------------
    // Test sequence -- one test per instruction class, matching
    // the control table in the explanation.
    //---------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("=========================================");
        $display(" MAIN CONTROL UNIT TESTBENCH START");
        $display("=========================================");

        //                 name                opcode           RW  MR  MW  M2R ASrc Br  Jmp ALUOp
        run_test("R_TYPE",          OPCODE_R_TYPE,   1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b10);
        run_test("I_TYPE_OP_IMM",   OPCODE_OP_IMM,   1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b10);
        run_test("LOAD_LW",         OPCODE_LOAD,     1'b1, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 2'b00);
        run_test("STORE_SW",        OPCODE_STORE,    1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 2'b00);
        run_test("BRANCH",          OPCODE_BRANCH,   1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b01);
        run_test("LUI",             OPCODE_LUI,      1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b11);
        run_test("AUIPC",           OPCODE_AUIPC,    1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b00);
        run_test("JAL",             OPCODE_JAL,      1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'b00);
        run_test("JALR",            OPCODE_JALR,     1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 2'b00);

        // Unknown opcode must produce all-inactive (safe defaults), not X or latched garbage
        run_test("UNKNOWN_OPCODE_safe_default", OPCODE_INVALID,
                  1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00);

        // Switching between two opcodes back-to-back must update ALL
        // signals correctly (no stale bits held from the previous opcode)
        run_test("SWITCH_TO_R_TYPE_AFTER_LOAD_1", OPCODE_LOAD,
                  1'b1, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 2'b00);
        run_test("SWITCH_TO_R_TYPE_AFTER_LOAD_2", OPCODE_R_TYPE,
                  1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b10);

        $display("=========================================");
        $display(" MAIN CONTROL UNIT TESTBENCH COMPLETE");
        $display(" PASS = %0d  FAIL = %0d", pass_count, fail_count);
        if (fail_count == 0)
            $display(" RESULT : ALL TESTS PASSED");
        else
            $display(" RESULT : %0d TEST(S) FAILED", fail_count);
        $display("=========================================");

        $finish;
    end

endmodule
