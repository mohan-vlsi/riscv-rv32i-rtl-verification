//=============================================================
// Module      : tb_instruction_memory
// Description : Self-checking testbench for instruction_memory.v
//               Verifies the preloaded test program is readable
//               at the correct addresses, that unused memory
//               returns NOP, that byte-offset bits within a word
//               are correctly ignored (alignment truncation), and
//               that an out-of-declared-range address aliases
//               deterministically rather than producing X/garbage.
// Standard    : Synthesizable/simulatable Verilog-2001
//=============================================================
`timescale 1ns/1ps

module tb_instruction_memory;

    localparam WORD_ADDR_WIDTH = 8;
    localparam MEM_SIZE_WORDS  = (1 << WORD_ADDR_WIDTH);

    reg  [31:0] addr;
    wire [31:0] instruction;

    integer pass_count;
    integer fail_count;

    //---------------------------------------------------------
    // DUT instantiation
    //---------------------------------------------------------
    instruction_memory #(
        .WORD_ADDR_WIDTH (WORD_ADDR_WIDTH),
        .MEM_SIZE_WORDS  (MEM_SIZE_WORDS)
    ) dut (
        .addr        (addr),
        .instruction (instruction)
    );

    //---------------------------------------------------------
    // Self-checking task
    //---------------------------------------------------------
    task run_test;
        input [319:0] test_name;
        input [31:0]  addr_in;
        input [31:0]  expected;
        begin
            addr = addr_in;
            #1;
            if (instruction === expected) begin
                pass_count = pass_count + 1;
                $display("[PASS] %0s : addr=0x%h -> instruction=0x%h",
                          test_name, addr_in, instruction);
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] %0s : addr=0x%h -> got=0x%h expected=0x%h",
                          test_name, addr_in, instruction, expected);
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
        $display(" INSTRUCTION MEMORY TESTBENCH START");
        $display("=========================================");

        // ---------- Preloaded program, in fetch order ----------
        run_test("FETCH_0x00_ADDI_x1", 32'h00000000, 32'h00500093);
        run_test("FETCH_0x04_ADDI_x2", 32'h00000004, 32'h00A00113);
        run_test("FETCH_0x08_ADD_x3",  32'h00000008, 32'h002081B3);
        run_test("FETCH_0x0C_SUB_x4",  32'h0000000C, 32'h40208233);
        run_test("FETCH_0x10_JAL_selfloop", 32'h00000010, 32'h0000006F);

        // ---------- Unused region returns NOP ----------
        run_test("FETCH_0x14_unused_is_NOP", 32'h00000014, 32'h00000013);
        run_test("FETCH_0x40_unused_is_NOP", 32'h00000040, 32'h00000013);

        // ---------- Byte-offset bits within a word are ignored ----------
        // addr=0x02 is not a legally aligned RV32I fetch address, but the
        // hardware still deterministically truncates to word_index=0 --
        // demonstrating exactly why the base ISA REQUIRES fetch alignment
        // rather than relying on this truncation behavior.
        run_test("MISALIGNED_addr_0x02_truncates_to_word0", 32'h00000002, 32'h00500093);
        run_test("MISALIGNED_addr_0x0E_truncates_to_word3", 32'h0000000E, 32'h40208233);

        // ---------- Last word in declared memory range ----------
        run_test("LAST_WORD_index255", 32'h000003FC, 32'h00000013); // word 255, NOP

        // ---------- Address bits above the decoded window alias/wrap ----------
        // Only addr[9:2] is used as the word index; upper address bits are
        // simply not connected to anything in this simple decoder, so a
        // large out-of-range address silently aliases to some in-range
        // word rather than causing an error. addr=0xFFFFFFFF -> addr[9:2]
        // = all ones = word 255 (same as LAST_WORD_index255 above).
        run_test("OUT_OF_RANGE_ADDR_ALIASES_word255", 32'hFFFFFFFF, 32'h00000013);

        $display("=========================================");
        $display(" INSTRUCTION MEMORY TESTBENCH COMPLETE");
        $display(" PASS = %0d  FAIL = %0d", pass_count, fail_count);
        if (fail_count == 0)
            $display(" RESULT : ALL TESTS PASSED");
        else
            $display(" RESULT : %0d TEST(S) FAILED", fail_count);
        $display("=========================================");

        $finish;
    end

endmodule
