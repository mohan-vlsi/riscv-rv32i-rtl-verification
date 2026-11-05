//=============================================================
// Module      : tb_riscv_core
// Project     : RV32I 5-Stage Pipelined Processor
// Description : Top-level, self-checking testbench for riscv_core.v.
//               Runs FOUR sequential phases against a single DUT
//               instance, each phase resetting the processor and
//               loading a fresh test program directly into
//               instruction memory (hierarchical poke -- no
//               external hex files, per project convention).
//               Instruction memory words 0-31 are explicitly
//               cleared to NOP before each phase's poke, so a
//               longer PRIOR phase's leftover instructions can
//               never accidentally execute during a SHORTER
//               later phase.
//
//               PHASE 1 -- Structural correctness (no register
//                 dependencies between instructions). Isolates
//                 "do the pipeline registers correctly carry data
//                 through 5 stages" from hazard handling.
//               PHASE 2 -- RAW hazard forwarding (EX/MEM and
//                 MEM/WB paths) and the load-use stall.
//               PHASE 3 -- Branch/jump PC resolution and pipeline
//                 flush for BEQ (taken), JAL, JALR, and a
//                 not-taken BEQ (straight-line fallthrough).
//                 Sentinel registers prove wrong-path instructions
//                 are genuinely discarded, not just coincidentally
//                 overwritten later.
//               PHASE 4 -- BLT/BGE/BLTU/BGEU, including the
//                 signed-vs-unsigned distinction on an identical
//                 bit pattern, with the same sentinel-register
//                 flush proof as Phase 3.
//               PHASE 5 -- Every remaining untested opcode:
//                 R-type AND/OR/XOR/SLL/SRL/SRA/SLT/SLTU, I-type
//                 ANDI/ORI/XORI/SLLI/SRLI/SRAI/SLTI/SLTIU, and
//                 LUI/AUIPC -- exercised through riscv_core's
//                 actual decode path, not just each block's own
//                 standalone testbench.
//
// Standard    : Synthesizable/simulatable Verilog-2001
//=============================================================
`timescale 1ns/1ps

module tb_riscv_core;

    reg clk;
    reg rst_n;

    integer pass_count;
    integer fail_count;
    integer clr_i;

    riscv_core dut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    //-----------------------------------------------------------
    // Self-checking task (shared by all phases)
    //-----------------------------------------------------------
    task check_val;
        input [319:0] test_name;
        input [31:0]  actual;
        input [31:0]  expected;
        begin
            if (actual === expected) begin
                pass_count = pass_count + 1;
                $display("[PASS] %0s : got=0x%h (%0d)", test_name, actual, $signed(actual));
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] %0s : got=0x%h(%0d) expected=0x%h(%0d)",
                          test_name, actual, $signed(actual), expected, $signed(expected));
            end
        end
    endtask

    //-----------------------------------------------------------
    // Clears instruction memory words 0-31 to NOP. Called before
    // each phase's poke so a shorter phase can never accidentally
    // execute a longer PRIOR phase's leftover instructions.
    //-----------------------------------------------------------
    task clear_imem;
        begin
            for (clr_i = 0; clr_i < 32; clr_i = clr_i + 1)
                dut.u_imem.mem[clr_i] = 32'h00000013; // NOP
        end
    endtask

    //-----------------------------------------------------------
    // Asserts reset for 2 cycles then releases. Clears the
    // register file, PC, and all 4 pipeline registers (each has
    // its own synchronous reset). Does NOT touch instruction
    // memory -- call clear_imem/poke BEFORE this, so the correct
    // program is already in place when reset releases and IF
    // starts fetching from PC=0.
    //-----------------------------------------------------------
    task do_reset;
        begin
            rst_n = 1'b0;
            @(negedge clk);
            @(negedge clk);
            rst_n = 1'b1;
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        rst_n = 1'b0;

        $display("=========================================");
        $display(" TOP-LEVEL RISCV_CORE TESTBENCH START");
        $display(" 4 sequential self-checking phases");
        $display("=========================================");

        //=========================================================
        // PHASE 1: Structural correctness (no dependencies)
        //=========================================================
        $display("-----------------------------------------");
        $display(" PHASE 1: Structural pipeline correctness");
        $display("-----------------------------------------");

        clear_imem;
        dut.u_imem.mem[0] = 32'h00A00093; // ADDI x1,x0,10
        dut.u_imem.mem[1] = 32'h01400113; // ADDI x2,x0,20
        dut.u_imem.mem[2] = 32'h01E00193; // ADDI x3,x0,30
        dut.u_imem.mem[3] = 32'h02800213; // ADDI x4,x0,40
        dut.u_imem.mem[4] = 32'h03200293; // ADDI x5,x0,50
        dut.u_imem.mem[5] = 32'h03C00313; // ADDI x6,x0,60

        do_reset;
        repeat (10) @(posedge clk);
        @(negedge clk);

        check_val("P1_REG_x1", dut.u_rf.regfile[1], 32'd10);
        check_val("P1_REG_x2", dut.u_rf.regfile[2], 32'd20);
        check_val("P1_REG_x3", dut.u_rf.regfile[3], 32'd30);
        check_val("P1_REG_x4", dut.u_rf.regfile[4], 32'd40);
        check_val("P1_REG_x5", dut.u_rf.regfile[5], 32'd50);
        check_val("P1_REG_x6", dut.u_rf.regfile[6], 32'd60);
        check_val("P1_REG_x0_never_written", dut.u_rf.regfile[0], 32'd0);

        //=========================================================
        // PHASE 2: Forwarding + load-use hazard stall
        //=========================================================
        $display("-----------------------------------------");
        $display(" PHASE 2: Forwarding + load-use stall");
        $display("-----------------------------------------");

        clear_imem;
        dut.u_imem.mem[0] = 32'h00500093; // ADDI x1,x0,5
        dut.u_imem.mem[1] = 32'h00108133; // ADD  x2,x1,x1   EX-hazard
        dut.u_imem.mem[2] = 32'h00700193; // ADDI x3,x0,7
        dut.u_imem.mem[3] = 32'h00100213; // ADDI x4,x0,1    filler
        dut.u_imem.mem[4] = 32'h000182B3; // ADD  x5,x3,x0   MEM-hazard
        dut.u_imem.mem[5] = 32'h00102023; // SW   x1,0(x0)
        dut.u_imem.mem[6] = 32'h00002303; // LW   x6,0(x0)
        dut.u_imem.mem[7] = 32'h06430393; // ADDI x7,x6,100  load-use hazard
        dut.u_imem.mem[8] = 32'h00310433; // ADD  x8,x2,x3

        do_reset;
        repeat (20) @(posedge clk);
        @(negedge clk);

        check_val("P2_REG_x1_ADDI",              dut.u_rf.regfile[1], 32'd5);
        check_val("P2_REG_x2_EX_hazard_forward",  dut.u_rf.regfile[2], 32'd10);
        check_val("P2_REG_x3_ADDI",               dut.u_rf.regfile[3], 32'd7);
        check_val("P2_REG_x4_filler",             dut.u_rf.regfile[4], 32'd1);
        check_val("P2_REG_x5_MEM_hazard_forward", dut.u_rf.regfile[5], 32'd7);
        check_val("P2_DMEM_word0_SW_result",      dut.u_dmem.mem[0],   32'd5);
        check_val("P2_REG_x6_LW_result",          dut.u_rf.regfile[6], 32'd5);
        check_val("P2_REG_x7_load_use_stall",     dut.u_rf.regfile[7], 32'd105);
        check_val("P2_REG_x8_resumes_correctly",  dut.u_rf.regfile[8], 32'd17);

        //=========================================================
        // PHASE 3: Branch/jump PC resolution + pipeline flush
        //=========================================================
        $display("-----------------------------------------");
        $display(" PHASE 3: Branch/jump resolution + flush");
        $display("-----------------------------------------");

        clear_imem;
        dut.u_imem.mem[8'h00] = 32'h00C000EF; // JAL x1,+12
        dut.u_imem.mem[8'h01] = 32'h3E700493; // ADDI x9,x0,999   POISON
        dut.u_imem.mem[8'h02] = 32'h37800493; // ADDI x9,x0,888   POISON
        dut.u_imem.mem[8'h03] = 32'h02A00113; // ADDI x2,x0,42
        dut.u_imem.mem[8'h04] = 32'h00500193; // ADDI x3,x0,5
        dut.u_imem.mem[8'h05] = 32'h00500213; // ADDI x4,x0,5
        dut.u_imem.mem[8'h06] = 32'h00418663; // BEQ x3,x4,+12 (taken)
        dut.u_imem.mem[8'h07] = 32'h30900513; // ADDI x10,x0,777  POISON
        dut.u_imem.mem[8'h08] = 32'h29A00513; // ADDI x10,x0,666  POISON
        dut.u_imem.mem[8'h09] = 32'h03700293; // ADDI x5,x0,55
        dut.u_imem.mem[8'h0A] = 32'h00100313; // ADDI x6,x0,1
        dut.u_imem.mem[8'h0B] = 32'h00200393; // ADDI x7,x0,2
        dut.u_imem.mem[8'h0C] = 32'h00730663; // BEQ x6,x7,+12 (NOT taken)
        dut.u_imem.mem[8'h0D] = 32'h06300413; // ADDI x8,x0,99
        dut.u_imem.mem[8'h0E] = 32'h04800593; // ADDI x11,x0,0x48
        dut.u_imem.mem[8'h0F] = 32'h00058667; // JALR x12,0(x11)
        dut.u_imem.mem[8'h10] = 32'h22B00713; // ADDI x14,x0,555  POISON
        dut.u_imem.mem[8'h11] = 32'h1BC00713; // ADDI x14,x0,444  POISON
        dut.u_imem.mem[8'h12] = 32'h05800793; // ADDI x15,x0,88

        do_reset;
        repeat (40) @(posedge clk);
        @(negedge clk);

        check_val("P3_REG_x1_JAL_link",              dut.u_rf.regfile[1],  32'h00000004);
        check_val("P3_REG_x9_SENTINEL_JAL_flush_ok",  dut.u_rf.regfile[9],  32'd0);
        check_val("P3_REG_x2_after_JAL_target",       dut.u_rf.regfile[2],  32'd42);
        check_val("P3_REG_x10_SENTINEL_BEQ_flush_ok", dut.u_rf.regfile[10], 32'd0);
        check_val("P3_REG_x5_after_taken_BEQ",        dut.u_rf.regfile[5],  32'd55);
        check_val("P3_REG_x8_via_fallthrough",        dut.u_rf.regfile[8],  32'd99);
        check_val("P3_REG_x12_JALR_link",             dut.u_rf.regfile[12], 32'h00000040);
        check_val("P3_REG_x14_SENTINEL_JALR_flush_ok",dut.u_rf.regfile[14], 32'd0);
        check_val("P3_REG_x15_after_JALR_target",     dut.u_rf.regfile[15], 32'd88);

        //=========================================================
        // PHASE 4: BLT / BGE / BLTU / BGEU
        //=========================================================
        $display("-----------------------------------------");
        $display(" PHASE 4: BLT/BGE/BLTU/BGEU signed & unsigned");
        $display("-----------------------------------------");

        clear_imem;
        dut.u_imem.mem[8'h00] = 32'h00300093; // ADDI x1,x0,3
        dut.u_imem.mem[8'h01] = 32'h00500113; // ADDI x2,x0,5
        dut.u_imem.mem[8'h02] = 32'h0020C463; // BLT x1,x2,+8 (taken)
        dut.u_imem.mem[8'h03] = 32'h3E700493; // POISON x9
        dut.u_imem.mem[8'h04] = 32'h00B00193; // ADDI x3,x0,11
        dut.u_imem.mem[8'h05] = 32'h00115463; // BGE x2,x1,+8 (taken)
        dut.u_imem.mem[8'h06] = 32'h37800493; // POISON x9
        dut.u_imem.mem[8'h07] = 32'h01600213; // ADDI x4,x0,22
        dut.u_imem.mem[8'h08] = 32'hFFF00293; // ADDI x5,x0,-1
        dut.u_imem.mem[8'h09] = 32'h00100313; // ADDI x6,x0,1
        dut.u_imem.mem[8'h0A] = 32'h0062E463; // BLTU x5,x6,+8 (NOT taken)
        dut.u_imem.mem[8'h0B] = 32'h02100393; // ADDI x7,x0,33
        dut.u_imem.mem[8'h0C] = 32'h0062F463; // BGEU x5,x6,+8 (taken)
        dut.u_imem.mem[8'h0D] = 32'h30900493; // POISON x9
        dut.u_imem.mem[8'h0E] = 32'h02C00413; // ADDI x8,x0,44

        do_reset;
        repeat (30) @(posedge clk);
        @(negedge clk);

        check_val("P4_REG_x3_BLT_taken",   dut.u_rf.regfile[3], 32'd11);
        check_val("P4_REG_x4_BGE_taken",   dut.u_rf.regfile[4], 32'd22);
        check_val("P4_REG_x5_huge_unsigned_neg1_signed", dut.u_rf.regfile[5], 32'hFFFFFFFF);
        check_val("P4_REG_x7_BLTU_NOT_taken", dut.u_rf.regfile[7], 32'd33);
        check_val("P4_REG_x8_BGEU_taken",     dut.u_rf.regfile[8], 32'd44);
        check_val("P4_REG_x9_SENTINEL_all_flushes_ok", dut.u_rf.regfile[9], 32'd0);

        //=========================================================
        // PHASE 5: Remaining untested instructions -- R-type
        // AND/OR/XOR/SLL/SRL/SRA/SLT/SLTU, I-type ANDI/ORI/XORI/
        // SLLI/SRLI/SRAI/SLTI/SLTIU, and LUI/AUIPC. Phases 1-4
        // already proved ADD/SUB and ADDI work through the real
        // pipeline decode path (via the hazard/branch tests), but
        // every other opcode had only been exercised in each
        // block's OWN standalone testbench (Blocks 1 and 5) --
        // never through riscv_core's actual instruction decode.
        // This phase closes that integration-level gap.
        //=========================================================
        $display("-----------------------------------------");
        $display(" PHASE 5: Remaining R-type/I-type/LUI/AUIPC");
        $display("-----------------------------------------");

        clear_imem;
        dut.u_imem.mem[8'h00] = 32'h00C00093; // ADDI x1,x0,12
        dut.u_imem.mem[8'h01] = 32'h00A00113; // ADDI x2,x0,10
        dut.u_imem.mem[8'h02] = 32'h0020F1B3; // AND  x3,x1,x2
        dut.u_imem.mem[8'h03] = 32'h0020E233; // OR   x4,x1,x2
        dut.u_imem.mem[8'h04] = 32'h0020C2B3; // XOR  x5,x1,x2
        dut.u_imem.mem[8'h05] = 32'h00100313; // ADDI x6,x0,1
        dut.u_imem.mem[8'h06] = 32'h00400393; // ADDI x7,x0,4
        dut.u_imem.mem[8'h07] = 32'h00731433; // SLL  x8,x6,x7
        dut.u_imem.mem[8'h08] = 32'h800004B7; // LUI  x9,0x80000
        dut.u_imem.mem[8'h09] = 32'h00400513; // ADDI x10,x0,4
        dut.u_imem.mem[8'h0A] = 32'h00A4D5B3; // SRL  x11,x9,x10
        dut.u_imem.mem[8'h0B] = 32'hFF000613; // ADDI x12,x0,-16
        dut.u_imem.mem[8'h0C] = 32'h00400693; // ADDI x13,x0,4
        dut.u_imem.mem[8'h0D] = 32'h40D65733; // SRA  x14,x12,x13
        dut.u_imem.mem[8'h0E] = 32'hFFF00793; // ADDI x15,x0,-1
        dut.u_imem.mem[8'h0F] = 32'h00100813; // ADDI x16,x0,1
        dut.u_imem.mem[8'h10] = 32'h0107A8B3; // SLT  x17,x15,x16
        dut.u_imem.mem[8'h11] = 32'h0107B933; // SLTU x18,x15,x16
        dut.u_imem.mem[8'h12] = 32'h00A0F993; // ANDI x19,x1,10
        dut.u_imem.mem[8'h13] = 32'h00A0EA13; // ORI  x20,x1,10
        dut.u_imem.mem[8'h14] = 32'h00A0CA93; // XORI x21,x1,10
        dut.u_imem.mem[8'h15] = 32'h00431B13; // SLLI x22,x6,4
        dut.u_imem.mem[8'h16] = 32'h0044DB93; // SRLI x23,x9,4
        dut.u_imem.mem[8'h17] = 32'h40465C13; // SRAI x24,x12,4
        dut.u_imem.mem[8'h18] = 32'h0017AC93; // SLTI x25,x15,1
        dut.u_imem.mem[8'h19] = 32'h0017BD13; // SLTIU x26,x15,1
        dut.u_imem.mem[8'h1A] = 32'hABCDEDB7; // LUI  x27,0xABCDE
        dut.u_imem.mem[8'h1B] = 32'h00001E17; // AUIPC x28,0x1  (pc=0x6C)

        do_reset;
        repeat (35) @(posedge clk);
        @(negedge clk);

        check_val("P5_REG_x3_AND",   dut.u_rf.regfile[3],  32'd8);
        check_val("P5_REG_x4_OR",    dut.u_rf.regfile[4],  32'd14);
        check_val("P5_REG_x5_XOR",   dut.u_rf.regfile[5],  32'd6);
        check_val("P5_REG_x8_SLL",   dut.u_rf.regfile[8],  32'd16);
        check_val("P5_REG_x9_LUI",   dut.u_rf.regfile[9],  32'h80000000);
        check_val("P5_REG_x11_SRL",  dut.u_rf.regfile[11], 32'h08000000);
        check_val("P5_REG_x14_SRA",  dut.u_rf.regfile[14], 32'hFFFFFFFF);
        check_val("P5_REG_x17_SLT_signed",   dut.u_rf.regfile[17], 32'd1);
        check_val("P5_REG_x18_SLTU_unsigned",dut.u_rf.regfile[18], 32'd0);
        check_val("P5_REG_x19_ANDI",  dut.u_rf.regfile[19], 32'd8);
        check_val("P5_REG_x20_ORI",   dut.u_rf.regfile[20], 32'd14);
        check_val("P5_REG_x21_XORI",  dut.u_rf.regfile[21], 32'd6);
        check_val("P5_REG_x22_SLLI",  dut.u_rf.regfile[22], 32'd16);
        check_val("P5_REG_x23_SRLI",  dut.u_rf.regfile[23], 32'h08000000);
        check_val("P5_REG_x24_SRAI",  dut.u_rf.regfile[24], 32'hFFFFFFFF);
        check_val("P5_REG_x25_SLTI_signed",   dut.u_rf.regfile[25], 32'd1);
        check_val("P5_REG_x26_SLTIU_unsigned",dut.u_rf.regfile[26], 32'd0);
        check_val("P5_REG_x27_LUI",   dut.u_rf.regfile[27], 32'hABCDE000);
        check_val("P5_REG_x28_AUIPC", dut.u_rf.regfile[28], 32'h0000106C);

        //=========================================================
        // Final summary
        //=========================================================
        $display("=========================================");
        $display(" TOP-LEVEL RISCV_CORE TESTBENCH COMPLETE");
        $display(" PASS = %0d  FAIL = %0d", pass_count, fail_count);
        if (fail_count == 0)
            $display(" RESULT : ALL TESTS PASSED");
        else
            $display(" RESULT : %0d TEST(S) FAILED", fail_count);
        $display("=========================================");

        $finish;
    end

endmodule
