//=============================================================
// Module      : control_unit
// Project     : RV32I 5-Stage Pipelined Processor (Phase 1)
// Description : Main Control Unit. Decodes the 7-bit opcode
//               field only and generates the top-level datapath
//               control signals. Does NOT select the exact ALU
//               operation (see alu_control.v for that).
// Standard    : Synthesizable Verilog-2001
//=============================================================

module control_unit (
    input  wire [6:0] opcode,      // instruction[6:0]

    output reg        reg_write,   // enable register file write (WB)
    output reg        mem_read,    // enable data memory read (MEM)
    output reg        mem_write,   // enable data memory write (MEM)
    output reg        mem_to_reg,  // WB mux: 1 = mem data, 0 = ALU result
    output reg        alu_src,     // ALU op-B mux: 1 = immediate, 0 = rs2_data
    output reg        branch,      // conditional branch instruction
    output reg        jump,        // unconditional jump (JAL/JALR)
    output reg  [1:0] alu_op       // coarse ALU operation class -> ALU Control
);

    //---------------------------------------------------------
    // RV32I opcode map (instruction[6:0])
    //---------------------------------------------------------
    localparam OPCODE_R_TYPE = 7'b0110011; // add, sub, and, or, xor, sll, srl, sra, slt, sltu
    localparam OPCODE_OP_IMM = 7'b0010011; // addi, andi, ori, xori, slli, srli, srai, slti, sltiu
    localparam OPCODE_LOAD   = 7'b0000011; // lw, lh, lb, lhu, lbu
    localparam OPCODE_STORE  = 7'b0100011; // sw, sh, sb
    localparam OPCODE_BRANCH = 7'b1100011; // beq, bne, blt, bge, bltu, bgeu
    localparam OPCODE_LUI    = 7'b0110111;
    localparam OPCODE_AUIPC  = 7'b0010111;
    localparam OPCODE_JAL    = 7'b1101111;
    localparam OPCODE_JALR   = 7'b1100111;

    //---------------------------------------------------------
    // Combinational decode: one-hot opcode -> control signals
    //---------------------------------------------------------
    always @(*) begin
        // Safe defaults -- prevents inferred latches and gives a
        // well-defined (all-inactive) response to unknown opcodes
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        alu_src    = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_op     = 2'b00;

        case (opcode)

            OPCODE_R_TYPE: begin
                reg_write  = 1'b1;
                alu_src    = 1'b0; // operand B = rs2_data
                alu_op     = 2'b10; // look at funct3/funct7
            end

            OPCODE_OP_IMM: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1; // operand B = immediate
                alu_op     = 2'b10; // look at funct3 (funct7 for shifts)
            end

            OPCODE_LOAD: begin
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1; // WB data comes from memory
                alu_src    = 1'b1; // ALU computes rs1 + imm (address)
                alu_op     = 2'b00; // force ADD
            end

            OPCODE_STORE: begin
                mem_write  = 1'b1;
                alu_src    = 1'b1; // ALU computes rs1 + imm (address)
                alu_op     = 2'b00; // force ADD
            end

            OPCODE_BRANCH: begin
                branch     = 1'b1;
                alu_src    = 1'b0; // operand B = rs2_data (comparison)
                alu_op     = 2'b01; // force SUB (for zero_flag compare)
            end

            OPCODE_LUI: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1; // operand B = immediate
                alu_op     = 2'b11; // pass-through class (see Block 5)
            end

            OPCODE_AUIPC: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1; // operand B = immediate (operand A = PC, forced
                                    // upstream in riscv_core.v's EX stage)
                // BUG FIX: AUIPC is U-type and has NO real funct3 field --
                // instruction[14:12] here is immediate DATA, not an opcode
                // selector. alu_op=2'b10 previously routed AUIPC through
                // alu_control.v's funct3-based R/I-type decode, so any
                // immediate whose bits happened to land funct3=001/101/etc.
                // silently selected SLL/SRL/etc. instead of ADD. AUIPC must
                // always simply add operand_a+operand_b, exactly like
                // LOAD/STORE/JALR's address calculation -- same ALUOp class.
                alu_op     = 2'b00; // force ADD (was 2'b10 -- see note above)
            end

            OPCODE_JAL: begin
                reg_write  = 1'b1;
                jump       = 1'b1;
                mem_to_reg = 1'b0; // WB data = PC+4 (link), handled by a
                                   // separate upstream mux, not ALU/mem
            end

            OPCODE_JALR: begin
                reg_write  = 1'b1;
                jump       = 1'b1;
                alu_src    = 1'b1; // ALU computes rs1 + imm (target address)
                alu_op     = 2'b00; // force ADD
            end

            default: begin
                // Unknown/unsupported opcode: all signals remain at
                // the safe defaults set above (no writes, no side effects)
            end

        endcase
    end

endmodule
