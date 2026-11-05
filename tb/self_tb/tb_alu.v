//=============================================================
// Module      : tb_alu
// Description : Self-checking testbench for alu.v
//               Tests all 10 RV32I ALU operations across
//               zero/positive/negative/boundary operands.
// Standard    : Synthesizable/simulatable Verilog-2001
//=============================================================
`timescale 1ns/1ps

module tb_alu;

    localparam WIDTH = 32;

    reg  [WIDTH-1:0] operand_a;
    reg  [WIDTH-1:0] operand_b;
    reg  [3:0]       alu_op;

    wire [WIDTH-1:0] alu_result;
    wire             zero_flag;

    integer pass_count;
    integer fail_count;

    // ALU opcode mirror (must match alu.v encoding)
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

    //---------------------------------------------------------
    // DUT instantiation
    //---------------------------------------------------------
    alu #(.WIDTH(WIDTH)) dut (
        .operand_a  (operand_a),
        .operand_b  (operand_b),
        .alu_op     (alu_op),
        .alu_result (alu_result),
        .zero_flag  (zero_flag)
    );

    //---------------------------------------------------------
    // Self-checking task
    //---------------------------------------------------------
    task run_test;
        input [199:0]     test_name;   // string label (25 chars @ 8 bits/char)
        input [WIDTH-1:0] a_in;
        input [WIDTH-1:0] b_in;
        input [3:0]       op_in;
        input [WIDTH-1:0] expected_result;
        input             expected_zero;
        begin
            operand_a = a_in;
            operand_b = b_in;
            alu_op    = op_in;
            #10; // allow combinational logic to settle

            if ((alu_result === expected_result) && (zero_flag === expected_zero)) begin
                pass_count = pass_count + 1;
                $display("[PASS] %0s : a=%0d b=%0d op=%b result=%0d (0x%h) zero=%b",
                          test_name, $signed(a_in), $signed(b_in), op_in,
                          $signed(alu_result), alu_result, zero_flag);
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] %0s : a=%0d b=%0d op=%b => got result=%0d(0x%h) zero=%b, expected result=%0d(0x%h) zero=%b",
                          test_name, $signed(a_in), $signed(b_in), op_in,
                          $signed(alu_result), alu_result, zero_flag,
                          $signed(expected_result), expected_result, expected_zero);
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
        $display(" ALU TESTBENCH START");
        $display("=========================================");

        // ---------- ADD ----------
        run_test("ADD_pos_pos",      32'd10,          32'd20,          ALU_ADD, 32'd30, 1'b0);
        run_test("ADD_zero",         32'd0,            32'd0,           ALU_ADD, 32'd0,  1'b1);
        run_test("ADD_neg_pos",     -32'sd5,          32'd5,           ALU_ADD, 32'd0,  1'b1);
        run_test("ADD_overflow_wrap",32'hFFFFFFFF,     32'd1,           ALU_ADD, 32'd0,  1'b1); // wraps to 0

        // ---------- SUB ----------
        run_test("SUB_equal",        32'd15,           32'd15,          ALU_SUB, 32'd0,  1'b1);
        run_test("SUB_pos_result",   32'd20,           32'd5,           ALU_SUB, 32'd15, 1'b0);
        run_test("SUB_neg_result",   32'd5,            32'd20,          ALU_SUB, -32'sd15, 1'b0);

        // ---------- AND / OR / XOR ----------
        run_test("AND_basic",        32'hFF00FF00,     32'h0F0F0F0F,    ALU_AND, 32'h0F000F00, 1'b0);
        run_test("OR_basic",         32'hFF00FF00,     32'h00FF00FF,    ALU_OR,  32'hFFFFFFFF, 1'b0);
        run_test("XOR_same",         32'hAAAAAAAA,     32'hAAAAAAAA,    ALU_XOR, 32'h00000000, 1'b1);

        // ---------- Shifts ----------
        run_test("SLL_basic",        32'h00000001,     32'd4,           ALU_SLL, 32'h00000010, 1'b0);
        run_test("SLL_maxshift",     32'h00000001,     32'd31,          ALU_SLL, 32'h80000000, 1'b0);
        run_test("SRL_basic",        32'h80000000,     32'd4,           ALU_SRL, 32'h08000000, 1'b0);
        run_test("SRA_negative",     32'hFFFFFFF0,      32'd4,          ALU_SRA, 32'hFFFFFFFF, 1'b0); // sign-extends
        run_test("SRA_positive",     32'h7FFFFFF0,      32'd4,          ALU_SRA, 32'h07FFFFFF, 1'b0);

        // ---------- SLT (signed) ----------
        run_test("SLT_true_neg_lt_pos", -32'sd1,        32'd1,          ALU_SLT, 32'd1, 1'b0);
        run_test("SLT_false_pos_lt_neg", 32'd1,        -32'sd1,         ALU_SLT, 32'd0, 1'b1);
        run_test("SLT_equal",            32'd7,         32'd7,          ALU_SLT, 32'd0, 1'b1);

        // ---------- SLTU (unsigned) ----------
        run_test("SLTU_true",        32'h00000001,      32'hFFFFFFFF,   ALU_SLTU, 32'd1, 1'b0); // 1 < 0xFFFFFFFF unsigned
        run_test("SLTU_false",       32'hFFFFFFFF,       32'h00000001,  ALU_SLTU, 32'd0, 1'b1);
        run_test("SLTU_equal",       32'd100,            32'd100,       ALU_SLTU, 32'd0, 1'b1);

        // ---------- Boundary values ----------
        run_test("MAX_pos_ADD_1",    32'h7FFFFFFF,       32'd1,          ALU_ADD, 32'h80000000, 1'b0); // signed overflow wrap
        run_test("MIN_neg_SUB_1",    32'h80000000,       32'd1,          ALU_SUB, 32'h7FFFFFFF, 1'b0); // signed underflow wrap

        $display("=========================================");
        $display(" ALU TESTBENCH COMPLETE");
        $display(" PASS = %0d  FAIL = %0d", pass_count, fail_count);
        if (fail_count == 0)
            $display(" RESULT : ALL TESTS PASSED");
        else
            $display(" RESULT : %0d TEST(S) FAILED", fail_count);
        $display("=========================================");

        $finish;
    end

endmodule
