//=============================================================
// Module      : tb_immediate_generator
// Description : Self-checking testbench for immediate_generator.v
//               Builds representative I/S/B/U/J-type instructions
//               (positive and negative immediates, plus boundary
//               values) using format-encoding functions that
//               mirror the RV32I spec, then checks the extracted
//               immediate against the value used to build it.
// Standard    : Synthesizable/simulatable Verilog-2001
//=============================================================
`timescale 1ns/1ps

module tb_immediate_generator;

    reg  [31:0] instruction;
    wire [31:0] imm_out;

    integer pass_count;
    integer fail_count;

    // Opcodes (must match immediate_generator.v)
    localparam OPCODE_LOAD   = 7'b0000011;
    localparam OPCODE_OP_IMM = 7'b0010011;
    localparam OPCODE_JALR   = 7'b1100111;
    localparam OPCODE_STORE  = 7'b0100011;
    localparam OPCODE_BRANCH = 7'b1100011;
    localparam OPCODE_LUI    = 7'b0110111;
    localparam OPCODE_AUIPC  = 7'b0010111;
    localparam OPCODE_JAL    = 7'b1101111;

    //---------------------------------------------------------
    // DUT instantiation
    //---------------------------------------------------------
    immediate_generator dut (
        .instruction (instruction),
        .imm_out     (imm_out)
    );

    //---------------------------------------------------------
    // Instruction-building functions.
    // These mirror the RV32I spec's bit scatter EXACTLY (the
    // inverse of what the DUT must do), so they double as an
    // independent reference model for the testbench.
    //---------------------------------------------------------

    // I-type: imm[11:0], rs1[4:0], funct3[2:0], rd[4:0], opcode[6:0]
    function [31:0] make_itype;
        input [11:0] imm12;
        input [4:0]  rs1;
        input [2:0]  funct3;
        input [4:0]  rd;
        input [6:0]  opcode;
        begin
            make_itype = {imm12, rs1, funct3, rd, opcode};
        end
    endfunction

    // S-type: imm[11:5], rs2[4:0], rs1[4:0], funct3[2:0], imm[4:0], opcode[6:0]
    function [31:0] make_stype;
        input [11:0] imm12;
        input [4:0]  rs2;
        input [4:0]  rs1;
        input [2:0]  funct3;
        input [6:0]  opcode;
        begin
            make_stype = {imm12[11:5], rs2, rs1, funct3, imm12[4:0], opcode};
        end
    endfunction

    // B-type: imm[12],imm[10:5], rs2, rs1, funct3, imm[4:1],imm[11], opcode
    // imm13 passed in with bit0 = 0 always (2-byte aligned target)
    function [31:0] make_btype;
        input [12:0] imm13;
        input [4:0]  rs2;
        input [4:0]  rs1;
        input [2:0]  funct3;
        input [6:0]  opcode;
        begin
            make_btype = {imm13[12], imm13[10:5], rs2, rs1, funct3,
                          imm13[4:1], imm13[11], opcode};
        end
    endfunction

    // U-type: imm[31:12], rd[4:0], opcode[6:0]
    function [31:0] make_utype;
        input [19:0] imm20;
        input [4:0]  rd;
        input [6:0]  opcode;
        begin
            make_utype = {imm20, rd, opcode};
        end
    endfunction

    // J-type: imm[20],imm[10:1],imm[11],imm[19:12], rd, opcode
    // imm21 passed in with bit0 = 0 always (2-byte aligned target)
    function [31:0] make_jtype;
        input [20:0] imm21;
        input [4:0]  rd;
        input [6:0]  opcode;
        begin
            make_jtype = {imm21[20], imm21[10:1], imm21[11], imm21[19:12],
                          rd, opcode};
        end
    endfunction

    //---------------------------------------------------------
    // Self-checking task
    //---------------------------------------------------------
    task run_test;
        input [319:0]     test_name;
        input [31:0]       instr_in;
        input signed [31:0] expected;
        begin
            instruction = instr_in;
            #1;
            if (imm_out === expected) begin
                pass_count = pass_count + 1;
                $display("[PASS] %0s : instr=0x%h imm_out=%0d (0x%h)",
                          test_name, instr_in, $signed(imm_out), imm_out);
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] %0s : instr=0x%h got=%0d(0x%h) expected=%0d(0x%h)",
                          test_name, instr_in, $signed(imm_out), imm_out,
                          expected, expected);
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
        $display(" IMMEDIATE GENERATOR TESTBENCH START");
        $display("=========================================");

        // ================= I-type =================
        // ADDI x1, x2, 100
        run_test("ITYPE_ADDI_positive",
                  make_itype(12'd100, 5'd2, 3'b000, 5'd1, OPCODE_OP_IMM),
                  32'sd100);

        // ADDI x1, x2, -1  (all-ones immediate -> imm_out must be -1, i.e. 0xFFFFFFFF)
        run_test("ITYPE_ADDI_negative_one",
                  make_itype(-12'sd1, 5'd2, 3'b000, 5'd1, OPCODE_OP_IMM),
                  -32'sd1);

        // LW x5, 2047(x6)  -> max positive 12-bit immediate
        run_test("ITYPE_LW_max_positive",
                  make_itype(12'sd2047, 5'd6, 3'b010, 5'd5, OPCODE_LOAD),
                  32'sd2047);

        // JALR x0, -2048(x1) -> min negative 12-bit immediate
        run_test("ITYPE_JALR_min_negative",
                  make_itype(-12'sd2048, 5'd1, 3'b000, 5'd0, OPCODE_JALR),
                  -32'sd2048);

        // ================= S-type =================
        // SW x3, 100(x4)
        run_test("STYPE_SW_positive",
                  make_stype(12'sd100, 5'd3, 5'd4, 3'b010, OPCODE_STORE),
                  32'sd100);

        // SW x3, -100(x4)
        run_test("STYPE_SW_negative",
                  make_stype(-12'sd100, 5'd3, 5'd4, 3'b010, OPCODE_STORE),
                  -32'sd100);

        // SB x0, -1(x0) -> boundary min value
        run_test("STYPE_min_negative",
                  make_stype(-12'sd2048, 5'd0, 5'd0, 3'b000, OPCODE_STORE),
                  -32'sd2048);

        // ================= B-type =================
        // BEQ x1, x2, +8  (forward branch)
        run_test("BTYPE_BEQ_forward",
                  make_btype(13'sd8, 5'd2, 5'd1, 3'b000, OPCODE_BRANCH),
                  32'sd8);

        // BNE x1, x2, -4  (backward branch, e.g. loop)
        run_test("BTYPE_BNE_backward",
                  make_btype(-13'sd4, 5'd2, 5'd1, 3'b001, OPCODE_BRANCH),
                  -32'sd4);

        // BLT x1, x2, +4094 -> near max positive (even, bit0=0)
        run_test("BTYPE_max_positive",
                  make_btype(13'sd4094, 5'd2, 5'd1, 3'b100, OPCODE_BRANCH),
                  32'sd4094);

        // ================= U-type =================
        // LUI x5, 0xABCDE
        run_test("UTYPE_LUI",
                  make_utype(20'hABCDE, 5'd5, OPCODE_LUI),
                  32'shABCDE000);

        // AUIPC x6, 0x00001
        run_test("UTYPE_AUIPC",
                  make_utype(20'h00001, 5'd6, OPCODE_AUIPC),
                  32'sh00001000);

        // ================= J-type =================
        // JAL x1, +16
        run_test("JTYPE_JAL_forward",
                  make_jtype(21'sd16, 5'd1, OPCODE_JAL),
                  32'sd16);

        // JAL x1, -16
        run_test("JTYPE_JAL_backward",
                  make_jtype(-21'sd16, 5'd1, OPCODE_JAL),
                  -32'sd16);

        // JAL x0, +1048574 -> near max positive J-type immediate (even)
        run_test("JTYPE_max_positive",
                  make_jtype(21'sd1048574, 5'd0, OPCODE_JAL),
                  32'sd1048574);

        // ================= Unrecognized opcode =================
        run_test("UNKNOWN_OPCODE_returns_zero",
                  32'h0000007F, // opcode = 1111111, not a valid RV32I opcode
                  32'sd0);

        $display("=========================================");
        $display(" IMMEDIATE GENERATOR TESTBENCH COMPLETE");
        $display(" PASS = %0d  FAIL = %0d", pass_count, fail_count);
        if (fail_count == 0)
            $display(" RESULT : ALL TESTS PASSED");
        else
            $display(" RESULT : %0d TEST(S) FAILED", fail_count);
        $display("=========================================");

        $finish;
    end

endmodule
