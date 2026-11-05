//=============================================================
// Module      : tb_alu_control
// Description : Self-checking testbench for alu_control.v
//               Covers all 10 R-type ops, all I-type arithmetic
//               ops (including the ADDI-vs-SUB disambiguation
//               bug case), shift-immediate SRLI/SRAI, and the
//               fixed classes (load/store, branch, LUI).
// Standard    : Synthesizable/simulatable Verilog-2001
//=============================================================
`timescale 1ns/1ps

module tb_alu_control;

    reg  [1:0] alu_op;
    reg  [6:0] opcode;
    reg  [2:0] funct3;
    reg  [6:0] funct7;

    wire [3:0] alu_ctrl;

    integer pass_count;
    integer fail_count;

    // ALU op encoding (must match alu.v / alu_control.v)
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLL  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_SLT  = 4'b1000;
    localparam ALU_SLTU = 4'b1001;

    // Opcodes
    localparam OPCODE_R_TYPE = 7'b0110011;
    localparam OPCODE_OP_IMM = 7'b0010011;
    localparam OPCODE_LOAD   = 7'b0000011;
    localparam OPCODE_STORE  = 7'b0100011;
    localparam OPCODE_BRANCH = 7'b1100011;
    localparam OPCODE_LUI    = 7'b0110111;

    // ALUOp classes
    localparam CLASS_LOAD_STORE  = 2'b00;
    localparam CLASS_BRANCH      = 2'b01;
    localparam CLASS_RTYPE_ITYPE = 2'b10;
    localparam CLASS_LUI         = 2'b11;

    // funct7 patterns
    localparam FUNCT7_STD = 7'b0000000; // ADD / SRL / logical
    localparam FUNCT7_ALT = 7'b0100000; // SUB / SRA

    //---------------------------------------------------------
    // DUT instantiation
    //---------------------------------------------------------
    alu_control dut (
        .alu_op   (alu_op),
        .opcode   (opcode),
        .funct3   (funct3),
        .funct7   (funct7),
        .alu_ctrl (alu_ctrl)
    );

    //---------------------------------------------------------
    // Self-checking task
    //---------------------------------------------------------
    task run_test;
        input [319:0] test_name;
        input [1:0]   alu_op_in;
        input [6:0]   opcode_in;
        input [2:0]   funct3_in;
        input [6:0]   funct7_in;
        input [3:0]   expected;
        begin
            alu_op = alu_op_in;
            opcode = opcode_in;
            funct3 = funct3_in;
            funct7 = funct7_in;
            #1;
            if (alu_ctrl === expected) begin
                pass_count = pass_count + 1;
                $display("[PASS] %0s : alu_op=%b opcode=%b funct3=%b funct7=%b -> alu_ctrl=%b",
                          test_name, alu_op_in, opcode_in, funct3_in, funct7_in, alu_ctrl);
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] %0s : alu_op=%b opcode=%b funct3=%b funct7=%b -> got=%b expected=%b",
                          test_name, alu_op_in, opcode_in, funct3_in, funct7_in, alu_ctrl, expected);
            end
        end
    endtask

    //---------------------------------------------------------
    // Test sequence
    //---------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("=========================================");
        $display(" ALU CONTROL UNIT TESTBENCH START");
        $display("=========================================");

        // ================= R-type: all 10 ALU ops =================
        run_test("RTYPE_ADD",  CLASS_RTYPE_ITYPE, OPCODE_R_TYPE, 3'b000, FUNCT7_STD, ALU_ADD);
        run_test("RTYPE_SUB",  CLASS_RTYPE_ITYPE, OPCODE_R_TYPE, 3'b000, FUNCT7_ALT, ALU_SUB);
        run_test("RTYPE_SLL",  CLASS_RTYPE_ITYPE, OPCODE_R_TYPE, 3'b001, FUNCT7_STD, ALU_SLL);
        run_test("RTYPE_SLT",  CLASS_RTYPE_ITYPE, OPCODE_R_TYPE, 3'b010, FUNCT7_STD, ALU_SLT);
        run_test("RTYPE_SLTU", CLASS_RTYPE_ITYPE, OPCODE_R_TYPE, 3'b011, FUNCT7_STD, ALU_SLTU);
        run_test("RTYPE_XOR",  CLASS_RTYPE_ITYPE, OPCODE_R_TYPE, 3'b100, FUNCT7_STD, ALU_XOR);
        run_test("RTYPE_SRL",  CLASS_RTYPE_ITYPE, OPCODE_R_TYPE, 3'b101, FUNCT7_STD, ALU_SRL);
        run_test("RTYPE_SRA",  CLASS_RTYPE_ITYPE, OPCODE_R_TYPE, 3'b101, FUNCT7_ALT, ALU_SRA);
        run_test("RTYPE_OR",   CLASS_RTYPE_ITYPE, OPCODE_R_TYPE, 3'b110, FUNCT7_STD, ALU_OR);
        run_test("RTYPE_AND",  CLASS_RTYPE_ITYPE, OPCODE_R_TYPE, 3'b111, FUNCT7_STD, ALU_AND);

        // ================= I-type arithmetic =================
        run_test("ITYPE_ADDI_positive_imm", CLASS_RTYPE_ITYPE, OPCODE_OP_IMM, 3'b000, FUNCT7_STD, ALU_ADD);

        // *** THE critical disambiguation test ***
        // ADDI with an immediate whose upper 7 bits happen to equal the
        // "SUB" funct7 pattern (0100000) purely because the immediate is
        // negative. This MUST still resolve to ADD, never SUB.
        run_test("ITYPE_ADDI_negative_imm_looks_like_funct7_SUB",
                  CLASS_RTYPE_ITYPE, OPCODE_OP_IMM, 3'b000, FUNCT7_ALT, ALU_ADD);

        run_test("ITYPE_SLTI",  CLASS_RTYPE_ITYPE, OPCODE_OP_IMM, 3'b010, FUNCT7_STD, ALU_SLT);
        run_test("ITYPE_SLTIU", CLASS_RTYPE_ITYPE, OPCODE_OP_IMM, 3'b011, FUNCT7_STD, ALU_SLTU);
        run_test("ITYPE_XORI",  CLASS_RTYPE_ITYPE, OPCODE_OP_IMM, 3'b100, FUNCT7_STD, ALU_XOR);
        run_test("ITYPE_ORI",   CLASS_RTYPE_ITYPE, OPCODE_OP_IMM, 3'b110, FUNCT7_STD, ALU_OR);
        run_test("ITYPE_ANDI",  CLASS_RTYPE_ITYPE, OPCODE_OP_IMM, 3'b111, FUNCT7_STD, ALU_AND);

        // ================= I-type shift-immediate =================
        // These DO legitimately use funct7[5], for both opcodes.
        run_test("ITYPE_SLLI", CLASS_RTYPE_ITYPE, OPCODE_OP_IMM, 3'b001, FUNCT7_STD, ALU_SLL);
        run_test("ITYPE_SRLI", CLASS_RTYPE_ITYPE, OPCODE_OP_IMM, 3'b101, FUNCT7_STD, ALU_SRL);
        run_test("ITYPE_SRAI", CLASS_RTYPE_ITYPE, OPCODE_OP_IMM, 3'b101, FUNCT7_ALT, ALU_SRA);

        // ================= Fixed classes =================
        // Load/Store: always ADD, regardless of funct3/funct7 noise
        run_test("LOAD_LW_forces_ADD",  CLASS_LOAD_STORE, OPCODE_LOAD,  3'b111, FUNCT7_ALT, ALU_ADD);
        run_test("STORE_SW_forces_ADD", CLASS_LOAD_STORE, OPCODE_STORE, 3'b111, FUNCT7_ALT, ALU_ADD);

        // Branch: always SUB, regardless of funct3/funct7 noise
        run_test("BRANCH_BEQ_forces_SUB", CLASS_BRANCH, OPCODE_BRANCH, 3'b000, FUNCT7_ALT, ALU_SUB);
        run_test("BRANCH_BNE_forces_SUB", CLASS_BRANCH, OPCODE_BRANCH, 3'b001, FUNCT7_ALT, ALU_SUB);

        // BLT/BGE: signed less-than comparison, regardless of the
        // invert bit (funct3[0]) -- that inversion is applied by the
        // CALLER using alu_result[0] + funct3[0], not selected here.
        run_test("BRANCH_BLT_uses_SLT", CLASS_BRANCH, OPCODE_BRANCH, 3'b100, FUNCT7_STD, ALU_SLT);
        run_test("BRANCH_BGE_uses_SLT", CLASS_BRANCH, OPCODE_BRANCH, 3'b101, FUNCT7_STD, ALU_SLT);

        // BLTU/BGEU: unsigned less-than comparison
        run_test("BRANCH_BLTU_uses_SLTU", CLASS_BRANCH, OPCODE_BRANCH, 3'b110, FUNCT7_STD, ALU_SLTU);
        run_test("BRANCH_BGEU_uses_SLTU", CLASS_BRANCH, OPCODE_BRANCH, 3'b111, FUNCT7_STD, ALU_SLTU);

        // LUI: pass-through class -> ADD
        run_test("LUI_forces_ADD", CLASS_LUI, OPCODE_LUI, 3'b000, FUNCT7_STD, ALU_ADD);

        $display("=========================================");
        $display(" ALU CONTROL UNIT TESTBENCH COMPLETE");
        $display(" PASS = %0d  FAIL = %0d", pass_count, fail_count);
        if (fail_count == 0)
            $display(" RESULT : ALL TESTS PASSED");
        else
            $display(" RESULT : %0d TEST(S) FAILED", fail_count);
        $display("=========================================");

        $finish;
    end

endmodule
