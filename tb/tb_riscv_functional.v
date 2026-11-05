`timescale 1ns/1ps

// Complete RV32I functional-verification testbench.
// DUT: riscv_core
// Scope: instruction functionality, corner cases, memory,
//        control flow, forwarding, stalls and WB->ID bypass.
// Existing tb_riscv_core.v (50/50 integration test) is untouched.

module tb_riscv_functional;

reg clk, rst_n;
integer pass_count, fail_count, i;

riscv_core dut (.clk(clk), .rst_n(rst_n));

initial clk = 1'b0;
always #5 clk = ~clk;

// ---------------- Instruction encoders ----------------
function [31:0] R;
input [6:0] f7; input [4:0] rs2,rs1; input [2:0] f3; input [4:0] rd;
begin R={f7,rs2,rs1,f3,rd,7'b0110011}; end
endfunction

function [31:0] I;
input [11:0] imm; input [4:0] rs1; input [2:0] f3; input [4:0] rd;
begin I={imm,rs1,f3,rd,7'b0010011}; end
endfunction

function [31:0] LW;
input [11:0] imm; input [4:0] rs1,rd;
begin LW={imm,rs1,3'b010,rd,7'b0000011}; end
endfunction

function [31:0] SW;
input [11:0] imm; input [4:0] rs1,rs2;
begin SW={imm[11:5],rs2,rs1,3'b010,imm[4:0],7'b0100011}; end
endfunction

function [31:0] B;
input [12:0] imm; input [4:0] rs1,rs2; input [2:0] f3;
begin B={imm[12],imm[10:5],rs2,rs1,f3,imm[4:1],imm[11], 7'b1100011}; end
endfunction

function [31:0] J;
input [20:0] imm; input [4:0] rd;
begin J={imm[20],imm[10:1],imm[11],imm[19:12],rd,7'b1101111}; end
endfunction

function [31:0] JR;
input [11:0] imm; input [4:0] rs1,rd;
begin JR={imm,rs1,3'b000,rd,7'b1100111}; end
endfunction

function [31:0] U;
input [19:0] imm; input [4:0] rd; input [6:0] opc;
begin U={imm,rd,opc}; end
endfunction

// ---------------- Testbench utilities ----------------
task clear_imem;
begin
    for (i=0;i<32;i=i+1)
        dut.u_imem.mem[i]=32'h00000013; // NOP
end
endtask

task reset_dut;
begin
    rst_n=1'b0;
    @(negedge clk); @(negedge clk);
    rst_n=1'b1;
end
endtask

task check;
input [319:0] name;
input [31:0] actual,expected;
begin
    if (actual === expected) begin
        pass_count=pass_count+1;
        $display("[PASS] %0s : got=0x%08h",name,actual);
    end else begin
        fail_count=fail_count+1;
        $display("[FAIL] %0s : got=0x%08h expected=0x%08h",
                 name,actual,expected);
    end
end
endtask

initial begin
pass_count=0; fail_count=0; rst_n=1'b0;

$display("=================================================");
$display(" RV32I FUNCTIONAL VERIFICATION START");
$display("=================================================");

// ============================================================
// GROUP 1: ARITHMETIC
// ============================================================
$display("\n--- GROUP 1: ARITHMETIC ---");
clear_imem;
dut.u_imem.mem[0]=I(12'd10,0,3'b000,1);          // ADDI x1=10
dut.u_imem.mem[1]=I(12'd20,0,3'b000,2);          // ADDI x2=20
dut.u_imem.mem[2]=R(7'b0000000,2,1,3'b000,3);   // ADD x3=30
dut.u_imem.mem[3]=R(7'b0100000,1,2,3'b000,4);   // SUB x4=10
dut.u_imem.mem[4]=I(12'hfff,0,3'b000,5);        // x5=-1
dut.u_imem.mem[5]=R(7'b0000000,1,5,3'b000,6);   // x6=9
dut.u_imem.mem[6]=R(7'b0000000,5,5,3'b000,7);   // x7=-2
reset_dut; repeat(14) @(posedge clk); @(negedge clk);
check("FUNC_ADD_POSITIVE",dut.u_rf.regfile[3],30);
check("FUNC_SUB_POSITIVE",dut.u_rf.regfile[4],10);
check("FUNC_ADDI_NEGATIVE",dut.u_rf.regfile[5],32'hffffffff);
check("FUNC_ADD_POS_NEG",dut.u_rf.regfile[6],9);
check("FUNC_ADD_NEG_NEG",dut.u_rf.regfile[7],32'hfffffffe);

// ============================================================
// GROUP 2: LOGICAL
// ============================================================
$display("\n--- GROUP 2: LOGICAL ---");
clear_imem;
// 0xAAAAAAAA = 0xAAAAB000 + (-0x556)
dut.u_imem.mem[0]=U(20'haaaab,1,7'b0110111);
dut.u_imem.mem[1]=I(12'haaa,1,3'b000,1);
// 0x55555555 = 0x55555000 + 0x555
dut.u_imem.mem[2]=U(20'h55555,2,7'b0110111);
dut.u_imem.mem[3]=I(12'h555,2,3'b000,2);
dut.u_imem.mem[4]=R(0,2,1,3'b111,3);            // AND=0
dut.u_imem.mem[5]=R(0,2,1,3'b110,4);            // OR=FFFFFFFF
dut.u_imem.mem[6]=R(0,2,1,3'b100,5);            // XOR=FFFFFFFF
dut.u_imem.mem[7]=I(12'h7f0,0,3'b000,6);        // x6=0x7F0
dut.u_imem.mem[8]=I(12'h0f0,6,3'b111,7);        // ANDI=F0
dut.u_imem.mem[9]=I(12'h0ff,6,3'b110,8);        // ORI=FFF
dut.u_imem.mem[10]=I(12'h0ff,6,3'b100,9);       // XORI=80F
reset_dut; repeat(20) @(posedge clk); @(negedge clk);
check("FUNC_AND_PATTERN",dut.u_rf.regfile[3],32'h00000000);
check("FUNC_OR_PATTERN",dut.u_rf.regfile[4],32'hffffffff);
check("FUNC_XOR_PATTERN",dut.u_rf.regfile[5],32'hffffffff);
check("FUNC_ANDI",dut.u_rf.regfile[7],32'h000000f0);
check("FUNC_ORI",dut.u_rf.regfile[8],32'h000007ff);
check("FUNC_XORI",dut.u_rf.regfile[9],32'h0000070f);

// ============================================================
// GROUP 3: SHIFTS
// ============================================================
$display("\n--- GROUP 3: SHIFTS ---");
clear_imem;
dut.u_imem.mem[0]=I(1,0,3'b000,1);               // x1=1
dut.u_imem.mem[1]=I(31,0,3'b000,2);              // x2=31
dut.u_imem.mem[2]=R(0,2,1,3'b001,3);             // SLL 1<<31
dut.u_imem.mem[3]=R(0,0,1,3'b001,4);             // SLL shift0
dut.u_imem.mem[4]=U(20'h80000,6,7'b0110111);    // x6=80000000
dut.u_imem.mem[5]=I(1,0,3'b000,8);               // x8=1
dut.u_imem.mem[6]=R(0,8,6,3'b101,7);             // SRL
dut.u_imem.mem[7]=R(7'b0100000,8,6,3'b101,9);   // SRA
dut.u_imem.mem[8]=I(12'h004,1,3'b001,10);        // SLLI x10=16
dut.u_imem.mem[9]=I(12'h004,6,3'b101,11);        // SRLI
dut.u_imem.mem[10]=I(12'h404,6,3'b101,12);      // SRAI
dut.u_imem.mem[11]=I(15,1,3'b001,13);            // shift15
dut.u_imem.mem[12]=I(31,1,3'b001,14);            // shift31
reset_dut; repeat(22) @(posedge clk); @(negedge clk);
check("FUNC_SLL_SHIFT31",dut.u_rf.regfile[3],32'h80000000);
check("FUNC_SLL_SHIFT0",dut.u_rf.regfile[4],1);
check("FUNC_SRL_NEGATIVE",dut.u_rf.regfile[7],32'h40000000);
check("FUNC_SRA_NEGATIVE",dut.u_rf.regfile[9],32'hc0000000);
check("FUNC_SLLI_SHIFT4",dut.u_rf.regfile[10],16);
check("FUNC_SRLI_SHIFT4",dut.u_rf.regfile[11],32'h08000000);
check("FUNC_SRAI_SHIFT4",dut.u_rf.regfile[12],32'hf8000000);
check("FUNC_SLLI_SHIFT15",dut.u_rf.regfile[13],32'h00008000);
check("FUNC_SLLI_SHIFT31",dut.u_rf.regfile[14],32'h80000000);

// ============================================================
// GROUP 4: COMPARISONS
// ============================================================
$display("\n--- GROUP 4: COMPARISONS ---");
clear_imem;
dut.u_imem.mem[0]=I(12'hfff,0,3'b000,1);         // -1
dut.u_imem.mem[1]=I(1,0,3'b000,2);               // 1
dut.u_imem.mem[2]=R(0,2,1,3'b010,3);              // SLT=1
dut.u_imem.mem[3]=R(0,2,1,3'b011,4);              // SLTU=0
dut.u_imem.mem[4]=I(1,1,3'b010,5);                // SLTI=1
dut.u_imem.mem[5]=I(1,1,3'b011,6);                // SLTIU=0
dut.u_imem.mem[6]=I(5,0,3'b000,7);
dut.u_imem.mem[7]=R(0,7,7,3'b010,8);              // equal=0
reset_dut; repeat(16) @(posedge clk); @(negedge clk);
check("FUNC_SLT_SIGNED",dut.u_rf.regfile[3],1);
check("FUNC_SLTU_UNSIGNED",dut.u_rf.regfile[4],0);
check("FUNC_SLTI_SIGNED",dut.u_rf.regfile[5],1);
check("FUNC_SLTIU_UNSIGNED",dut.u_rf.regfile[6],0);
check("FUNC_SLT_EQUAL",dut.u_rf.regfile[8],0);

// ============================================================
// GROUP 5: IMMEDIATE BOUNDARIES + LUI/AUIPC
// ============================================================
$display("\n--- GROUP 5: IMMEDIATE CORNER CASES ---");
clear_imem;
dut.u_imem.mem[0]=I(12'h800,0,3'b000,1);          // -2048
dut.u_imem.mem[1]=I(12'hfff,0,3'b000,2);         // -1
dut.u_imem.mem[2]=I(0,0,3'b000,3);               // 0
dut.u_imem.mem[3]=I(1,0,3'b000,4);               // 1
dut.u_imem.mem[4]=I(12'h7ff,0,3'b000,5);         // 2047
dut.u_imem.mem[5]=U(20'habcde,6,7'b0110111);    // LUI
dut.u_imem.mem[7]=U(20'h00001,7,7'b0010111);    // AUIPC at PC=1C
reset_dut; repeat(14) @(posedge clk); @(negedge clk);
check("FUNC_IMM_NEG2048",dut.u_rf.regfile[1],32'hfffff800);
check("FUNC_IMM_NEG1",dut.u_rf.regfile[2],32'hffffffff);
check("FUNC_IMM_ZERO",dut.u_rf.regfile[3],0);
check("FUNC_IMM_POS1",dut.u_rf.regfile[4],1);
check("FUNC_IMM_POS2047",dut.u_rf.regfile[5],32'h000007ff);
check("FUNC_LUI",dut.u_rf.regfile[6],32'habcde000);
check("FUNC_AUIPC",dut.u_rf.regfile[7],32'h0000101c);

// ============================================================
// GROUP 6: x0
// ============================================================
$display("\n--- GROUP 6: x0 BEHAVIOR ---");
clear_imem;
dut.u_imem.mem[0]=I(123,0,3'b000,0);
dut.u_imem.mem[1]=R(0,0,0,3'b000,1);
dut.u_imem.mem[2]=I(12'hfff,0,3'b000,0);
dut.u_imem.mem[3]=I(0,0,3'b000,2);
reset_dut; repeat(12) @(posedge clk); @(negedge clk);
check("FUNC_X0_WRITE_BLOCKED",dut.u_rf.regfile[0],0);
check("FUNC_X0_SOURCE",dut.u_rf.regfile[1],0);
check("FUNC_X0_STILL_ZERO",dut.u_rf.regfile[2],0);

// ============================================================
// GROUP 7: MEMORY
// ============================================================
$display("\n--- GROUP 7: MEMORY ---");
clear_imem;
// AAAAAAAA
dut.u_imem.mem[0]=U(20'haaaab,1,7'b0110111);
dut.u_imem.mem[1]=I(12'haaa,1,3'b000,1);
// 55555555
dut.u_imem.mem[2]=U(20'h55555,2,7'b0110111);
dut.u_imem.mem[3]=I(12'h555,2,3'b000,2);
dut.u_imem.mem[4]=I(12'hfff,0,3'b000,3);        // FFFFFFFF
dut.u_imem.mem[5]=I(0,0,3'b000,4);
dut.u_imem.mem[6]=SW(0,0,1);
dut.u_imem.mem[7]=SW(4,0,2);
dut.u_imem.mem[8]=SW(8,0,3);
dut.u_imem.mem[9]=SW(12,0,4);
dut.u_imem.mem[10]=LW(0,0,5);
dut.u_imem.mem[11]=LW(4,0,6);
dut.u_imem.mem[12]=LW(8,0,7);
dut.u_imem.mem[13]=LW(12,0,8);
reset_dut; repeat(24) @(posedge clk); @(negedge clk);
check("FUNC_SW_ADDR0",dut.u_dmem.mem[0],32'haaaaaaaa);
check("FUNC_SW_ADDR4",dut.u_dmem.mem[1],32'h55555555);
check("FUNC_SW_ADDR8",dut.u_dmem.mem[2],32'hffffffff);
check("FUNC_SW_ADDR12",dut.u_dmem.mem[3],0);
check("FUNC_LW_ADDR0",dut.u_rf.regfile[5],32'haaaaaaaa);
check("FUNC_LW_ADDR4",dut.u_rf.regfile[6],32'h55555555);
check("FUNC_LW_ADDR8",dut.u_rf.regfile[7],32'hffffffff);
check("FUNC_LW_ADDR12",dut.u_rf.regfile[8],0);

// ============================================================
// GROUP 8: BRANCHES
// ============================================================
$display("\n--- GROUP 8: BRANCHES ---");
clear_imem;
dut.u_imem.mem[0]=I(5,0,3'b000,1);
dut.u_imem.mem[1]=I(5,0,3'b000,2);
dut.u_imem.mem[2]=I(7,0,3'b000,3);
dut.u_imem.mem[3]=I(9,0,3'b000,4);

// BEQ taken: index4 -> index6
dut.u_imem.mem[4]=B(13'd8,1,2,3'b000);
dut.u_imem.mem[5]=I(111,0,3'b000,10);
dut.u_imem.mem[6]=I(11,0,3'b000,5);

// BNE taken: index7 -> index9
dut.u_imem.mem[7]=B(13'd8,1,3,3'b001);
dut.u_imem.mem[8]=I(222,0,3'b000,11);
dut.u_imem.mem[9]=I(22,0,3'b000,6);

// BNE not taken; fall-through index11
dut.u_imem.mem[10]=B(13'd8,1,2,3'b001);
dut.u_imem.mem[11]=I(33,0,3'b000,7);

// BLT taken: index12 -> index14
dut.u_imem.mem[12]=B(13'd8,1,3,3'b100);
dut.u_imem.mem[13]=I(44,0,3'b000,12);
dut.u_imem.mem[14]=I(44,0,3'b000,13);

// BGE taken: index15 -> index17
dut.u_imem.mem[15]=B(13'd8,3,1,3'b101);
dut.u_imem.mem[16]=I(55,0,3'b000,14);
dut.u_imem.mem[17]=I(55,0,3'b000,15);

// BLTU taken: index18 -> index20
dut.u_imem.mem[18]=B(13'd8,3,4,3'b110);
dut.u_imem.mem[19]=I(66,0,3'b000,16);
dut.u_imem.mem[20]=I(66,0,3'b000,17);

// BGEU taken: index21 -> index23
dut.u_imem.mem[21]=B(13'd8,4,3,3'b111);
dut.u_imem.mem[22]=I(77,0,3'b000,18);
dut.u_imem.mem[23]=I(77,0,3'b000,19);

reset_dut; repeat(34) @(posedge clk); @(negedge clk);
check("FUNC_BEQ_TARGET",dut.u_rf.regfile[5],11);
check("FUNC_BEQ_FLUSH",dut.u_rf.regfile[10],0);
check("FUNC_BNE_TARGET",dut.u_rf.regfile[6],22);
check("FUNC_BNE_FLUSH",dut.u_rf.regfile[11],0);
check("FUNC_BNE_NOT_TAKEN",dut.u_rf.regfile[7],33);
check("FUNC_BLT_TARGET",dut.u_rf.regfile[13],44);
check("FUNC_BLT_FLUSH",dut.u_rf.regfile[12],0);
check("FUNC_BGE_TARGET",dut.u_rf.regfile[15],55);
check("FUNC_BGE_FLUSH",dut.u_rf.regfile[14],0);
check("FUNC_BLTU_TARGET",dut.u_rf.regfile[17],66);
check("FUNC_BLTU_FLUSH",dut.u_rf.regfile[16],0);
check("FUNC_BGEU_TARGET",dut.u_rf.regfile[19],77);
check("FUNC_BGEU_FLUSH",dut.u_rf.regfile[18],0);

// ============================================================
// GROUP 9: JAL / JALR
// ============================================================
$display("\n--- GROUP 9: JAL / JALR ---");
clear_imem;
// JAL x1,+12: PC0 -> PC12/index3
dut.u_imem.mem[0]=J(21'd12,1);
dut.u_imem.mem[1]=I(111,0,3'b000,9);
dut.u_imem.mem[2]=I(222,0,3'b000,9);
dut.u_imem.mem[3]=I(42,0,3'b000,2);

// x3=0x48; JALR at index5 -> target index18
dut.u_imem.mem[4]=I(12'h048,0,3'b000,3);
dut.u_imem.mem[5]=JR(0,3,4);
dut.u_imem.mem[6]=I(333,0,3'b000,10);
dut.u_imem.mem[7]=I(444,0,3'b000,10);
dut.u_imem.mem[18]=I(88,0,3'b000,5);

reset_dut; repeat(32) @(posedge clk); @(negedge clk);
check("FUNC_JAL_LINK",dut.u_rf.regfile[1],32'h00000004);
check("FUNC_JAL_TARGET",dut.u_rf.regfile[2],42);
check("FUNC_JAL_FLUSH",dut.u_rf.regfile[9],0);
check("FUNC_JALR_LINK",dut.u_rf.regfile[4],32'h00000018);
check("FUNC_JALR_TARGET",dut.u_rf.regfile[5],88);
check("FUNC_JALR_FLUSH",dut.u_rf.regfile[10],0);

// ============================================================
// GROUP 10: PIPELINE HAZARDS
// ============================================================
$display("\n--- GROUP 10: PIPELINE HAZARDS ---");
clear_imem;

// EX/MEM forwarding
dut.u_imem.mem[0]=I(5,0,3'b000,1);
dut.u_imem.mem[1]=R(0,1,1,3'b000,2);             // 10

// MEM/WB forwarding
dut.u_imem.mem[2]=I(7,0,3'b000,3);
dut.u_imem.mem[3]=I(1,0,3'b000,4);
dut.u_imem.mem[4]=R(0,0,3,3'b000,5);             // 7
dut.u_imem.mem[5]=R(0,4,5,3'b000,6);             // 8

// Store then load: memory[0]=5
dut.u_imem.mem[6]=SW(0,0,1);
dut.u_imem.mem[7]=LW(0,0,7);
dut.u_imem.mem[8]=I(100,7,3'b000,8);             // load-use -> 105

// WB->ID bypass
dut.u_imem.mem[9]=I(123,0,3'b000,9);
dut.u_imem.mem[10]=I(1,9,3'b000,10);             // 124
dut.u_imem.mem[11]=R(0,10,8,3'b000,11);          // 229

reset_dut; repeat(28) @(posedge clk); @(negedge clk);
check("FUNC_EX_MEM_FORWARD",dut.u_rf.regfile[2],10);
check("FUNC_MEM_WB_FORWARD",dut.u_rf.regfile[6],8);
check("FUNC_STORE_SOURCE",dut.u_dmem.mem[0],5);
check("FUNC_LOAD_USE_STALL",dut.u_rf.regfile[8],105);
check("FUNC_WB_ID_BYPASS",dut.u_rf.regfile[10],124);
check("FUNC_POST_HAZARD_RESULT",dut.u_rf.regfile[11],229);

// ============================================================
// SUMMARY
// ============================================================
$display("=================================================");
$display(" RV32I FUNCTIONAL VERIFICATION COMPLETE");
$display(" PASS = %0d  FAIL = %0d",pass_count,fail_count);
if (fail_count==0)
    $display(" RESULT : ALL FUNCTIONAL TESTS PASSED");
else
    $display(" RESULT : %0d FUNCTIONAL TEST(S) FAILED",fail_count);
$display("=================================================");
$finish;
end

endmodule
